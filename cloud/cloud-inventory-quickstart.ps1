<#
.SYNOPSIS
    Quickstart: Run all cloud inventory scripts for a fast overview.
.DESCRIPTION
    Runs all inventory scripts in the cloud folder and summarizes results.
#>
$files = Get-ChildItem -Path $PSScriptRoot -Filter '*.ps1' | Where-Object { $_.Name -notlike '*suite*' -and $_.Name -notlike '*quickstart*' }
foreach ($file in $files) {
    Write-Host "Running $($file.Name) ..."
    & $file.FullName
}
Write-Host 'Cloud inventory quickstart complete.'
