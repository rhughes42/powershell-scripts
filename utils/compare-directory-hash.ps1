<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Compare file hashes between two directories.
.DESCRIPTION
    Computes and compares hashes for all files in two directories, reporting differences and matches.
.PARAMETER PathA
    First directory path.
.PARAMETER PathB
    Second directory path.
.PARAMETER OutputCsv
    Path to export results.
#>

<#
.SYNOPSIS
    Get a hashtable of file relative paths and SHA256 hashes for a directory.
.DESCRIPTION
    Recursively computes SHA256 hashes for all files in the given directory and returns a hashtable mapping relative paths to hashes.
.PARAMETER dir
    The root directory to scan.
.OUTPUTS
    Hashtable mapping relative file paths to SHA256 hashes.
#>
function Get-FileHashTable($dir) {
    $table = @{}
    Get-ChildItem -Path $dir -Recurse -File | ForEach-Object {
        $hash = Get-FileHash $_.FullName -Algorithm SHA256
        $rel = $_.FullName.Substring($dir.Length).TrimStart('\','/')
        $table[$rel] = $hash.Hash
    }
    return $table
}

param(
    [string]$PathA,
    [string]$PathB,
    [string]$OutputCsv = 'DirHashCompare.csv'
)

$hashA = Get-FileHashTable $PathA
$hashB = Get-FileHashTable $PathB
$allKeys = $hashA.Keys + $hashB.Keys | Sort-Object -Unique
$results = foreach ($key in $allKeys) {
    [PSCustomObject]@{
        File = $key
        HashA = $hashA[$key]
        HashB = $hashB[$key]
        Status = if ($hashA[$key] -and $hashB[$key]) {
            if ($hashA[$key] -eq $hashB[$key]) { 'Match' } else { 'Different' }
        } elseif ($hashA[$key]) { 'OnlyInA' } else { 'OnlyInB' }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
