# Custom colored TUI widgets, built on [Console]::ReadKey.
#
# NOT PORTED from the bash version: mouse-click selection (the bash menu
# enabled terminal mouse reporting via "\e[?1000h" and could jump to an
# option on click). Windows consoles don't expose that escape sequence
# reliably, so only keyboard navigation (arrows/Enter/q/Esc) is supported here.

# Menu-Select TITLE OPTIONS[]
# Returns the chosen option's index (0-based), or -1 if cancelled (q / Esc).
function Menu-Select {
    param(
        [string]$Title,
        [string[]]$Options
    )

    $count = $Options.Count
    $sel = 0

    [Console]::CursorVisible = $false
    try {
        while ($true) {
            Clear-Host
            Write-Host "$($global:C2)$Title$($global:CR)`n"
            for ($i = 0; $i -lt $count; $i++) {
                if ($i -eq $sel) {
                    Write-Host "$($global:C1) > $($Options[$i])$($global:CR)"
                } else {
                    Write-Host "   $($Options[$i])"
                }
            }
            Write-Host "`n$($global:C4)↑/↓ navigieren, Enter wählen, q/Esc abbrechen$($global:CR)"

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'UpArrow' {
                    $sel--
                    if ($sel -lt 0) { $sel = $count - 1 }
                }
                'DownArrow' {
                    $sel++
                    if ($sel -ge $count) { $sel = 0 }
                }
                'Enter' { return $sel }
                'Escape' { return -1 }
                'Q' { return -1 }
            }
        }
    } finally {
        [Console]::CursorVisible = $true
    }
}

# Text-Input PROMPT [DEFAULT]
# Returns the entered value. Empty input returns DEFAULT (if given) or "".
#
# NOT PORTED: bash's "read -i" pre-fills the input line with DEFAULT so the
# user can edit it in place. PowerShell's Read-Host has no equivalent, so the
# default is only shown as a hint and used when the user presses Enter
# without typing anything.
function Text-Input {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    $hint = if ($Default) { " [$Default]" } else { "" }
    Write-Host -NoNewline "$($global:C2)$Prompt$hint$($global:CR) "
    $value = Read-Host
    if ([string]::IsNullOrEmpty($value)) { return $Default }
    return $value
}

# Confirm-Action PROMPT
# Returns $true for "Ja", $false for "Nein"/cancel.
function Confirm-Action {
    param([string]$Prompt)

    $choice = Menu-Select -Title $Prompt -Options @("Ja", "Nein")
    return ($choice -eq 0)
}
