#!/bin/bash

ANFG_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$ANFG_HOME/src/tui/logo.sh"
source "$ANFG_HOME/src/tui/colors.sh"
source "$ANFG_HOME/src/tui/mdecho.sh"
source "$ANFG_HOME/src/tui/setup.sh"

source "$ANFG_HOME/src/system/dependencyInstaller.sh"

setupTerminal
if ! sudo -n true 2>/dev/null; then
    mdecho "Um das Programm zu installiren braucht es {msudo}"
    sudo true
fi
update_apt
installDependency "jq"
installDependency "nano"
installCron

mkdir -p "$ANFG_HOME/templates" "$ANFG_HOME/configs" "$ANFG_HOME/configs/.state"
chmod +x "$ANFG_HOME/ANFG.sh"