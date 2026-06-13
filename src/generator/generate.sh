# Render a config's template into its destination folder.

# generateFromConfig CONFIG_ID
function generateFromConfig {
    local id="$1"
    local config_file="$CONFIGS_DIR/$id.json"

    if [[ ! -f "$config_file" ]]; then
        echo "Config '$id' nicht gefunden." >&2
        return 1
    fi

    local preset day
    preset=$(getConfigField "$id" '.schedule.preset')
    day=$(getConfigField "$id" '.schedule.day')

    case "$preset" in
        weekly)
            [[ -n "$day" && "$day" != "null" && "$(date +%w)" != "$day" ]] && return 0
            ;;
        monthly)
            [[ -n "$day" && "$day" != "null" && "$((10#$(date +%d)))" != "$((10#$day))" ]] && return 0
            ;;
    esac

    local template destination filename
    template=$(getConfigField "$id" '.template')
    destination=$(getConfigField "$id" '.destination')
    filename=$(getConfigField "$id" '.filename')

    local template_path
    if [[ "$template" == /* ]]; then
        template_path="$template"
    else
        template_path="$TEMPLATES_DIR/$template"
    fi

    if [[ ! -f "$template_path" ]]; then
        echo "Template '$template_path' nicht gefunden." >&2
        return 1
    fi

    local content resolved_content resolved_filename
    content=$(cat "$template_path")
    resolved_content=$(applyPlaceholders "$content" "$id")
    resolved_filename=$(applyPlaceholders "$filename" "$id")

    mkdir -p "$destination"

    local output_path="$destination/$resolved_filename"
    if [[ -e "$output_path" ]]; then
        echo "Datei existiert bereits, überspringe: $output_path"
        return 0
    fi

    printf '%s\n' "$resolved_content" > "$output_path"
    echo "Erstellt: $output_path"
}
