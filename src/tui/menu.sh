# Main menu.

function mainMenu {
    while true; do
        local choice
        choice=$(menu_select "ANFG - Hauptmenü" "Config hinzufügen" "Config bearbeiten" "Config löschen" "Beenden") || exit 0
        case "$choice" in
            0) newConfigWizard ;;
            1) editConfigMenu ;;
            2) deleteConfigMenu ;;
            3) exit 0 ;;
        esac
    done
}
