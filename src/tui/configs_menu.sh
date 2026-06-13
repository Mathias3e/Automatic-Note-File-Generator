# Config management: list/create/edit configs, schedule and variables.

function editConfigMenu {
    while true; do
        local ids=() labels=()
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            ids+=("$id")
            local name active marker
            name=$(getConfigField "$id" '.name')
            active=$(getConfigField "$id" '.active')
            marker="[ ]"
            [[ "$active" == "true" ]] && marker="[x]"
            labels+=("$marker $name ($id)")
        done < <(listConfigIds)

        local options=("${labels[@]}" "Zurück")
        local choice
        choice=$(menu_select "Config bearbeiten" "${options[@]}") || return

        local count=${#ids[@]}
        if (( choice < count )); then
            configDetailMenu "${ids[$choice]}"
        else
            return
        fi
    done
}

function deleteConfigMenu {
    while true; do
        local ids=() labels=()
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            ids+=("$id")
            labels+=("$(getConfigField "$id" '.name') ($id)")
        done < <(listConfigIds)

        local options=("${labels[@]}" "Zurück")
        local choice
        choice=$(menu_select "Config löschen" "${options[@]}") || return

        local count=${#ids[@]}
        if (( choice < count )); then
            local id="${ids[$choice]}" name="${labels[$choice]}"
            if confirm "Config '$name' wirklich löschen?"; then
                deleteConfig "$id"
            fi
        else
            return
        fi
    done
}

# pickTemplate -> echoes either a bare filename (from $TEMPLATES_DIR) or an
# absolute path (picked from disk). Returns 1 if cancelled.
function pickTemplate {
    local tchoice
    tchoice=$(menu_select "Template-Quelle" "Aus Templates-Ordner wählen" "Datei vom Datenträger wählen") || return 1

    if [[ "$tchoice" -eq 0 ]]; then
        local files=()
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            files+=("$(basename "$f")")
        done < <(find "$TEMPLATES_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)

        if [[ ${#files[@]} -eq 0 ]]; then
            menu_select "Keine Templates im Templates-Ordner gefunden." "OK" >/dev/null
            return 1
        fi

        local fchoice
        fchoice=$(menu_select "Template wählen" "${files[@]}") || return 1
        echo "${files[$fchoice]}"
    else
        file_picker "$HOME" "file" || return 1
    fi
}

function newConfigWizard {
    local id name template destination filename

    id=$(text_input "Config-ID (eindeutig, keine Leerzeichen):")
    [[ -z "$id" ]] && return
    if [[ -f "$CONFIGS_DIR/$id.json" ]]; then
        menu_select "Fehler: Config-ID '$id' existiert bereits." "OK" >/dev/null
        return
    fi

    name=$(text_input "Anzeigename:" "$id")

    template=$(pickTemplate) || return
    destination=$(file_picker "$HOME" "dir") || return
    filename=$(text_input "Dateinamen-Muster (z.B. {{date}}_Notiz.md):" "{{date}}_Notiz.md")

    createConfig "$id" "$name" "false" "$template" "$destination" "$filename" "custom" ""
    scheduleMenu "$id"

    if confirm "Config '$name' jetzt aktivieren?"; then
        setActive "$id" "true"
    fi
}

function configDetailMenu {
    local id="$1"
    while true; do
        [[ -f "$CONFIGS_DIR/$id.json" ]] || return

        local name active template destination filename preset day status schedule_label
        name=$(getConfigField "$id" '.name')
        active=$(getConfigField "$id" '.active')
        template=$(getConfigField "$id" '.template')
        destination=$(getConfigField "$id" '.destination')
        filename=$(getConfigField "$id" '.filename')
        preset=$(getConfigField "$id" '.schedule.preset')
        day=$(getConfigField "$id" '.schedule.day')

        local weekdays=(Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag)
        [[ "$day" == "null" ]] && day=""
        case "$preset" in
            daily) schedule_label="Täglich, sobald möglich" ;;
            weekly)
                if [[ "$day" =~ ^[0-6]$ ]]; then
                    schedule_label="Wöchentlich (${weekdays[$day]}), sobald möglich"
                else
                    schedule_label="Wöchentlich, sobald möglich"
                fi
                ;;
            monthly) schedule_label="Monatlich (Tag ${day:-?}), sobald möglich" ;;
            custom) schedule_label="Eigener Cron-Ausdruck ($(getConfigField "$id" '.schedule.cron'))" ;;
            *) schedule_label="(kein)" ;;
        esac

        status="Inaktiv"
        [[ "$active" == "true" ]] && status="Aktiv"

        local choice
        choice=$(menu_select "Config: $name [$status]" \
            "Name: $name" \
            "Template: $template" \
            "Zielordner: $destination" \
            "Dateiname: $filename" \
            "Zeitplan: $schedule_label" \
            "Variablen verwalten" \
            "Aktiv/Inaktiv umschalten ($status)" \
            "Zurück") || return

        case "$choice" in
            0)
                local newval
                newval=$(text_input "Neuer Name:" "$name")
                [[ -n "$newval" ]] && setConfigField "$id" ".name" "$newval"
                ;;
            1)
                local newtpl
                newtpl=$(pickTemplate) || continue
                setConfigField "$id" ".template" "$newtpl"
                ;;
            2)
                local newdest
                newdest=$(file_picker "$destination" "dir") || continue
                setConfigField "$id" ".destination" "$newdest"
                ;;
            3)
                local newfn
                newfn=$(text_input "Neues Dateinamen-Muster:" "$filename")
                [[ -n "$newfn" ]] && setConfigField "$id" ".filename" "$newfn"
                ;;
            4)
                scheduleMenu "$id"
                ;;
            5)
                variablesMenu "$id"
                ;;
            6)
                if [[ "$active" == "true" ]]; then
                    setActive "$id" "false"
                else
                    setActive "$id" "true"
                fi
                ;;
            7) return ;;
        esac
    done
}

function scheduleMenu {
    local id="$1"
    local choice
    choice=$(menu_select "Zeitplan wählen" "Täglich" "Wöchentlich" "Monatlich" "Eigener Cron-Ausdruck" "Abbrechen") || return

    local preset cron day=""
    case "$choice" in
        0)
            preset="daily"
            cron="@reboot"
            ;;
        1)
            day=$(menu_select "Wochentag" "Sonntag" "Montag" "Dienstag" "Mittwoch" "Donnerstag" "Freitag" "Samstag") || return
            preset="weekly"
            cron="@reboot"
            ;;
        2)
            day=$(text_input "Tag im Monat (1-31):" "1")
            preset="monthly"
            cron="@reboot"
            ;;
        3)
            cron=$(text_input "Cron-Ausdruck (Min Std Tag Monat Wochentag):" "* * * * *")
            preset="custom"
            ;;
        4) return ;;
    esac

    setConfigSchedule "$id" "$preset" "$cron" "$day"
    syncCronForConfig "$id"
}

function variablesMenu {
    local id="$1"
    while true; do
        local keys=() labels=()
        while IFS=$'\t' read -r k v; do
            [[ -z "$k" ]] && continue
            keys+=("$k")
            labels+=("$k = $v")
        done < <(jq -r '.variables | to_entries[] | "\(.key)\t\(.value)"' "$CONFIGS_DIR/$id.json")

        local options=("${labels[@]}" "+ Neue Variable" "Zurück")
        local choice
        choice=$(menu_select "Variablen ({{name}} -> Wert)" "${options[@]}") || return

        local count=${#keys[@]}
        if (( choice < count )); then
            local key="${keys[$choice]}"
            local action
            action=$(menu_select "Variable: $key" "Bearbeiten" "Löschen" "Zurück") || continue
            case "$action" in
                0)
                    local curval newval
                    curval=$(jq -r --arg k "$key" '.variables[$k]' "$CONFIGS_DIR/$id.json")
                    newval=$(text_input "Neuer Wert für $key:" "$curval")
                    addVariable "$id" "$key" "$newval"
                    ;;
                1)
                    confirm "Variable '$key' löschen?" && removeVariable "$id" "$key"
                    ;;
            esac
        elif (( choice == count )); then
            local newkey newval
            newkey=$(text_input "Variablenname (ohne {{ }}):")
            [[ -z "$newkey" ]] && continue
            newval=$(text_input "Wert für $newkey:")
            addVariable "$id" "$newkey" "$newval"
        else
            return
        fi
    done
}
