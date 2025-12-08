<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics
#>
<#
.SYNOPSIS
    Find broken shortcut (.lnk) files under a given path.
.DESCRIPTION
    Scans for .lnk files whose targets do not exist, exports to CSV.
.PARAMETER RootPath
    Root directory to scan.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$RootPath = "$env:USERPROFILE\Desktop",
    [string]$OutputCsv = 'BrokenShortcuts.csv'
)

# Find all .lnk (shortcut) files recursively
$lnks = Get-ChildItem -Path $RootPath -Recurse -Filter '*.lnk' -ErrorAction SilentlyContinue

# Create Windows Script Host Shell COM object to read shortcut properties
$shell = New-Object -ComObject WScript.Shell
$results = @()

# Check each shortcut to see if its target still exists
foreach ($lnk in $lnks) {
    # Read the target path from the shortcut
    $target = $shell.CreateShortcut($lnk.FullName).TargetPath
    # Test if the target file or directory exists
    if (-not (Test-Path $target)) {
        $results += [PSCustomObject]@{ Shortcut = $lnk.FullName; Target = $target }
    }
}
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
$results | Format-Table -AutoSize Shortcut, Target
