<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Automated test for system audit scripts.
.DESCRIPTION
    Runs system info and software audit scripts, checks for expected output files, and validates content.
#>
& ../system/get-system-info.ps1 -OutputCsv 'test_sysinfo_out.csv'
& ../system/audit-installed-software.ps1 -OutputCsv 'test_software_out.csv'
if (Test-Path 'test_sysinfo_out.csv' -and Test-Path 'test_software_out.csv') {
    $sysinfo = Import-Csv 'test_sysinfo_out.csv'
    $software = Import-Csv 'test_software_out.csv'
    if ($sysinfo.ComputerName -and $software.Name) {
        Write-Host '✓ System audit test passed: All required data present' -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host '❌ System audit test failed: Missing data in CSV files' -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host '❌ System audit test failed: Missing output files' -ForegroundColor Red
    exit 1
}
