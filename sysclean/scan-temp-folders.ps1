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
    Scan system and user temp folders for files and size.
.DESCRIPTION
    Reports file count and total size in temp directories, exports to CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'TempFoldersScan.csv'
)

$folders = @("$env:TEMP", "$env:WINDIR\Temp", "$env:LOCALAPPDATA\Temp")
$results = @()
foreach ($folder in $folders) {
    if (Test-Path $folder) {
        $files = Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue
        $size = ($files | Measure-Object -Property Length -Sum).Sum
        $results += [PSCustomObject]@{
            Folder      = $folder
            FileCount   = $files.Count
            TotalSizeMB = [math]::Round($size / 1MB, 2)
        }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
