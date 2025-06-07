<#
.SYNOPSIS
    Find duplicate files by hash under a given path.
.DESCRIPTION
    Scans for files with identical hashes, exports groups to CSV.
.PARAMETER RootPath
    Root directory to scan.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$RootPath = 'C:\',
    [string]$OutputCsv = 'DuplicateFiles.csv'
)

$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue
$hashes = @{}
foreach ($file in $files) {
    $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
    if (-not $hashes.ContainsKey($hash)) { $hashes[$hash] = @() }
    $hashes[$hash] += $file.FullName
}
$dupes = $hashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
$results = @()
foreach ($d in $dupes) {
    foreach ($f in $d.Value) {
        $results += [PSCustomObject]@{ Hash = $d.Key; File = $f }
    }
}
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
$results | Format-Table -AutoSize Hash, File
