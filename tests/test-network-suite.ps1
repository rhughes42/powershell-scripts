<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Automated test suite for network scripts.
.DESCRIPTION
    Runs a series of network diagnostics and checks for expected results.
#>

# Run DNS test script and check output
$dnsTest = & ../network/test-dns.ps1 -Hosts @('google.com') -OutputCsv 'test_dns_out.csv'

# Run traceroute test script and check output
$traceTest = & ../network/trace-multi-hop.ps1 -Hosts @('google.com') -OutputCsv 'test_trace_out.csv'

# Run bandwidth monitor test script and check output
$bandwidthTest = & ../tests/test-bandwidth-monitor.ps1

# Run HTTP endpoint test script and check output
$httpTest = & ../tests/test-http-endpoints.ps1

# Validate all expected output files exist
$allPassed = $true

# Validate DNS test output file and contents
if (-not (Test-Path 'test_dns_out.csv')) {
    Write-Host 'DNS test failed: missing file.'
    $allPassed = $false
}
else {
    $dnsResults = Import-Csv 'test_dns_out.csv'
    # Check for expected DNS result columns
    if (-not $dnsResults.Hostname) {
        Write-Host 'DNS test failed: missing data.'
        $allPassed = $false
    }
}

# Validate traceroute test output file and contents
if (-not (Test-Path 'test_trace_out.csv')) {
    Write-Host 'Traceroute test failed: missing file.'
    $allPassed = $false
}
else {
    $traceResults = Import-Csv 'test_trace_out.csv'
    # Check for expected traceroute result columns
    if (-not $traceResults.Host -or -not $traceResults.HopCount) {
        Write-Host 'Traceroute test failed: missing data.'
        $allPassed = $false
    }
}

# Validate bandwidth monitor test output file and contents
if (-not (Test-Path 'test_bandwidth_out.csv')) {
    Write-Host 'Bandwidth monitor test failed: missing file.'
    $allPassed = $false
}
else {
    $bwResults = Import-Csv 'test_bandwidth_out.csv'
    # Check for expected bandwidth result columns
    if (-not $bwResults.Adapter -or -not $bwResults.Rx_Mbps) {
        Write-Host 'Bandwidth monitor test failed: missing data.'
        $allPassed = $false
    }
}

# Validate HTTP endpoint test output file and contents
if (-not (Test-Path 'test_http_out.csv')) {
    Write-Host 'HTTP endpoint test failed: missing file.'
    $allPassed = $false
}
else {
    $httpResults = Import-Csv 'test_http_out.csv'
    # Check for at least one HTTP 200 status code
    if (-not ($httpResults | Where-Object { $_.StatusCode -eq 200 })) {
        Write-Host 'HTTP endpoint test failed: no 200 status.'
        $allPassed = $false
    }
}

# Final test suite result
if ($allPassed) {
    Write-Host 'Network test suite passed.'
}
else {
    Write-Host 'Network test suite failed.'
}
