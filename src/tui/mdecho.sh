function mdecho {
    local modified="\x1b[38;2;255;255;255m$1\x1b[0m"
    echo -e "$modified" | sed -E 's/\{m([^}]+)\}/\x1b[38;2;10;182;255m\1\x1b[38;2;255;255;255m/g'
}

# rgba(10, 182, 255), rgba(32, 32, 30), rgba(249, 249, 249)