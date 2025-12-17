<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Automated test for HTTP endpoint script.
.DESCRIPTION
    Runs the HTTP endpoint test script and checks for expected output and status codes.
#>
& ../network/test-http-endpoints.ps1 -Urls @('https://www.microsoft.com', 'https://expired.badssl.com') -OutputCsv 'test_http_out.csv'
if (Test-Path 'test_http_out.csv') {
    $results = Import-Csv 'test_http_out.csv'
    if ($results | Where-Object { $_.StatusCode -eq 200 }) {
        Write-Host '✓ HTTP endpoint test passed: Found successful responses' -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host '❌ HTTP endpoint test failed: No successful responses (200 status code)' -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host '❌ HTTP endpoint test failed: Output file not created' -ForegroundColor Red
    exit 1
}
