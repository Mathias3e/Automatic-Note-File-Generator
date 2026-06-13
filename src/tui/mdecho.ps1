function Write-MdEcho {
    param([string]$Text)

    $modified = "$($global:C6)$Text$($global:CR)"
    $modified = [regex]::Replace($modified, '\{m([^}]+)\}', "$($global:C1)`$1$($global:C6)")
    Write-Host $modified
}

# rgba(10, 182, 255), rgba(32, 32, 30), rgba(249, 249, 249)
