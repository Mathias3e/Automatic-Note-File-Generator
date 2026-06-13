# Automatic Note File Generator (ANFG) - PowerShell / Windows port

ANFG is a small terminal app for automatically creating Markdown note files
from templates on a schedule (daily, weekly, monthly, or on demand). You
define one or more **configs**, each pointing at a template, a destination
folder, a filename pattern, and a schedule - ANFG then takes care of creating
the file at the right time and filling in placeholders like the current date.

This branch (`powershell-port`) is a port of the original Bash/Linux version
to PowerShell for Windows. For the Linux/Bash version, see the `main` branch.

## Requirements

- Windows 10/11
- **PowerShell 7+ (`pwsh`) recommended** for correct rendering of the
  colored menu, logo, and Unicode arrows. Windows PowerShell 5.1 also works,
  but in older `powershell.exe`/conhost windows the colors/symbols may not
  render correctly - use [Windows Terminal](https://aka.ms/terminal) for the
  best experience.
- The built-in `ScheduledTasks` PowerShell module (included with Windows;
  used to register scheduled runs instead of cron).

## Installation

1. Download or clone this repository (and stay on the `powershell-port`
   branch).
2. Open PowerShell (or `pwsh`) in the project folder.
3. Run the installer:
   ```powershell
   .\ANFG_Install.ps1
   ```
   This creates the `templates/`, `configs/`, and `configs/.state/` folders.
   If your system blocks running local scripts, you may need to allow it for
   this session first:
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
4. Start the app:
   ```powershell
   .\ANFG.ps1
   ```

## Usage

Running `.\ANFG.ps1` opens the main menu:

- **Config hinzufügen** - create a new config: give it an ID and display
  name, pick a template (from the `templates/` folder or from disk), pick a
  destination folder, define the filename pattern, and choose a schedule.
- **Config bearbeiten** - edit an existing config's name, template,
  destination, filename pattern, schedule, or custom variables, and toggle it
  active/inactive.
- **Config löschen** - delete a config (and its scheduled task, if any).
- **Beenden** - quit.

### Placeholders

Templates and filename patterns support the following placeholders, which are
replaced when a note is generated:

| Placeholder    | Replaced with                           |
|-----------------|------------------------------------------|
| `{{date}}`      | Current date, ISO format (`YYYY-MM-DD`)  |
| `{{time}}`      | Current time (`HH:mm:ss`)                |
| `{{timeshot}}`  | Current time (`HH:mm`)                   |
| `{{datetime}}`  | `YYYY-MM-DD HH:mm`                       |
| `{{your_var}}`  | Any custom variable defined per config   |

### Schedules

A config can be scheduled as **Täglich** (daily), **Wöchentlich** (weekly,
pick a weekday), **Monatlich** (monthly, pick a day of month), or with a
**custom cron expression** (kept for compatibility with the Linux version,
see limitations below). No time of day is asked for - the note is generated
as early as possible on the configured day.

### Running a config manually / from a script

```powershell
.\ANFG.ps1 --run <config_id>
```

This is also what the scheduled task executes in the background.

## How scheduling works on Windows

Active configs are registered as Windows Scheduled Tasks named
`ANFG_<config_id>`, triggered **at logon** (i.e. whenever you log in).
When the task runs, `ANFG.ps1 --run <config_id>`:

1. For weekly/monthly schedules, checks whether today is the configured
   day - if not, it does nothing.
2. Checks whether the target file already exists - if so, it does nothing
   (so it won't recreate/overwrite a file you already have for today).
3. Otherwise, renders the template and writes the new file.

So a note appears shortly after you next log in on (or after) the scheduled
day. You can inspect or manually trigger the task in Task Scheduler under the
name `ANFG_<config_id>`.

Registration uses the classic `Schedule.Service` COM API (the same one
`schtasks.exe` uses), not the `ScheduledTasks` PowerShell module - the module
talks to Task Scheduler via WMI/CIM, which is blocked by Group Policy on many
managed/school PCs (`Register-ScheduledTask : Zugriff verweigert`,
`0x80070005`) even for tasks in your own user context. The COM API uses a
different RPC path that standard users can normally still use.

If the COM registration *also* fails (fully locked-down machine), ANFG prints
an error but still saves the config - you can still run it manually:
```powershell
.\ANFG.ps1 --run <config_id>
```
As a no-admin alternative to Task Scheduler entirely, you can place a
shortcut to that command in your Startup folder (open it via `Win+R` ->
`shell:startup`), which Windows runs at every logon without needing Task
Scheduler permissions.

## Known limitations of the Windows port

Compared to the Bash/Linux version, a few things could not be ported 1:1:

- **Mouse selection in menus** - the Bash version enables terminal mouse
  reporting (`\e[?1000h`) to let you click a menu option. This isn't reliably
  available on Windows, so only keyboard navigation (arrow keys / Enter /
  q / Esc) is supported.
- **"@reboot" scheduling without login** - on Linux, daily/weekly/monthly
  schedules run via a cron `@reboot` job that fires at every boot, even
  without anyone logging in. On Windows, running "at startup" without a
  logged-in user requires the scheduled task to run as SYSTEM/an elevated
  account, which a standard user cannot register. To keep this usable without
  admin rights, this port uses a logon trigger instead. If you run as
  Administrator, you can change `$script:TASK_TRIGGER_LOGON` (and the
  trigger creation call) in `src/scheduler/scheduler.ps1` to `8`
  (`TASK_TRIGGER_BOOT`) for true "@reboot"-like behaviour.
- **Custom cron expressions** - 5-field cron expressions (`min hour day
  month weekday`) have no direct equivalent in Windows Task Scheduler and are
  **not translated**. A config using the "Eigener Cron-Ausdruck" preset is
  registered with the same logon trigger as daily/weekly/monthly (i.e. it
  runs once per login, every day); the raw cron string is only kept for
  reference/round-trip compatibility with the Linux version.
- **Colors/logo/Unicode** - require a VT100-capable terminal (Windows
  Terminal or PowerShell 7+). In legacy `powershell.exe`/conhost windows,
  escape codes or Unicode symbols may not render correctly.

## Project structure

```
.
├─ ANFG.ps1                    # Main entry point (menu, or --run <id>)
├─ ANFG_Install.ps1            # Installer / first-time setup
├─ src/
│  ├─ tui/                     # Menus, widgets, colors, logo, config menus
│  ├─ config/                  # Config CRUD (JSON via ConvertFrom/To-Json)
│  ├─ scheduler/               # Windows Task Scheduler integration
│  └─ generator/                # Template rendering & placeholder substitution
├─ configs/                    # One JSON file per config
│  └─ .state/                  # Per-config logs from scheduled runs
└─ templates/                  # Markdown templates
```

## Config file format

Each config is a JSON file under `configs/`:

```json
{
  "config_id": "example",
  "name": "Example Note",
  "active": true,
  "template": "Template_BBZW.md",
  "destination": "C:\\Users\\you\\Notes",
  "filename": "{{date}}_Notiz.md",
  "schedule": { "preset": "daily", "cron": "@reboot", "day": "" },
  "variables": { "Lehrer": "Christian" }
}
```

These files are interchangeable between the Linux and Windows versions.
