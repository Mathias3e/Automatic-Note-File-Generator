# Render a config's template into its destination folder.

# Invoke-GenerateFromConfig CONFIG_ID
function Invoke-GenerateFromConfig {
    param([string]$Id)

    $configFile = Get-ConfigPath $Id
    if (-not (Test-Path -Path $configFile)) {
        Write-Error "Config '$Id' nicht gefunden."
        return 1
    }

    $config = Get-Config $Id

    $preset = $config.schedule.preset
    $day = $config.schedule.day
    switch ($preset) {
        "weekly" {
            if ($day -and $day -match '^\d+$' -and (Get-Date).DayOfWeek.value__ -ne [int]$day) {
                return 0
            }
        }
        "monthly" {
            if ($day -and $day -match '^\d+$' -and (Get-Date).Day -ne [int]$day) {
                return 0
            }
        }
    }

    $template = $config.template
    $destination = $config.destination
    $filename = $config.filename

    $templatePath = if ([System.IO.Path]::IsPathRooted($template)) {
        $template
    } else {
        Join-Path $global:TEMPLATES_DIR $template
    }

    if (-not (Test-Path -Path $templatePath -PathType Leaf)) {
        Write-Error "Template '$templatePath' nicht gefunden."
        return 1
    }

    $content = Get-Content -Raw -Path $templatePath
    $resolvedContent = Resolve-Placeholders -Text $content -ConfigId $Id
    $resolvedFilename = Resolve-Placeholders -Text $filename -ConfigId $Id

    New-Item -ItemType Directory -Force -Path $destination | Out-Null

    $outputPath = Join-Path $destination $resolvedFilename
    if (Test-Path -Path $outputPath) {
        Write-Host "Datei existiert bereits, überspringe: $outputPath"
        return 0
    }

    Set-Content -Path $outputPath -Value $resolvedContent -NoNewline
    Write-Host "Erstellt: $outputPath"
    return 0
}
