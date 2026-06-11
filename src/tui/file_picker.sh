# Arrow-key (and mouse) navigable file/folder browser.
#
# file_picker [START_DIR] [MODE]
#   MODE: "file" (default) - navigate into directories, pick a file
#         "dir"             - navigate into directories, pick the current one
#
# Prints the chosen absolute path to stdout. Returns 1 if cancelled.
function file_picker {
    local current="${1:-$HOME}"
    local mode="${2:-file}"

    current="$(cd "$current" 2>/dev/null && pwd || echo "$HOME")"

    while true; do
        local labels=() entries=()

        if [[ "$mode" == "dir" ]]; then
            labels+=("[ Diesen Ordner wählen ]")
            entries+=("__SELECT_DIR__")
        fi

        if [[ "$current" != "/" ]]; then
            labels+=("../")
            entries+=("$(dirname "$current")")
        fi

        while IFS= read -r d; do
            [[ -z "$d" ]] && continue
            labels+=("$(basename "$d")/")
            entries+=("$d")
        done < <(find "$current" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

        if [[ "$mode" == "file" ]]; then
            while IFS= read -r f; do
                [[ -z "$f" ]] && continue
                labels+=("$(basename "$f")")
                entries+=("$f")
            done < <(find "$current" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | sort)
        fi

        local choice
        choice=$(menu_select "Ordner: $current" "${labels[@]}") || return 1

        local target="${entries[$choice]}"
        if [[ "$target" == "__SELECT_DIR__" ]]; then
            echo "$current"
            return 0
        elif [[ -d "$target" ]]; then
            current="$target"
        else
            echo "$target"
            return 0
        fi
    done
}
