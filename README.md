# Automatic Note File Generator (ANFG)

ANFG is a small terminal app for automatically creating Markdown note files
from templates on a schedule (daily, weekly, monthly, or on demand). You
define one or more **configs**, each pointing at a template, a destination
folder, a filename pattern, and a schedule - ANFG then takes care of creating
the file at the right time and filling in placeholders like the current date.

This is the Bash/Linux version. For a PowerShell port for Windows, see the
`powershell-port` branch.

## Requirements

- Bash
- [`jq`](https://jqlang.org/) - JSON parsing for configs
- `cron` - scheduling
- `nano` (or any `$EDITOR`) - only used if you edit templates manually
  outside of ANFG

The installer will try to install missing dependencies automatically via
`apt-get`, `brew`, or `dnf` (using `sudo` where required).

## Installation

1. Clone this repository.
2. Run the installer:
   ```bash
   ./ANFG_Install.sh
   ```
   This installs missing dependencies (`jq`, `nano`, `cron`), creates the
   `templates/`, `configs/`, and `configs/.state/` folders, and makes
   `ANFG.sh` executable.
3. Start the app:
   ```bash
   ./ANFG.sh
   ```

## Usage

Running `./ANFG.sh` opens the main menu:

- **Config hinzufügen** - create a new config: give it an ID and display
  name, pick a template (from the `templates/` folder or from disk), pick a
  destination folder, define the filename pattern, and choose a schedule.
- **Config bearbeiten** - edit an existing config's name, template,
  destination, filename pattern, schedule, or custom variables, and toggle it
  active/inactive.
- **Config löschen** - delete a config (and its crontab entry, if any).
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
**custom cron expression**. No time of day is asked for - the note is
generated as early as possible on the configured day.

### Running a config manually / from a script

```bash
./ANFG.sh --run <config_id>
```

This is also what the cron job executes in the background.

## How scheduling works

Active configs get an entry in your crontab, tagged with a trailing
`# ANFG:<config_id>` comment so it can be found/replaced/removed without
touching your other crontab entries.

For daily/weekly/monthly presets, the cron entry uses `@reboot` - i.e. it
runs once at every system boot, even if no one logs in. When it runs,
`ANFG.sh --run <config_id>`:

1. For weekly/monthly schedules, checks whether today is the configured
   day - if not, it does nothing.
2. Checks whether the target file already exists - if so, it does nothing
   (so it won't recreate/overwrite a file you already have for today).
3. Otherwise, renders the template and writes the new file.

So a note appears shortly after the machine next boots on (or after) the
scheduled day. A config using a custom cron expression is scheduled exactly
as entered (standard 5-field `min hour day month weekday` syntax).

You can inspect the managed crontab entries yourself with `crontab -l`, and
per-config run logs are written to `configs/.state/<config_id>.log`.

## Project structure

```
.
├─ ANFG.sh                      # Main entry point (menu, or --run <id>)
├─ ANFG_Install.sh              # Installer / dependency setup
├─ src/
│  ├─ tui/                      # Menus, widgets, colors, logo, config menus
│  ├─ config/                   # Config CRUD (jq-based JSON handling)
│  ├─ cron/                     # crontab integration
│  ├─ generator/                # Template rendering & placeholder substitution
│  └─ system/                   # Dependency installer
├─ configs/                     # One JSON file per config
│  └─ .state/                   # Per-config logs from scheduled runs
└─ templates/                   # Markdown templates
```

## Config file format

Each config is a JSON file under `configs/`:

```json
{
  "config_id": "example",
  "name": "Example Note",
  "active": true,
  "template": "Template_BBZW.md",
  "destination": "/home/you/Notes",
  "filename": "{{date}}_Notiz.md",
  "schedule": { "preset": "daily", "cron": "@reboot", "day": "" },
  "variables": { "Lehrer": "Christian" }
}
```

These files are interchangeable with the PowerShell/Windows version.
