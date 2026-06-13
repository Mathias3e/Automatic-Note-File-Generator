#Requires -Version 5.1

$ANFG_HOME = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ANFG_HOME\src\tui\colors.ps1"
. "$ANFG_HOME\src\tui\mdecho.ps1"
. "$ANFG_HOME\src\tui\logo.ps1"
. "$ANFG_HOME\src\tui\setup.ps1"

Initialize-Terminal

# NOT PORTED: dependencyInstaller.sh installed jq/nano/cron. None of these are
# needed on Windows - config JSON is handled by ConvertFrom-Json/ConvertTo-Json,
# templates are no longer edited from within ANFG, and scheduling uses the
# built-in Windows Task Scheduler (module "ScheduledTasks").

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-MdEcho "Hinweis: {mPowerShell 7+} (pwsh) wird empfohlen - die Farben/Symbole des Menüs benötigen ein VT100-faehiges Terminal (z.B. Windows Terminal)."
}

if (-not (Get-Module -ListAvailable -Name ScheduledTasks)) {
    Write-MdEcho "Fehler: Das {mScheduledTasks}-Modul ist nicht verfügbar. Geplante Configs können nicht registriert werden."
    exit 1
}

Write-MdEcho "Erstelle Ordnerstruktur ..."
New-Item -ItemType Directory -Force -Path (Join-Path $ANFG_HOME "templates") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ANFG_HOME "configs") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ANFG_HOME "configs\.state") | Out-Null

Write-MdEcho "Installation abgeschlossen. Starte mit {m.\ANFG.ps1}"
