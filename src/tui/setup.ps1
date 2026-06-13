function Initialize-Terminal {
    # Set terminal background color (VT100). On consoles without VT support
    # this sequence is simply ignored.
    Write-Host -NoNewline "$([char]27)]11;#1f1f1f`a$($global:CR)"
    Clear-Host
    Show-Logo
    Write-Host ""
}
