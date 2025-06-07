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
        Write-Host 'System audit test passed.'
    }
    else {
        Write-Host 'System audit test failed: missing data.'
    }
}
else {
    Write-Host 'System audit test failed: missing files.'
}
