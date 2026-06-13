# Main menu.

function Show-MainMenu {
    while ($true) {
        $choice = Menu-Select -Title "ANFG - Hauptmenü" -Options @("Config hinzufügen", "Config bearbeiten", "Config löschen", "Beenden")
        switch ($choice) {
            0 { New-ConfigWizard }
            1 { Edit-ConfigMenu }
            2 { Remove-ConfigMenu }
            default { exit 0 }
        }
    }
}
