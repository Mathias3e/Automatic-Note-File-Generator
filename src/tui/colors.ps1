# ANSI color codes (24-bit). Requires a VT100-capable console
# (Windows Terminal or PowerShell 7+ on Windows 10+).

$ESC = [char]27
$global:C1 = "$ESC[38;2;0;229;255m"
$global:C2 = "$ESC[38;2;0;191;255m"
$global:C3 = "$ESC[38;2;0;152;255m"
$global:C4 = "$ESC[38;2;25;100;200m"
$global:C5 = "$ESC[38;2;80;60;220m"
$global:C6 = "$ESC[38;2;255;255;255m"
$global:CR = "$ESC[0m"
