#!/bin/bash

ANFG_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ANFG_HOME
export TEMPLATES_DIR="$ANFG_HOME/templates"
export CONFIGS_DIR="$ANFG_HOME/configs"
export EDITOR="${EDITOR:-nano}"

source "$ANFG_HOME/src/tui/colors.sh"
source "$ANFG_HOME/src/tui/mdecho.sh"
source "$ANFG_HOME/src/tui/logo.sh"
source "$ANFG_HOME/src/tui/setup.sh"
source "$ANFG_HOME/src/tui/widgets.sh"
source "$ANFG_HOME/src/tui/file_picker.sh"
source "$ANFG_HOME/src/config/config.sh"
source "$ANFG_HOME/src/cron/cron.sh"
source "$ANFG_HOME/src/generator/placeholders.sh"
source "$ANFG_HOME/src/generator/generate.sh"
source "$ANFG_HOME/src/tui/templates_menu.sh"
source "$ANFG_HOME/src/tui/configs_menu.sh"
source "$ANFG_HOME/src/tui/menu.sh"

mkdir -p "$TEMPLATES_DIR" "$CONFIGS_DIR" "$CONFIGS_DIR/.state"

if [[ "$1" == "--run" && -n "$2" ]]; then
    generateFromConfig "$2"
    exit $?
fi

setupTerminal
mainMenu
