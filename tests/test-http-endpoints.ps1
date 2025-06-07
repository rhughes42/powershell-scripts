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
& ../network/test-http-endpoints.ps1 -Urls @('https://www.microsoft.com','https://expired.badssl.com') -OutputCsv 'test_http_out.csv'
if (Test-Path 'test_http_out.csv') {
    $results = Import-Csv 'test_http_out.csv'
    if ($results | Where-Object { $_.StatusCode -eq 200 }) {
        Write-Host 'HTTP endpoint test passed.'
    } else {
        Write-Host 'HTTP endpoint test failed: no 200 status.'
    }
} else {
    Write-Host 'HTTP endpoint test failed: missing file.'
}
