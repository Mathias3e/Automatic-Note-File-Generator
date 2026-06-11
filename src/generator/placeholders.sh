# Placeholder substitution for template content and filenames.

# applyPlaceholders TEXT CONFIG_ID
# Prints TEXT with built-in placeholders and the config's custom
# {{variables}} substituted.
function applyPlaceholders {
    local text="$1" config_id="$2"
    local d t ts dt

    d=$(date +%d.%m.%Y)
    t=$(date +%H:%M:%S)
    ts=$(date +%H:%M)
    dt=$(date +"%H:%M %d.%m.%Y")

    text="${text//\{\{date\}\}/$d}"
    text="${text//\{\{time\}\}/$t}"
    text="${text//\{\{timeshot\}\}/$ts}"
    text="${text//\{\{datetime\}\}/$dt}"

    local key value
    while IFS=$'\t' read -r key value; do
        [[ -z "$key" ]] && continue
        text="${text//\{\{$key\}\}/$value}"
    done < <(jq -r '.variables | to_entries[] | "\(.key)\t\(.value)"' "$CONFIGS_DIR/$config_id.json")

    printf '%s' "$text"
}
