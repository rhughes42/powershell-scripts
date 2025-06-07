<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Find large files in a directory tree.
.DESCRIPTION
    Recursively searches for files larger than a specified size and outputs results to console and CSV.
.PARAMETER Path
    Root directory to search.
.PARAMETER MinSizeMB
    Minimum file size in MB.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$Path = '.',
    [int]$MinSizeMB = 100,
    [string]$OutputCsv = 'LargeFiles.csv'
)

$files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -ge ($MinSizeMB * 1MB) }
$results = $files | Select-Object FullName, Length, LastWriteTime | Sort-Object Length -Descending
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
