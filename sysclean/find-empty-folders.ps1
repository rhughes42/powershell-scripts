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
    Find empty folders under a given path.
.DESCRIPTION
    Recursively scans for empty directories, exports to CSV.
.PARAMETER RootPath
    Root directory to scan.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$RootPath = 'C:\',
    [string]$OutputCsv = 'EmptyFolders.csv'
)

$folders = Get-ChildItem -Path $RootPath -Directory -Recurse -ErrorAction SilentlyContinue
$empty = $folders | Where-Object { @(Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 }
$empty | Select-Object FullName | Export-Csv -Path $OutputCsv -NoTypeInformation
$empty | Format-Table -AutoSize FullName
