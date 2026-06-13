# Template management (create/edit/rename/delete/import), edited with $EDITOR (nano).

function templatesMenu {
    while true; do
        local files=()
        while IFS= read -r f; do
            [[ -z "$f" ]] && continue
            files+=("$(basename "$f")")
        done < <(find "$TEMPLATES_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)

        local options=("${files[@]}" "+ Neues Template" "Importieren von Datenträger" "Zurück")
        local choice
        choice=$(menu_select "Templates" "${options[@]}") || return

        local count=${#files[@]}
        if (( choice < count )); then
            templateDetailMenu "${files[$choice]}"
        elif (( choice == count )); then
            newTemplate
        elif (( choice == count + 1 )); then
            importTemplate
        else
            return
        fi
    done
}

function newTemplate {
    local name
    name=$(text_input "Dateiname (z.B. Modul.md):")
    [[ -z "$name" ]] && return
    [[ "$name" != *.md ]] && name="$name.md"

    local path="$TEMPLATES_DIR/$name"
    if [[ ! -e "$path" ]]; then
        cat > "$path" <<'EOF'
---
Datum: "{{date}}"
---

## {{date}} -

EOF
    fi
    "$EDITOR" "$path" < /dev/tty > /dev/tty
}

function templateDetailMenu {
    local name="$1"
    local path="$TEMPLATES_DIR/$name"
    while true; do
        local choice
        choice=$(menu_select "Template: $name" "Bearbeiten" "Umbenennen" "Löschen" "Zurück") || return
        case "$choice" in
            0)
                "$EDITOR" "$path" < /dev/tty > /dev/tty
                ;;
            1)
                local newname
                newname=$(text_input "Neuer Dateiname:" "$name")
                [[ -z "$newname" ]] && continue
                [[ "$newname" != *.md ]] && newname="$newname.md"
                mv "$path" "$TEMPLATES_DIR/$newname"
                name="$newname"
                path="$TEMPLATES_DIR/$name"
                ;;
            2)
                if confirm "Template '$name' wirklich löschen?"; then
                    rm -f "$path"
                    return
                fi
                ;;
            3) return ;;
        esac
    done
}

function importTemplate {
    local src
    src=$(file_picker "$HOME" "file") || return

    local name
    name=$(text_input "Name für das importierte Template:" "$(basename "$src")")
    [[ -z "$name" ]] && name="$(basename "$src")"
    [[ "$name" != *.md ]] && name="$name.md"

    cp "$src" "$TEMPLATES_DIR/$name"
}
