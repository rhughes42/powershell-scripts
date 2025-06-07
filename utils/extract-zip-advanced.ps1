<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Extract ZIP archives with filtering, flattening, and logging.
.DESCRIPTION
    Extracts ZIP files, supports file type filters, flattening directory structure, and logs extracted files.
.PARAMETER ZipPath
    Path to the ZIP archive.
.PARAMETER Destination
    Extraction destination directory.
.PARAMETER Filter
    Optional file extension filter (e.g., '*.txt').
.PARAMETER Flatten
    If set, flattens all files into the destination root.
.PARAMETER LogFile
    Optional log file for extracted files.
#>
param(
    [string]$ZipPath,
    [string]$Destination,
    [string]$Filter = '*',
    [switch]$Flatten,
    [string]$LogFile
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
$entries = $zip.Entries | Where-Object { $_.Name -like $Filter }
foreach ($entry in $entries) {
    $target = if ($Flatten) { Join-Path $Destination $entry.Name } else { Join-Path $Destination $entry.FullName }
    $dir = Split-Path $target -Parent
    if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
    $entry.ExtractToFile($target, $true)
    $msg = "Extracted: $target"
    Write-Host $msg
    if ($LogFile) { $msg | Out-File -FilePath $LogFile -Append -Encoding utf8 }
}
$zip.Dispose()
