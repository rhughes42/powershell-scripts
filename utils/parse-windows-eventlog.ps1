<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Parse Windows Event Logs for specific event IDs and export results.
.DESCRIPTION
    Searches the Windows Event Log for given event IDs, extracts details, and exports to CSV.
.PARAMETER LogName
    Name of the event log (e.g., 'System', 'Security').
.PARAMETER EventIds
    Array of event IDs to search for.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$LogName = 'System',
    [int[]]$EventIds = @(6005,6006),
    [string]$OutputCsv = 'EventLogResults.csv'
)

$results = Get-WinEvent -LogName $LogName -FilterHashtable @{Id=$EventIds} |
    Select-Object TimeCreated, Id, LevelDisplayName, Message | Sort-Object TimeCreated
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
