# Main menu.

function mainMenu {
    while true; do
        local choice
        choice=$(menu_select "ANFG - Hauptmenü" "Configs verwalten" "Templates verwalten" "Config jetzt ausführen" "Beenden") || exit 0
        case "$choice" in
            0) configsMenu ;;
            1) templatesMenu ;;
            2) runConfigNow ;;
            3) exit 0 ;;
        esac
    done
}

function runConfigNow {
    local ids=() labels=()
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        ids+=("$id")
        labels+=("$(getConfigField "$id" '.name') ($id)")
    done < <(listConfigIds)

    if [[ ${#ids[@]} -eq 0 ]]; then
        menu_select "Keine Configs vorhanden." "OK" >/dev/null
        return
    fi

    local choice
    choice=$(menu_select "Config jetzt ausführen" "${labels[@]}") || return

    clear
    generateFromConfig "${ids[$choice]}"
    echo
    text_input "Weiter mit Enter..." >/dev/null
}
