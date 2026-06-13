# Sync a config's "active"/"schedule" state with Windows Task Scheduler.
# Each managed task is named "ANFG_<config_id>" so it can be found/replaced/
# removed without touching other scheduled tasks. This replaces cron.sh.
#
# Uses the classic "Schedule.Service" COM API (the same one schtasks.exe
# uses) instead of the "ScheduledTasks" PowerShell module. The module talks
# to Task Scheduler via WMI/CIM (Root\Microsoft\Windows\TaskScheduler), which
# on many managed/school PCs is blocked by Group Policy for standard users -
# even for tasks in the user's own context - causing
# "Register-ScheduledTask : Zugriff verweigert" (HRESULT 0x80070005). The COM
# API uses a different RPC path that standard users can normally still use to
# manage their own tasks.
#
# NOT PORTED 1:1 - cron's "@reboot" semantics:
#   On Linux, daily/weekly/monthly presets run "@reboot" and rely on
#   Invoke-GenerateFromConfig's day-check + existing-file skip to fire once,
#   as early as possible, on the right day - i.e. the moment the machine
#   boots, even if no one logs in.
#   On Windows, a task that runs "at startup" without any user logged in
#   requires the task to run as SYSTEM/an elevated account, which a standard
#   user cannot register. To keep this usable without admin rights, this port
#   uses a logon trigger (runs as soon as the current user logs in) as the
#   closest equivalent. If you DO run as Administrator, you can change
#   $TASK_TRIGGER_TYPE below to 8 (TASK_TRIGGER_BOOT) for true "@reboot"
#   behaviour.
#
# NOT SUPPORTED - "Eigener Cron-Ausdruck" (custom preset):
#   Arbitrary 5-field cron expressions ("Min Std Tag Monat Wochentag") have
#   no equivalent in Windows Task Scheduler triggers and are NOT translated.
#   A custom-preset config is registered with the same logon trigger as
#   daily/weekly/monthly (i.e. it runs once per logon, every day), and the
#   raw cron string is kept in the config purely for reference/round-trip
#   with the Linux version.

# Schedule.Service constants (Microsoft.Win32.TaskScheduler enums)
$script:TASK_TRIGGER_LOGON = 9
$script:TASK_ACTION_EXEC = 0
$script:TASK_CREATE_OR_UPDATE = 6
$script:TASK_LOGON_INTERACTIVE_TOKEN = 3

function Get-AnfgTaskName {
    param([string]$Id)
    return "ANFG_$Id"
}

# Get-AnfgScheduledTask ROOTFOLDER TASKNAME
# Returns the ITaskFolder's task object, or $null if it doesn't exist.
function Get-AnfgScheduledTask {
    param($RootFolder, [string]$TaskName)
    try {
        return $RootFolder.GetTask("\$TaskName")
    } catch {
        return $null
    }
}

# Sync-ScheduledTaskForConfig ID
# Registers/updates the scheduled task if the config is active, removes it otherwise.
function Sync-ScheduledTaskForConfig {
    param([string]$Id)

    $taskName = Get-AnfgTaskName $Id

    $service = New-Object -ComObject "Schedule.Service"
    $service.Connect()
    $rootFolder = $service.GetFolder("\")

    $existingTask = Get-AnfgScheduledTask -RootFolder $rootFolder -TaskName $taskName

    $config = Get-Config $Id
    $preset = $config.schedule.preset
    $needsTask = $config.active -and $preset -and $preset -ne "null"

    if (-not $needsTask) {
        if ($existingTask) {
            Write-Host "$($global:C4)Geplante Aufgabe wird entfernt ...$($global:CR)"
            try {
                $rootFolder.DeleteTask($taskName, 0)
            } catch {
                Write-MdEcho "Hinweis: Geplante Aufgabe '$taskName' konnte nicht entfernt werden: $($_.Exception.Message)"
            }
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
    $userId = "$env:USERDOMAIN\$env:USERNAME"

    $taskDef = $service.NewTask(0)
    $taskDef.RegistrationInfo.Description = "ANFG config $Id"
    $taskDef.Settings.Enabled = $true
    $taskDef.Settings.StartWhenAvailable = $true
    $taskDef.Settings.DisallowStartIfOnBatteries = $false
    $taskDef.Settings.StopIfGoingOnBatteries = $false

    $trigger = $taskDef.Triggers.Create($script:TASK_TRIGGER_LOGON)
    $trigger.UserId = $userId
    $trigger.Enabled = $true

    $psCommand = "& '$scriptPath' --run $Id *>> '$logPath'"
    $action = $taskDef.Actions.Create($script:TASK_ACTION_EXEC)
    $action.Path = $pwsh
    $action.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"$psCommand`""

    try {
        $rootFolder.RegisterTaskDefinition(
            $taskName, $taskDef, $script:TASK_CREATE_OR_UPDATE,
            $userId, $null, $script:TASK_LOGON_INTERACTIVE_TOKEN, $null) | Out-Null
    } catch {
        Write-MdEcho "Fehler: Geplante Aufgabe '$taskName' konnte nicht erstellt werden: $($_.Exception.Message)"
        Write-MdEcho "Die Config wurde trotzdem gespeichert - {m.\ANFG.ps1 --run $Id} funktioniert weiterhin manuell/per Verknüpfung."
    }
}

# Remove-ScheduledTaskForConfig ID
function Remove-ScheduledTaskForConfig {
    param([string]$Id)

    $taskName = Get-AnfgTaskName $Id
    $service = New-Object -ComObject "Schedule.Service"
    $service.Connect()
    $rootFolder = $service.GetFolder("\")

    if (Get-AnfgScheduledTask -RootFolder $rootFolder -TaskName $taskName) {
        try {
            $rootFolder.DeleteTask($taskName, 0)
        } catch {
            # ignore - nothing to clean up if it can't be removed
        }
    }
}
