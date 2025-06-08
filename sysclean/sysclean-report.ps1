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
    Generate a summary report of system cleaning opportunities.
.DESCRIPTION
    Aggregates results from other sysclean scripts and summarizes potential areas to clean.
.PARAMETER OutputReport
    Path to export the summary report.
#>
param(
    [string]$OutputReport = 'SysCleanSummary.txt'
)

$reports = @(
    'TempFoldersScan.csv',
    'LargeFolders.csv',
    'OldFiles.csv',
    'EmptyFolders.csv',
    'DuplicateFiles.csv',
    'RecycleBinScan.csv',
    'LargeFilesByType.csv',
    'BrokenShortcuts.csv',
    'UnusedAppData.csv'
)

$content = "System Cleaning Summary Report - $(Get-Date)" + "`n`n"
foreach ($file in $reports) {
    if (Test-Path $file) {
        $content += "--- $file ---`n"
        $content += (Get-Content $file | Select-Object -First 20) -join "`n"
        $content += "`n...`n"
    }
}
Set-Content -Path $OutputReport -Value $content
Write-Host "Summary report written to $OutputReport"
