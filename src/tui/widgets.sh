# Custom colored TUI widgets (no whiptail/dialog).
# All drawing happens on /dev/tty so the chosen result can still be
# returned to the caller via stdout (command substitution).

# menu_select TITLE OPT1 OPT2 ...
# Prints the chosen option's index (0-based) to stdout.
# Returns 1 if the user cancelled (q / Esc).
function menu_select {
    local title="$1"; shift
    local options=("$@")
    local count=${#options[@]}
    local sel=0
    local key rest

    exec 3>/dev/tty

    tput civis >&3
    printf '\e[?1000h' >&3   # enable basic mouse click reporting

    while true; do
        clear >&3
        echo -e "${C2}${title}${CR}\n" >&3
        local list_start=3 # header lines before the list (title + blank)
        for i in "${!options[@]}"; do
            if [[ $i -eq $sel ]]; then
                echo -e "${C1} > ${options[$i]}${CR}" >&3
            else
                echo -e "   ${options[$i]}" >&3
            fi
        done
        echo -e "\n${C4}↑/↓ navigieren, Enter wählen, q/Esc abbrechen${CR}" >&3

        IFS= read -rsn1 key < /dev/tty
        if [[ $key == $'\x1b' ]]; then
            read -rsn1 -t 0.01 key < /dev/tty
            if [[ $key == "[" ]]; then
                read -rsn1 -t 0.01 key < /dev/tty
                case "$key" in
                    A) ((sel--)); ((sel < 0)) && sel=$((count - 1)) ;;
                    B) ((sel++)); ((sel >= count)) && sel=0 ;;
                    M)
                        # Mouse click sequence: \e[M <button> <col> <row>
                        read -rsn3 -t 0.05 rest < /dev/tty
                        if [[ -n "$rest" ]]; then
                            local row=$(( $(printf '%d' "'${rest:2:1}") - 32 ))
                            local clicked=$(( row - list_start ))
                            if (( clicked >= 0 && clicked < count )); then
                                sel=$clicked
                                printf '\e[?1000l' >&3
                                tput cnorm >&3
                                exec 3>&-
                                echo "$sel"
                                return 0
                            fi
                        fi
                        ;;
                esac
            else
                # bare Esc
                printf '\e[?1000l' >&3
                tput cnorm >&3
                exec 3>&-
                return 1
            fi
        elif [[ -z "$key" ]]; then
            # Enter
            printf '\e[?1000l' >&3
            tput cnorm >&3
            exec 3>&-
            echo "$sel"
            return 0
        elif [[ $key == "q" ]]; then
            printf '\e[?1000l' >&3
            tput cnorm >&3
            exec 3>&-
            return 1
        fi
    done
}

# text_input PROMPT [DEFAULT]
# Prints the entered value to stdout. Returns 1 if cancelled (empty input
# is allowed and returned as empty string, not a cancel).
function text_input {
    local prompt="$1"
    local default="${2:-}"
    local value

    IFS= read -rep "$(echo -e "${C2}${prompt}${CR} ")" -i "$default" value < /dev/tty > /dev/tty
    echo "$value"
}

# confirm PROMPT
# Returns 0 for "Yes", 1 for "No"/cancel.
function confirm {
    local prompt="$1"
    local choice
    choice=$(menu_select "$prompt" "Ja" "Nein") || return 1
    [[ "$choice" -eq 0 ]]
}
