<#
.SYNOPSIS
    Find large files of specific types under a given path.
.DESCRIPTION
    Scans for files of given extensions exceeding a size threshold, exports to CSV.
.PARAMETER RootPath
    Root directory to scan.
.PARAMETER Extensions
    Array of file extensions (e.g. '.log','.mp4').
.PARAMETER MinSizeMB
    Minimum file size in MB.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$RootPath = 'C:\',
    [string[]]$Extensions = @('.log', '.mp4', '.zip'),
    [int]$MinSizeMB = 100,
    [string]$OutputCsv = 'LargeFilesByType.csv'
)

$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $Extensions -contains $_.Extension -and $_.Length -ge ($MinSizeMB * 1MB) }
$files | Select-Object FullName, Length, LastWriteTime | Export-Csv -Path $OutputCsv -NoTypeInformation
$files | Format-Table -AutoSize FullName, Length, LastWriteTime
