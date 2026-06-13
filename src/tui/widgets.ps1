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
# Shows the prompt in color, pre-fills DEFAULT (editable in place, like bash's
# "read -i"), and returns the final text. Enter without typing anything
# returns DEFAULT.
function Text-Input {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    Write-Host -NoNewline "$($global:C2)$Prompt$($global:CR) "
    $startLeft = [Console]::CursorLeft
    $startTop = [Console]::CursorTop

    $chars = [System.Collections.Generic.List[char]]::new()
    if ($Default) { [void]$chars.AddRange([char[]]$Default) }
    $pos = $chars.Count
    $clearToEol = "$([char]27)[K"

    [Console]::CursorVisible = $true
    try {
        while ($true) {
            [Console]::SetCursorPosition($startLeft, $startTop)
            Write-Host -NoNewline "$clearToEol$(-join $chars)"
            [Console]::SetCursorPosition($startLeft + $pos, $startTop)

            $key = [Console]::ReadKey($true)
            switch ($key.Key) {
                'Enter' {
                    Write-Host ""
                    $value = -join $chars
                    if ([string]::IsNullOrEmpty($value)) { return $Default }
                    return $value
                }
                'Backspace' {
                    if ($pos -gt 0) {
                        $chars.RemoveAt($pos - 1)
                        $pos--
                    }
                }
                'Delete' {
                    if ($pos -lt $chars.Count) { $chars.RemoveAt($pos) }
                }
                'LeftArrow' { if ($pos -gt 0) { $pos-- } }
                'RightArrow' { if ($pos -lt $chars.Count) { $pos++ } }
                'Home' { $pos = 0 }
                'End' { $pos = $chars.Count }
                default {
                    $ch = $key.KeyChar
                    if ($ch -and [int]$ch -ge 32) {
                        $chars.Insert($pos, $ch)
                        $pos++
                    }
                }
            }
        }
    } finally {
        [Console]::CursorVisible = $false
    }
}

# Confirm-Action PROMPT
# Returns $true for "Ja", $false for "Nein"/cancel.
function Confirm-Action {
    param([string]$Prompt)

    $choice = Menu-Select -Title $Prompt -Options @("Ja", "Nein")
    return ($choice -eq 0)
}
