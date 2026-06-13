#Requires -Version 5.1

$global:ANFG_HOME = Split-Path -Parent $MyInvocation.MyCommand.Path
$global:TEMPLATES_DIR = Join-Path $global:ANFG_HOME "templates"
$global:CONFIGS_DIR = Join-Path $global:ANFG_HOME "configs"

. "$global:ANFG_HOME\src\tui\colors.ps1"
. "$global:ANFG_HOME\src\tui\mdecho.ps1"
. "$global:ANFG_HOME\src\tui\logo.ps1"
. "$global:ANFG_HOME\src\tui\setup.ps1"
. "$global:ANFG_HOME\src\tui\widgets.ps1"
. "$global:ANFG_HOME\src\tui\file_picker.ps1"
. "$global:ANFG_HOME\src\config\config.ps1"
. "$global:ANFG_HOME\src\scheduler\scheduler.ps1"
. "$global:ANFG_HOME\src\generator\placeholders.ps1"
. "$global:ANFG_HOME\src\generator\generate.ps1"
. "$global:ANFG_HOME\src\tui\configs_menu.ps1"
. "$global:ANFG_HOME\src\tui\menu.ps1"

New-Item -ItemType Directory -Force -Path $global:TEMPLATES_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $global:CONFIGS_DIR | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $global:CONFIGS_DIR ".state") | Out-Null

if ($args.Count -ge 2 -and $args[0] -eq "--run") {
    exit (Invoke-GenerateFromConfig -Id $args[1])
}

Initialize-Terminal
Show-MainMenu
