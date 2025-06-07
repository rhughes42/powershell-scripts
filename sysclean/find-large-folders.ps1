<#
.SYNOPSIS
    Find large folders under a given path.
.DESCRIPTION
    Recursively scans for folders exceeding a size threshold, exports to CSV.
.PARAMETER RootPath
    Root directory to scan.
.PARAMETER MinSizeMB
    Minimum folder size in MB.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$RootPath = 'C:\',
    [int]$MinSizeMB = 500,
    [string]$OutputCsv = 'LargeFolders.csv'
)

$folders = Get-ChildItem -Path $RootPath -Directory -Recurse -ErrorAction SilentlyContinue
$results = @()
foreach ($folder in $folders) {
    $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($size -ge ($MinSizeMB * 1MB)) {
        $results += [PSCustomObject]@{
            Folder = $folder.FullName
            SizeMB = [math]::Round($size / 1MB, 2)
        }
    }
}
$results | Sort-Object SizeMB -Descending | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
