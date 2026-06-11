# CRUD for config JSON files in $CONFIGS_DIR.
#
# Schema:
# {
#   "config_id": "...",
#   "name": "...",
#   "active": true|false,
#   "template": "Template_BBZW.md" | "/abs/path/to/template.md",
#   "destination": "/abs/path/to/folder",
#   "filename": "{{date}}_M122.md",
#   "schedule": { "preset": "hourly|daily|weekly|monthly|custom", "cron": "* * * * *" },
#   "variables": { "key": "value", ... }
# }

function _updateConfigJson {
    local id="$1"; shift
    local tmp="$CONFIGS_DIR/.$id.tmp.json"
    jq "$@" "$CONFIGS_DIR/$id.json" > "$tmp" && mv "$tmp" "$CONFIGS_DIR/$id.json"
}

# createConfig ID NAME ACTIVE TEMPLATE DESTINATION FILENAME PRESET CRON
function createConfig {
    local id="$1" name="$2" active="$3" template="$4" destination="$5" filename="$6" preset="$7" cron="$8"
    jq -n \
        --arg config_id "$id" \
        --arg name "$name" \
        --argjson active "$active" \
        --arg template "$template" \
        --arg destination "$destination" \
        --arg filename "$filename" \
        --arg preset "$preset" \
        --arg cron "$cron" \
        '{
            config_id: $config_id,
            name: $name,
            active: $active,
            template: $template,
            destination: $destination,
            filename: $filename,
            schedule: { preset: $preset, cron: $cron },
            variables: {}
        }' > "$CONFIGS_DIR/$id.json"
}

function listConfigIds {
    local f
    for f in "$CONFIGS_DIR"/*.json; do
        [[ -e "$f" ]] || continue
        basename "$f" .json
    done
}

function loadConfig {
    cat "$CONFIGS_DIR/$1.json"
}

# getConfigField ID JQ_FILTER
function getConfigField {
    jq -r "$2" "$CONFIGS_DIR/$1.json"
}

# setConfigField ID JQ_PATH VALUE   (e.g. setConfigField myid .name "New name")
function setConfigField {
    _updateConfigJson "$1" --arg v "$3" "$2 = \$v"
}

# setConfigSchedule ID PRESET CRON
function setConfigSchedule {
    _updateConfigJson "$1" --arg preset "$2" --arg cron "$3" '.schedule = {preset: $preset, cron: $cron}'
}

# addVariable ID KEY VALUE
function addVariable {
    _updateConfigJson "$1" --arg k "$2" --arg v "$3" '.variables[$k] = $v'
}

# removeVariable ID KEY
function removeVariable {
    _updateConfigJson "$1" --arg k "$2" 'del(.variables[$k])'
}

# setActive ID true|false
function setActive {
    _updateConfigJson "$1" --argjson a "$2" '.active = $a'
    syncCronForConfig "$1"
}

function deleteConfig {
    removeCronForConfig "$1"
    rm -f "$CONFIGS_DIR/$1.json"
}
