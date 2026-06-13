# CRUD for config JSON files in $CONFIGS_DIR.
#
# Schema (identical to the bash version):
# {
#   "config_id": "...",
#   "name": "...",
#   "active": true|false,
#   "template": "Template_BBZW.md" | "C:\\abs\\path\\to\\template.md",
#   "destination": "C:\\abs\\path\\to\\folder",
#   "filename": "{{date}}_M122.md",
#   "schedule": { "preset": "daily|weekly|monthly|custom", "cron": "@reboot" | "* * * * *", "day": "" },
#     - for "weekly", day is 0-6 (Sonntag=0 .. Samstag=6), matches (Get-Date).DayOfWeek.value__
#     - for "monthly", day is the day-of-month (1-31)
#   "variables": { "key": "value", ... }
# }

function Get-ConfigPath {
    param([string]$Id)
    return Join-Path $global:CONFIGS_DIR "$Id.json"
}

function Get-Config {
    param([string]$Id)
    return Get-Content -Raw -Path (Get-ConfigPath $Id) | ConvertFrom-Json
}

function Save-Config {
    param([string]$Id, $ConfigObject)
    $ConfigObject | ConvertTo-Json -Depth 10 | Set-Content -Path (Get-ConfigPath $Id)
}

# New-Config ID NAME ACTIVE TEMPLATE DESTINATION FILENAME PRESET CRON
function New-Config {
    param(
        [string]$Id,
        [string]$Name,
        [bool]$Active,
        [string]$Template,
        [string]$Destination,
        [string]$Filename,
        [string]$Preset,
        [string]$Cron
    )

    $config = [ordered]@{
        config_id   = $Id
        name        = $Name
        active      = $Active
        template    = $Template
        destination = $Destination
        filename    = $Filename
        schedule    = [ordered]@{ preset = $Preset; cron = $Cron; day = "" }
        variables   = [ordered]@{}
    }
    Save-Config -Id $Id -ConfigObject $config
}

function Get-ConfigIds {
    Get-ChildItem -Path $global:CONFIGS_DIR -Filter "*.json" -File -ErrorAction SilentlyContinue |
        ForEach-Object { $_.BaseName }
}

# Set-ConfigField ID FIELD VALUE   (e.g. Set-ConfigField myid name "New name")
function Set-ConfigField {
    param([string]$Id, [string]$Field, $Value)
    $config = Get-Config $Id
    $config.$Field = $Value
    Save-Config -Id $Id -ConfigObject $config
}

# Set-ConfigSchedule ID PRESET CRON DAY
function Set-ConfigSchedule {
    param([string]$Id, [string]$Preset, [string]$Cron, [string]$Day = "")
    $config = Get-Config $Id
    $config.schedule = [ordered]@{ preset = $Preset; cron = $Cron; day = $Day }
    Save-Config -Id $Id -ConfigObject $config
}

# Add-ConfigVariable ID KEY VALUE (also used to edit an existing variable)
function Add-ConfigVariable {
    param([string]$Id, [string]$Key, [string]$Value)
    $config = Get-Config $Id
    if ($config.variables.PSObject.Properties.Name -contains $Key) {
        $config.variables.$Key = $Value
    } else {
        $config.variables | Add-Member -NotePropertyName $Key -NotePropertyValue $Value
    }
    Save-Config -Id $Id -ConfigObject $config
}

# Remove-ConfigVariable ID KEY
function Remove-ConfigVariable {
    param([string]$Id, [string]$Key)
    $config = Get-Config $Id
    $config.variables.PSObject.Properties.Remove($Key) | Out-Null
    Save-Config -Id $Id -ConfigObject $config
}

# Set-ConfigActive ID true|false
function Set-ConfigActive {
    param([string]$Id, [bool]$Active)
    Set-ConfigField -Id $Id -Field "active" -Value $Active
    Sync-ScheduledTaskForConfig -Id $Id
}

function Remove-Config {
    param([string]$Id)
    Remove-ScheduledTaskForConfig -Id $Id
    Remove-Item -Path (Get-ConfigPath $Id) -Force -ErrorAction SilentlyContinue
}
