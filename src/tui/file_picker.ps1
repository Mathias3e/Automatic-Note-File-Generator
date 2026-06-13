# Arrow-key navigable file/folder browser.
#
# Select-FileOrFolder [-StartDir DIR] [-Mode file|dir]
#   Mode "file" (default) - navigate into directories, pick a file
#   Mode "dir"             - navigate into directories, pick the current one
#
# Returns the chosen absolute path, or $null if cancelled.
#
# NOT PORTED: mouse-click navigation (see widgets.ps1).
function Select-FileOrFolder {
    param(
        [string]$StartDir = $HOME,
        [string]$Mode = "file"
    )

    $resolved = Resolve-Path -Path $StartDir -ErrorAction SilentlyContinue
    $current = if ($resolved) { $resolved.ProviderPath } else { $HOME }

    while ($true) {
        $labels = @()
        $entries = @()

        if ($Mode -eq "dir") {
            $labels += "[ Diesen Ordner wählen ]"
            $entries += "__SELECT_DIR__"
        }

        $parent = Split-Path -Path $current -Parent
        if ($parent -and $parent -ne $current) {
            $labels += "..\"
            $entries += $parent
        } else {
            # At a drive root - offer the other available drives instead of "..\"
            Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | ForEach-Object {
                $driveRoot = "$($_.Name):\"
                if ($driveRoot -ne $current) {
                    $labels += $driveRoot
                    $entries += $driveRoot
                }
            }
        }

        Get-ChildItem -Path $current -Directory -ErrorAction SilentlyContinue |
            Sort-Object Name | ForEach-Object {
                $labels += "$($_.Name)\"
                $entries += $_.FullName
            }

        if ($Mode -eq "file") {
            Get-ChildItem -Path $current -File -ErrorAction SilentlyContinue |
                Sort-Object Name | ForEach-Object {
                    $labels += $_.Name
                    $entries += $_.FullName
                }
        }

        $choice = Menu-Select -Title "Ordner: $current" -Options $labels
        if ($choice -lt 0) { return $null }

        $target = $entries[$choice]
        if ($target -eq "__SELECT_DIR__") {
            return $current
        } elseif (Test-Path -Path $target -PathType Container) {
            $current = $target
        } else {
            return $target
        }
    }
}
