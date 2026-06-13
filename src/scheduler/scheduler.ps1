# Sync a config's "active"/"schedule" state with Windows Task Scheduler.
# Each managed task is named "ANFG_<config_id>" so it can be found/replaced/
# removed without touching other scheduled tasks. This replaces cron.sh.
#
# NOT PORTED 1:1 - cron's "@reboot" semantics:
#   On Linux, daily/weekly/monthly presets run "@reboot" and rely on
#   Invoke-GenerateFromConfig's day-check + existing-file skip to fire once,
#   as early as possible, on the right day - i.e. the moment the machine
#   boots, even if no one logs in.
#   On Windows, a task that runs "at startup" (New-ScheduledTaskTrigger
#   -AtStartup) without any user logged in requires the task to run as
#   SYSTEM/an elevated account, which Register-ScheduledTask can only set up
#   when the installer itself runs elevated. To keep the installer usable
#   without admin rights, this port uses "-AtLogOn" (runs as soon as the
#   current user logs in) as the closest equivalent. If you DO run the
#   installer/PowerShell as Administrator, you can switch the trigger below
#   to New-ScheduledTaskTrigger -AtStartup for true "@reboot" behaviour.
#
# NOT SUPPORTED - "Eigener Cron-Ausdruck" (custom preset):
#   Arbitrary 5-field cron expressions ("Min Std Tag Monat Wochentag") have
#   no equivalent in Windows Task Scheduler triggers and are NOT translated.
#   A custom-preset config is registered with the same "-AtLogOn" trigger as
#   daily/weekly/monthly (i.e. it runs once per logon, every day), and the
#   raw cron string is kept in the config purely for reference/round-trip
#   with the Linux version.

function Get-AnfgTaskName {
    param([string]$Id)
    return "ANFG_$Id"
}

# Sync-ScheduledTaskForConfig ID
# Registers/updates the scheduled task if the config is active, removes it otherwise.
function Sync-ScheduledTaskForConfig {
    param([string]$Id)

    $taskName = Get-AnfgTaskName $Id
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    $config = Get-Config $Id
    $preset = $config.schedule.preset
    $needsTask = $config.active -and $preset -and $preset -ne "null"

    if (-not $needsTask) {
        if ($existingTask) {
            Write-Host "$($global:C4)Geplante Aufgabe wird entfernt ...$($global:CR)"
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        }
        return
    }

    # The task always just runs "ANFG.ps1 --run <id>" - the day/weekday check
    # and the existing-file check happen inside Invoke-GenerateFromConfig at
    # run time, based on the live config. So once the task exists, changing
    # the schedule preset/day doesn't require re-registering it.
    if ($existingTask) { return }

    Write-Host "$($global:C4)Geplante Aufgabe wird aktualisiert ...$($global:CR)"

    if ($preset -eq "custom") {
        Write-MdEcho "Hinweis: {mEigener Cron-Ausdruck} wird unter Windows nicht uebersetzt - Task '$taskName' laeuft taeglich bei Anmeldung."
    }

    New-Item -ItemType Directory -Force -Path (Join-Path $global:CONFIGS_DIR ".state") | Out-Null

    $pwsh = (Get-Process -Id $PID).Path
    $scriptPath = Join-Path $global:ANFG_HOME "ANFG.ps1"
    $logPath = Join-Path $global:CONFIGS_DIR ".state\$Id.log"

    $action = New-ScheduledTaskAction -Execute $pwsh `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" --run $Id *>> `"$logPath`""

    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings `
        -Description "ANFG config $Id" -Force | Out-Null
}

# Remove-ScheduledTaskForConfig ID
function Remove-ScheduledTaskForConfig {
    param([string]$Id)
    Unregister-ScheduledTask -TaskName (Get-AnfgTaskName $Id) -Confirm:$false -ErrorAction SilentlyContinue
}
