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

# Recursively scan all files under the root path
$files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue
$hashes = @{}

# Calculate hash for each file and group by hash value
foreach ($file in $files) {
    $hash = (Get-FileHash $file.FullName -Algorithm SHA256).Hash
    # Initialize array for this hash if not exists
    if (-not $hashes.ContainsKey($hash)) { $hashes[$hash] = @() }
    # Add file path to the hash group
    $hashes[$hash] += $file.FullName
}

# Filter to only hashes that have more than one file (duplicates)
$dupes = $hashes.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

# Flatten the duplicate groups into individual records for export
$results = @()
foreach ($d in $dupes) {
    foreach ($f in $d.Value) {
        $results += [PSCustomObject]@{ Hash = $d.Key; File = $f }
    }
}
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
$results | Format-Table -AutoSize Hash, File
