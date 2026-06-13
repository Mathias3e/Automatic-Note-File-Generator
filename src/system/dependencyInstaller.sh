function installDependency {
    mdecho "Überprüfe Installation von {m$1}"
    if ! command -v "$1" &> /dev/null; then
        if command -v apt-get &> /dev/null; then
            mdecho "Installiere Abhängigkeit: {m$1}"
            sudo apt-get install -y "$1"
        elif command -v brew &> /dev/null; then
            mdecho "Installiere Abhängigkeit: {m$1}"
            brew install "$1"
        elif command -v dnf &> /dev/null; then
            mdecho "Installiere Abhängigkeit: {m$1}"
            sudo dnf install -y "$1"
        else
            mdecho "Bitte installiere {m$1} manuell"
            exit 1
        fi
    else
        local version
        version=$($1 --version 2>/dev/null | head -n 1)

        mdecho "{m$1} bereits Installiert - $version"
    fi
}

function update_apt {
    if command -v apt-get &> /dev/null; then
        mdecho "Update {mapt-get}"
        sudo apt-get update
    fi
}

function installCron {
    mdecho "Überprüfe Installation von {mcron}"
    if command -v crontab &> /dev/null; then
        mdecho "{mcron} bereits Installiert"
        return
    fi

    if command -v apt-get &> /dev/null; then
        mdecho "Installiere Abhängigkeit: {mcron}"
        sudo apt-get install -y cron
        sudo systemctl enable --now cron 2>/dev/null
    elif command -v dnf &> /dev/null; then
        mdecho "Installiere Abhängigkeit: {mcronie}"
        sudo dnf install -y cronie
        sudo systemctl enable --now crond 2>/dev/null
    elif command -v brew &> /dev/null; then
        mdecho "{mcron} sollte unter macOS bereits verfügbar sein"
    else
        mdecho "Bitte installiere {mcron} manuell"
        exit 1
    fi
}