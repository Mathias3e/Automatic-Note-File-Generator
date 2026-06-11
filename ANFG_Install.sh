# FILE="note-file-generator.sh"

# if [ -f "$FILE" ]; then
#     echo "Already installed!"
# else
#     sudo cp ./src/ /bin/note-file-generator
# fi

source src/tui/logo.sh
source src/tui/colors.sh
source src/tui/mdecho.sh
source src/tui/setup.sh

source src/system/dependencyInstaller.sh

setupTerminal
if ! sudo -n true 2>/dev/null; then
    mdecho "Um das Programm zu installiren braucht es {msudo}"
    sudo true 
fi
update_apt
installDependency "jq"
installDependency "nano"
installCron

mkdir -p templates configs configs/.state
chmod +x ANFG.sh