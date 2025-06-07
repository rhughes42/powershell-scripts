<#

 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Test VPN connectivity: ping, DNS resolution, TCP port checks, TLS handshake, and timing.
.DESCRIPTION
    PowerShell 7 script for end-to-end validation of VPN endpoints.
    Outputs console report and CSV results for latency and connectivity.
.PARAMETER Hosts
    List of hosts or IPs to ping and resolve.
.PARAMETER TcpEndpoints
    List of host:port tuples for TCP and TLS tests.
.PARAMETER PingCount
    Number of ICMP echo requests per host.
.PARAMETER OutputCsv
    File path to export ping results to CSV.
#>

param (
    [string[]]$Hosts = @('8.8.8.8', '1.1.1.1'),
    [string[]]$TcpEndpoints = @('google.com:443', 'protonvpn.com:443'),
    [int]     $PingCount = 4,
    [string]  $OutputCsv = "VpnTestResults.csv"
)

#region Helper Functions
<#
.SYNOPSIS
    Tests network connectivity to a specified host using the ping command.

.DESCRIPTION
    The Test-Ping function sends ICMP echo requests to a specified host to determine network connectivity.
    It can be used to verify if a remote computer or device is reachable from the local machine.

.PARAMETER TargetHost
    The hostname or IP address to ping.
    This parameter specifies the target host for the ping test. It can be a valid hostname (e.g., "google.com") or an IP address (e.g., "8.8.8.8").

.EXAMPLE
    Test-Ping -TargetHost "google.com"
    Tests connectivity to google.com.

.OUTPUTS
    PSCustomObject
    Returns an object with the properties: Host, Status (Success/Failed), AvgLatency, MinLatency, and MaxLatency.
    If the ping fails, AvgLatency, MinLatency, and MaxLatency will be null.
    If successful, AvgLatency will be the average response time in milliseconds.
#>
function Test-Ping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TargetHost
    )
    $results = Test-Connection -ComputerName $TargetHost -Count $PingCount -ErrorAction SilentlyContinue
    if (-not $results) {
        return [PSCustomObject]@{ Host = $TargetHost; Status = 'Failed'; AvgLatency = $null; MinLatency = $null; MaxLatency = $null }
    }
    else {
        $avg = ($results | Measure-Object -Property ResponseTime -Average).Average
        $min = ($results | Measure-Object -Property ResponseTime -Minimum).Minimum
        $max = ($results | Measure-Object -Property ResponseTime -Maximum).Maximum
        return [PSCustomObject]@{ Host = $TargetHost; Status = 'Success'; AvgLatency = [math]::Round($avg, 2); MinLatency = $min; MaxLatency = $max }
    }
}

<#
.SYNOPSIS
    Tests TCP connectivity to a specified endpoint and measures latency.

.DESCRIPTION
    The Test-TcpPort function attempts to establish a TCP connection to a given host and port combination.
    It returns an object containing the endpoint, TCP status (Open or Closed), and the measured latency in milliseconds.

.PARAMETER Endpoint
    The target endpoint in the format 'hostname:port' to test TCP connectivity against.

.EXAMPLE
    Test-TcpPort -Endpoint "example.com:443"
    Tests TCP connectivity to example.com on port 443 and returns the connection status and latency.

.OUTPUTS
    PSCustomObject
    Returns an object with the properties: Endpoint, TcpStatus (Open/Closed), and LatencyMs.
    If the connection fails, TcpStatus will be 'Closed' and LatencyMs will be the time taken to attempt the connection.
#>
function Test-TcpPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Endpoint
    )
    $host, $port = $Endpoint -split ':'
    $start = Get-Date
    $res = Test-NetConnection -ComputerName $host -Port [int]$port -WarningAction SilentlyContinue
    $lat = ((Get-Date) - $start).TotalMilliseconds
    return [PSCustomObject]@{ Endpoint = $Endpoint; TcpStatus = if ($res.TcpTestSucceeded) { 'Open' } else { 'Closed' }; LatencyMs = [math]::Round($lat, 2) }
}

<#
.SYNOPSIS
    Tests DNS resolution for a specified hostname.

.DESCRIPTION
    The Test-DnsResolve function attempts to resolve the DNS name provided as input and returns the result of the resolution attempt.

.PARAMETER TargetHost
    The hostname or IP address to resolve. If it is an IP address, it will return the status without DNS resolution.

.EXAMPLE
    Test-DnsResolve -TargetHost "example.com"
    Attempts to resolve "example.com" and returns the result.

.OUTPUTS
    PSCustomObject
    Returns an object with the properties: Host, Status, ResolveTimeMs, and Addresses.
    If the resolution fails, it returns 'Failed' status and null for ResolveTimeMs.
    If successful, it returns the resolved IP addresses as a comma-separated string.
#>
function Test-DnsResolve {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TargetHost
    )
    $start = Get-Date
    try {
        $resp = Resolve-DnsName -Name $TargetHost -ErrorAction Stop
        $time = ((Get-Date) - $start).TotalMilliseconds
        $addrs = ($resp | Where-Object IPAddress | Select-Object -Expand IPAddress) -join ','
        return [PSCustomObject]@{ Host = $TargetHost; Status = 'Resolved'; ResolveTimeMs = [math]::Round($time, 2); Addresses = $addrs }
    }
    catch {
        return [PSCustomObject]@{ Host = $TargetHost; Status = 'Failed'; ResolveTimeMs = $null; Addresses = '' }
    }
}

<#
.SYNOPSIS
    Tests TLS handshake with a specified endpoint.

.DESCRIPTION
    The Test-TlsHandshake function attempts to establish a TLS handshake with a given server or endpoint.
    It can be used to verify connectivity and TLS configuration for troubleshooting or validation purposes.

.PARAMETER Endpoint
    The target endpoint in the format 'hostname:port' to test the TLS handshake against.

.EXAMPLE
    Test-TlsHandshake -Server 'example.com' -Port 443
    Tests the TLS handshake to example.com on port 443.

.OUTPUTS
    PSCustomObject
    Returns an object with the properties: Endpoint, HandshakeMs, Issuer, Subject, and Expiration.
    If the handshake fails, it returns null for HandshakeMs and empty strings for Issuer and Subject.
#>
function Test-TlsHandshake {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Endpoint
    )
    $host, $port = $Endpoint -split ':'
    try {
        $tcp = [System.Net.Sockets.TcpClient]::new()
        $start = Get-Date
        $tcp.Connect($host, [int]$port)
        $ssl = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({ $true }))
        $ssl.AuthenticateAsClient($host)
        $time = ((Get-Date) - $start).TotalMilliseconds
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $ssl.RemoteCertificate
        return [PSCustomObject]@{
            Endpoint = $Endpoint; HandshakeMs = [math]::Round($time, 2); Issuer = $cert.Issuer; Subject = $cert.Subject; Expiration = $cert.NotAfter
        }
    }
    catch {
        return [PSCustomObject]@{ Endpoint = $Endpoint; HandshakeMs = $null; Issuer = ''; Subject = ''; Expiration = $null }
    }
    finally {
        $ssl.Dispose()    ; $tcp.Close()
    }
}
#endregion

#  Validate PowerShell Version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "This script is written for PowerShell 7+. Functionality is not guaranteed on earlier versions."
}

# Main Script Execution
$timestamp = Get-Date -Format 'dd-MM-yyyy_HH-mm'
Write-Host "=== [Graph Technologies] VPN Test Report - $timestamp ===`n"

Write-Log "Starting Ping Tests..."
$pingStart = Get-Date
$pingResults = $Hosts | ForEach-Object { Test-Ping -TargetHost $_ }
$pingElapsed = ((Get-Date) - $pingStart).TotalSeconds
$pingResults | Format-Table -AutoSize
Write-Log "Ping Tests completed in $([math]::Round($pingElapsed,2)) seconds.`n"

# 2) DNS Resolution Tests
$dnsTargets = $Hosts | Where-Object { $_ -notmatch '^[0-9\.]+$' }
if ($dnsTargets) {
    Write-Log "Starting DNS Resolution Tests..."
    $dnsStart = Get-Date
    $dnsResults = $dnsTargets | ForEach-Object { Test-DnsResolve -TargetHost $_ }
    $dnsElapsed = ((Get-Date) - $dnsStart).TotalSeconds
    $dnsResults | Format-Table -AutoSize
    Write-Log "DNS Resolution Tests completed in $([math]::Round($dnsElapsed,2)) seconds.`n"
}

# 3) TCP Port Connectivity
Write-Log "Starting TCP Port Connectivity Tests..."
$tcpStart = Get-Date
$tcpResults = $TcpEndpoints | ForEach-Object { Test-TcpPort -Endpoint $_ }
$tcpElapsed = ((Get-Date) - $tcpStart).TotalSeconds
$tcpResults | Format-Table -AutoSize
Write-Log "TCP Port Connectivity Tests completed in $([math]::Round($tcpElapsed,2)) seconds.`n"

# 4) TLS Handshake Validation
Write-Log "Starting TLS Handshake Validation..."
$tlsStart = Get-Date
$tlsResults = $TcpEndpoints | ForEach-Object { Test-TlsHandshake -Endpoint $_ }
$tlsElapsed = ((Get-Date) - $tlsStart).TotalSeconds
$tlsResults | Format-Table Endpoint, HandshakeMs, Issuer, Expiration -AutoSize
Write-Log "TLS Handshake Validation completed in $([math]::Round($tlsElapsed,2)) seconds.`n"

# 5) Export Ping Results to CSV
Write-Log "Exporting ping results to $OutputCsv ..."
$pingResults | Select-Object Host, Status, AvgLatency, MinLatency, MaxLatency | Export-Csv -Path $OutputCsv -NoTypeInformation
Write-Log "Ping results saved to $OutputCsv"