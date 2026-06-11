# Sync the user's crontab with config "active"/"schedule.cron" state.
# Each managed line is tagged with a trailing "# ANFG:<config_id>" comment
# so it can be found/replaced/removed without touching other crontab entries.

# removeCronForConfig ID
function removeCronForConfig {
    local id="$1"
    local existing
    existing=$(crontab -l 2>/dev/null | grep -v "# ANFG:$id\$")
    printf '%s\n' "$existing" | grep -v '^$' | crontab -
}

# syncCronForConfig ID
# Adds/updates the crontab line if the config is active, removes it otherwise.
function syncCronForConfig {
    local id="$1"
    local active cron
    active=$(getConfigField "$id" '.active')
    cron=$(getConfigField "$id" '.schedule.cron')

    local existing
    existing=$(crontab -l 2>/dev/null | grep -v "# ANFG:$id\$")

    if [[ "$active" == "true" && -n "$cron" && "$cron" != "null" ]]; then
        mkdir -p "$CONFIGS_DIR/.state"
        local line="$cron \"$ANFG_HOME/ANFG.sh\" --run $id >> \"$CONFIGS_DIR/.state/$id.log\" 2>&1 # ANFG:$id"
        printf '%s\n%s\n' "$existing" "$line" | grep -v '^$' | crontab -
    else
        printf '%s\n' "$existing" | grep -v '^$' | crontab -
    fi
}
