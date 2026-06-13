# Config management: list/create/edit configs, schedule and variables.

function configsMenu {
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

        local options=("${labels[@]}" "+ Neue Config" "Zurück")
        local choice
        choice=$(menu_select "Configs" "${options[@]}") || return

        local count=${#ids[@]}
        if (( choice < count )); then
            configDetailMenu "${ids[$choice]}"
        elif (( choice == count )); then
            newConfigWizard
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

        local name active template destination filename cron status
        name=$(getConfigField "$id" '.name')
        active=$(getConfigField "$id" '.active')
        template=$(getConfigField "$id" '.template')
        destination=$(getConfigField "$id" '.destination')
        filename=$(getConfigField "$id" '.filename')
        cron=$(getConfigField "$id" '.schedule.cron')

        status="Inaktiv"
        [[ "$active" == "true" ]] && status="Aktiv"

        local choice
        choice=$(menu_select "Config: $name [$status]" \
            "Name: $name" \
            "Template: $template" \
            "Zielordner: $destination" \
            "Dateiname: $filename" \
            "Zeitplan: ${cron:-(kein)}" \
            "Variablen verwalten" \
            "Aktiv/Inaktiv umschalten ($status)" \
            "Config löschen" \
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
            7)
                if confirm "Config '$name' wirklich löschen?"; then
                    deleteConfig "$id"
                    return
                fi
                ;;
            8) return ;;
        esac
    done
}

function scheduleMenu {
    local id="$1"
    local choice
    choice=$(menu_select "Zeitplan wählen" "Stündlich" "Täglich" "Wöchentlich" "Monatlich" "Eigener Cron-Ausdruck" "Abbrechen") || return

    local preset cron
    case "$choice" in
        0)
            preset="hourly"
            cron="0 * * * *"
            ;;
        1)
            local hh h m
            hh=$(text_input "Uhrzeit (HH:MM):" "07:00")
            h=${hh%%:*}; m=${hh##*:}
            preset="daily"
            cron="$((10#$m)) $((10#$h)) * * *"
            ;;
        2)
            local day hh h m
            day=$(menu_select "Wochentag" "Sonntag" "Montag" "Dienstag" "Mittwoch" "Donnerstag" "Freitag" "Samstag") || return
            hh=$(text_input "Uhrzeit (HH:MM):" "07:00")
            h=${hh%%:*}; m=${hh##*:}
            preset="weekly"
            cron="$((10#$m)) $((10#$h)) * * $day"
            ;;
        3)
            local dom hh h m
            dom=$(text_input "Tag im Monat (1-31):" "1")
            hh=$(text_input "Uhrzeit (HH:MM):" "07:00")
            h=${hh%%:*}; m=${hh##*:}
            preset="monthly"
            cron="$((10#$m)) $((10#$h)) $((10#$dom)) * *"
            ;;
        4)
            cron=$(text_input "Cron-Ausdruck (Min Std Tag Monat Wochentag):" "* * * * *")
            preset="custom"
            ;;
        5) return ;;
    esac

    setConfigSchedule "$id" "$preset" "$cron"
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
