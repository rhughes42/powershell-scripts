<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Automated test for bandwidth monitoring script.
.DESCRIPTION
    Runs the bandwidth monitor and checks for output file and plausible data.
#>
& ../network/monitor-bandwidth-usage.ps1 -IntervalSeconds 1 -DurationSeconds 5 -OutputCsv 'test_bandwidth_out.csv'
if (Test-Path 'test_bandwidth_out.csv') {
    $results = Import-Csv 'test_bandwidth_out.csv'
    if ($results.Adapter -and $results.Rx_Mbps) {
        Write-Host '✓ Bandwidth monitor test passed: Output file contains expected data' -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host '❌ Bandwidth monitor test failed: Missing required data columns' -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host '❌ Bandwidth monitor test failed: Output file not created' -ForegroundColor Red
    exit 1
}
