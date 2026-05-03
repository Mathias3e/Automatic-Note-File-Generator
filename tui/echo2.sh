function echo2 {
    local modified="\e[2G\x1b[38;2;255;255;255m$1\x1b[0m"
    echo -e "$modified" | sed -E 's/\{m([^}]+)\}/\x1b[38;2;8;156;218m\1\x1b[38;2;255;255;255m/g'
}

# rgba(8, 156, 218), rgba(32, 32, 30), rgba(249, 249, 249)