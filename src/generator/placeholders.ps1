# Placeholder substitution for template content and filenames.

# Resolve-Placeholders TEXT CONFIG_ID
# Returns TEXT with built-in placeholders and the config's custom
# {{variables}} substituted.
function Resolve-Placeholders {
    param([string]$Text, [string]$ConfigId)

    $d = Get-Date -Format "yyyy-MM-dd"
    $t = Get-Date -Format "HH:mm:ss"
    $ts = Get-Date -Format "HH:mm"
    $dt = Get-Date -Format "yyyy-MM-dd HH:mm"

    $Text = $Text.Replace('{{date}}', $d)
    $Text = $Text.Replace('{{time}}', $t)
    $Text = $Text.Replace('{{timeshot}}', $ts)
    $Text = $Text.Replace('{{datetime}}', $dt)

    $config = Get-Config $ConfigId
    foreach ($prop in $config.variables.PSObject.Properties) {
        $Text = $Text.Replace("{{$($prop.Name)}}", [string]$prop.Value)
    }

    return $Text
}
