<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Scan a host or subnet for open TCP ports.
.DESCRIPTION
    Scans a range of ports on a host or across a subnet, outputs open ports, and exports results to CSV.
.PARAMETER Target
    Hostname, IP, or CIDR subnet to scan.
.PARAMETER Ports
    Array or range of ports to scan.
.PARAMETER OutputCsv
    Path to export results.
#>

<#
.SYNOPSIS
    Test if a TCP port is open on a host.
.DESCRIPTION
    Attempts to connect to the specified host and port, returns $true if open, $false otherwise.
.PARAMETER Host
    Hostname or IP address to test.
.PARAMETER Port
    TCP port number to test.
.OUTPUTS
    Boolean indicating if the port is open.
#>
function Test-Port {
    param($Host, $Port)
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $iar = $tcp.BeginConnect($Host, $Port, $null, $null)
        $success = $iar.AsyncWaitHandle.WaitOne(500)
        if ($success -and $tcp.Connected) {
            $tcp.Close()
            return $true
        }
        $tcp.Close()
        return $false
    } catch { return $false }
}

param(
    [string]$Target = '127.0.0.1',
    [int[]]$Ports = @(22, 80, 443, 3389),
    [string]$OutputCsv = 'PortScanResults.csv'
)

$results = @()
foreach ($port in $Ports) {
    if (Test-Port -Host $Target -Port $port) {
        Write-Host "Port $port open on $Target"
        $results += [PSCustomObject]@{ Host=$Target; Port=$port; Status='Open' }
    } else {
        $results += [PSCustomObject]@{ Host=$Target; Port=$port; Status='Closed' }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
