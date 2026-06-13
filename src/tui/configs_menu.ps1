# Config management: list/create/edit configs, schedule and variables.

function Edit-ConfigMenu {
    while ($true) {
        $ids = @(Get-ConfigIds)
        $labels = @($ids | ForEach-Object {
            $c = Get-Config $_
            $marker = if ($c.active) { "[x]" } else { "[ ]" }
            "$marker $($c.name) ($_)"
        })

        $options = $labels + @("Zurück")
        $choice = Menu-Select -Title "Config bearbeiten" -Options $options
        if ($choice -lt 0) { return }

        if ($choice -lt $ids.Count) {
            Show-ConfigDetail -Id $ids[$choice]
        } else {
            return
        }
    }
}

function Remove-ConfigMenu {
    while ($true) {
        $ids = @(Get-ConfigIds)
        $labels = @($ids | ForEach-Object {
            $c = Get-Config $_
            "$($c.name) ($_)"
        })

        $options = $labels + @("Zurück")
        $choice = Menu-Select -Title "Config löschen" -Options $options
        if ($choice -lt 0) { return }

        if ($choice -lt $ids.Count) {
            $id = $ids[$choice]
            $name = $labels[$choice]
            if (Confirm-Action "Config '$name' wirklich löschen?") {
                Remove-Config -Id $id
            }
        } else {
            return
        }
    }
}

# Select-Template -> returns either a bare filename (from $TEMPLATES_DIR) or an
# absolute path (picked from disk). Returns $null if cancelled.
function Select-Template {
    $tchoice = Menu-Select -Title "Template-Quelle" -Options @("Aus Templates-Ordner wählen", "Datei vom Datenträger wählen")
    if ($tchoice -lt 0) { return $null }

    if ($tchoice -eq 0) {
        $files = @(Get-ChildItem -Path $global:TEMPLATES_DIR -Filter "*.md" -File -ErrorAction SilentlyContinue | Sort-Object Name)

        if ($files.Count -eq 0) {
            Menu-Select -Title "Keine Templates im Templates-Ordner gefunden." -Options @("OK") | Out-Null
            return $null
        }

        $labels = @($files | ForEach-Object { $_.Name })
        $fchoice = Menu-Select -Title "Template wählen" -Options $labels
        if ($fchoice -lt 0) { return $null }
        return $files[$fchoice].Name
    } else {
        return Select-FileOrFolder -StartDir $HOME -Mode "file"
    }
}

function New-ConfigWizard {
    $id = Text-Input "Config-ID (eindeutig, keine Leerzeichen):"
    if ([string]::IsNullOrWhiteSpace($id)) { return }
    if (Test-Path -Path (Get-ConfigPath $id)) {
        Menu-Select -Title "Fehler: Config-ID '$id' existiert bereits." -Options @("OK") | Out-Null
        return
    }

    $name = Text-Input "Anzeigename:" $id

    $template = Select-Template
    if ($null -eq $template) { return }

    $destination = Select-FileOrFolder -StartDir $HOME -Mode "dir"
    if ($null -eq $destination) { return }

    $filename = Text-Input "Dateinamen-Muster (z.B. {{date}}_Notiz.md):" "{{date}}_Notiz.md"

    New-Config -Id $id -Name $name -Active $false -Template $template -Destination $destination -Filename $filename -Preset "custom" -Cron ""
    Set-ScheduleMenu -Id $id

    if (Confirm-Action "Config '$name' jetzt aktivieren?") {
        Set-ConfigActive -Id $id -Active $true
    }
}

function Show-ConfigDetail {
    param([string]$Id)

    while ($true) {
        if (-not (Test-Path -Path (Get-ConfigPath $Id))) { return }

        $config = Get-Config $Id
        $status = if ($config.active) { "Aktiv" } else { "Inaktiv" }
        $scheduleLabel = Format-ScheduleLabel -Config $config -Id $Id

        $choice = Menu-Select -Title "Config: $($config.name) [$status]" -Options @(
            "Name: $($config.name)",
            "Template: $($config.template)",
            "Zielordner: $($config.destination)",
            "Dateiname: $($config.filename)",
            "Zeitplan: $scheduleLabel",
            "Variablen verwalten",
            "Aktiv/Inaktiv umschalten ($status)",
            "Zurück"
        )

        switch ($choice) {
            0 {
                $newval = Text-Input "Neuer Name:" $config.name
                if ($newval) { Set-ConfigField -Id $Id -Field "name" -Value $newval }
            }
            1 {
                $newtpl = Select-Template
                if ($null -ne $newtpl) { Set-ConfigField -Id $Id -Field "template" -Value $newtpl }
            }
            2 {
                $newdest = Select-FileOrFolder -StartDir $config.destination -Mode "dir"
                if ($null -ne $newdest) { Set-ConfigField -Id $Id -Field "destination" -Value $newdest }
            }
            3 {
                $newfn = Text-Input "Neues Dateinamen-Muster:" $config.filename
                if ($newfn) { Set-ConfigField -Id $Id -Field "filename" -Value $newfn }
            }
            4 { Set-ScheduleMenu -Id $Id }
            5 { Show-VariablesMenu -Id $Id }
            6 { Set-ConfigActive -Id $Id -Active (-not $config.active) }
            7 { return }
            default { return }
        }
    }
}

function Format-ScheduleLabel {
    param($Config, [string]$Id)

    $weekdays = @("Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag")
    $preset = $Config.schedule.preset
    $day = $Config.schedule.day

    switch ($preset) {
        "daily" { return "Täglich, sobald möglich" }
        "weekly" {
            if ($day -match '^[0-6]$') {
                return "Wöchentlich ($($weekdays[[int]$day])), sobald möglich"
            }
            return "Wöchentlich, sobald möglich"
        }
        "monthly" {
            $dayLabel = if ($day) { $day } else { "?" }
            return "Monatlich (Tag $dayLabel), sobald möglich"
        }
        "custom" { return "Eigener Cron-Ausdruck ($($Config.schedule.cron))" }
        default { return "(kein)" }
    }
}

# Set-ScheduleMenu ID
#
# NOT PORTED: time-of-day input. Like the bash version, no time is asked -
# tasks run "as early as possible" (see scheduler.ps1 for what that means on
# Windows).
function Set-ScheduleMenu {
    param([string]$Id)

    $choice = Menu-Select -Title "Zeitplan wählen" -Options @("Täglich", "Wöchentlich", "Monatlich", "Eigener Cron-Ausdruck", "Abbrechen")
    if ($choice -lt 0) { return }

    $preset = $null
    $cron = $null
    $day = ""

    switch ($choice) {
        0 {
            $preset = "daily"
            $cron = "@reboot"
        }
        1 {
            $weekday = Menu-Select -Title "Wochentag" -Options @("Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag")
            if ($weekday -lt 0) { return }
            $day = [string]$weekday
            $preset = "weekly"
            $cron = "@reboot"
        }
        2 {
            $day = Text-Input "Tag im Monat (1-31):" "1"
            $preset = "monthly"
            $cron = "@reboot"
        }
        3 {
            $cron = Text-Input "Cron-Ausdruck (Min Std Tag Monat Wochentag):" "* * * * *"
            $preset = "custom"
        }
        default { return }
    }

    Set-ConfigSchedule -Id $Id -Preset $preset -Cron $cron -Day $day
    Sync-ScheduledTaskForConfig -Id $Id
}

function Show-VariablesMenu {
    param([string]$Id)

    while ($true) {
        $config = Get-Config $Id
        $keys = @($config.variables.PSObject.Properties.Name)
        $labels = @($keys | ForEach-Object { "$_ = $($config.variables.$_)" })

        $options = $labels + @("+ Neue Variable", "Zurück")
        $choice = Menu-Select -Title "Variablen ({{name}} -> Wert)" -Options $options
        if ($choice -lt 0) { return }

        $count = $keys.Count
        if ($choice -lt $count) {
            $key = $keys[$choice]
            $action = Menu-Select -Title "Variable: $key" -Options @("Bearbeiten", "Löschen", "Zurück")
            switch ($action) {
                0 {
                    $curval = $config.variables.$key
                    $newval = Text-Input "Neuer Wert für $key:" $curval
                    Add-ConfigVariable -Id $Id -Key $key -Value $newval
                }
                1 {
                    if (Confirm-Action "Variable '$key' löschen?") {
                        Remove-ConfigVariable -Id $Id -Key $key
                    }
                }
            }
        } elseif ($choice -eq $count) {
            $newkey = Text-Input "Variablenname (ohne {{ }}):"
            if ([string]::IsNullOrWhiteSpace($newkey)) { continue }
            $newval = Text-Input "Wert für $newkey:"
            Add-ConfigVariable -Id $Id -Key $newkey -Value $newval
        } else {
            return
        }
    }
}
