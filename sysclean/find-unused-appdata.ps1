<#
.SYNOPSIS
    Find unused folders in AppData (not accessed in N days).
.DESCRIPTION
    Scans AppData for folders not accessed in a given number of days, exports to CSV.
.PARAMETER DaysOld
    Minimum age in days since last access.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [int]$DaysOld = 180,
    [string]$OutputCsv = 'UnusedAppData.csv'
)

$cutoff = (Get-Date).AddDays(-$DaysOld)
$folders = Get-ChildItem -Path $env:APPDATA -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.LastAccessTime -lt $cutoff }
$folders | Select-Object FullName, LastAccessTime | Export-Csv -Path $OutputCsv -NoTypeInformation
$folders | Format-Table -AutoSize FullName, LastAccessTime
