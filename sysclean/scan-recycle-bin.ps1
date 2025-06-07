<#
.SYNOPSIS
    Scan the Windows Recycle Bin for file count and size.
.DESCRIPTION
    Reports number and total size of items in the Recycle Bin, exports to CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'RecycleBinScan.csv'
)

$shell = New-Object -ComObject Shell.Application
$bin = $shell.Namespace(0xA)
$items = @(1..$bin.Items().Count | ForEach-Object { $bin.Items().Item($_-1) })
$totalSize = ($items | Measure-Object -Property Size -Sum).Sum
$results = [PSCustomObject]@{
    ItemCount = $items.Count
    TotalSizeMB = [math]::Round($totalSize/1MB,2)
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
