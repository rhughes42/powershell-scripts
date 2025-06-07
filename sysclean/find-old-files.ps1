<#
.SYNOPSIS
    Find files older than a specified age.
.DESCRIPTION
    Scans for files not modified in a given number of days, exports to CSV.
.PARAMETER RootPath
    Root directory to scan.
.PARAMETER DaysOld
    Minimum age in days.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$RootPath = 'C:\',
    [int]$DaysOld = 180,
    [string]$OutputCsv = 'OldFiles.csv'
)

$cutoff = (Get-Date).AddDays(-$DaysOld)
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff }
$files | Select-Object FullName, Length, LastWriteTime | Export-Csv -Path $OutputCsv -NoTypeInformation
$files | Format-Table -AutoSize FullName, Length, LastWriteTime
