### Important paths
#### Linux
- `/etc/Automatic-Note-File-Generator` | Benutzereinstellungen
- `/bin/Automatic-Note-File-Generator` | Programcode

#### Windows
- `C:\Users\<user name>\AppData\Roaming` | benutzereinstellungen
- `C:\Users\<user name>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs` | Programverlinkung
- `C:\Users\<user name>\AppData\Local\Programs\` | Programcode

### echo2
code:
echo2 "Hallo {mUser} wie geht es dir?"

output (User wird blau sien, {m} als markirung gedacht):
Hallo User wie geht es dir?

#### dependency


---

## Project:
- 1 Script (instalation und programm)
- kein .md im terminal
- setings:
    - haupt folder
    - User name
    - 
- .link in windows menu

## PowerShell-Port (Windows)
Dieser Branch portiert alle `.sh`-Dateien nach `.ps1` (gleiche Ordnerstruktur,
`src/cron` → `src/scheduler`). Einstiegspunkte: `ANFG_Install.ps1` (Setup) und
`ANFG.ps1` (Programm, bzw. `ANFG.ps1 --run <config_id>` für geplante Läufe).
`configs/*.json` und `templates/*.md` sind unverändert/identisch nutzbar.

Nicht bzw. nicht 1:1 portierbare Funktionalität:
- **Mausklick-Auswahl im Menü** - die bash-Version aktiviert Terminal-Mausreporting
  (`\e[?1000h`); unter Windows nicht zuverlässig verfügbar, daher nur Tastatur
  (Pfeiltasten/Enter/q/Esc).
- **Vorausgefüllte Eingabefelder** - `read -i` (bash) zeigt den Default editierbar
  im Eingabefeld an. `Read-Host` kann das nicht; der Default wird nur als Hinweis
  angezeigt und bei leerer Eingabe übernommen.
- **„@reboot“-Zeitplan (täglich/wöchentlich/monatlich)** - unter Linux läuft der
  Cron-Job bei jedem Boot und das Skript selbst prüft Tag + ob die Datei schon
  existiert. Unter Windows würde "beim Systemstart, ohne Login" Admin-Rechte für
  den Scheduled Task benötigen. Der Port registriert den Task daher mit
  `-AtLogOn` (läuft bei Anmeldung des Benutzers); für echtes "@reboot"-Verhalten
  müsste der Task mit Adminrechten auf `-AtStartup` umgestellt werden
  (siehe `src/scheduler/scheduler.ps1`).
- **„Eigener Cron-Ausdruck“ (custom preset)** - 5-Felder-Cron-Ausdrücke haben kein
  Äquivalent in der Windows-Aufgabenplanung und werden NICHT übersetzt. Ein
  custom-Config wird wie daily/weekly/monthly mit `-AtLogOn` registriert; der
  Cron-String wird nur zur Anzeige/Kompatibilität mit der Linux-Version gespeichert.
- **Farben/Logo** - benötigen ein VT100-fähiges Terminal (Windows Terminal oder
  PowerShell 7+); in alten `powershell.exe`/conhost-Fenstern können Escape-Codes
  oder Unicode-Symbole falsch dargestellt werden.

## Ordner Strucktur
```
Haupt Ordner/
├─ src/
|  ├─ tui/
|  |  └─ ...
|  ├─ installation/
|  |  └─ ...
|  ├─ background/
|  |  └─ ...
|  ├─ config/
|  |  └─ ...
|  └─ main/
|     └─ ...
├─ configs/
|  ├─ config1.json
|  ├─ config2.json
|  └─ ...
└─ templates/
   ├─ template1.md
   ├─ template2.md
   └─ ...
```
