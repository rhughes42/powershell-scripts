<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Monitor network bandwidth usage per adapter over time.
.DESCRIPTION
    Samples bytes sent/received per network adapter at intervals, calculates bandwidth, and exports to CSV.
.PARAMETER IntervalSeconds
    Sampling interval in seconds.
.PARAMETER DurationSeconds
    Total monitoring duration in seconds.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [int]$IntervalSeconds = 2,
    [int]$DurationSeconds = 60,
    [string]$OutputCsv = 'BandwidthUsage.csv'
)

$end = (Get-Date).AddSeconds($DurationSeconds)
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
$prevStats = @{}
foreach ($adapter in $adapters) {
    $stats = Get-NetAdapterStatistics -Name $adapter.Name
    $prevStats[$adapter.Name] = @($stats.ReceivedBytes, $stats.SentBytes)
}
$results = @()
while ((Get-Date) -lt $end) {
    Start-Sleep -Seconds $IntervalSeconds
    foreach ($adapter in $adapters) {
        $stats = Get-NetAdapterStatistics -Name $adapter.Name
        $prev = $prevStats[$adapter.Name]
        $rx = $stats.ReceivedBytes - $prev[0]
        $tx = $stats.SentBytes - $prev[1]
        $bandwidthRx = [math]::Round($rx*8/($IntervalSeconds*1000000),2) # Mbps
        $bandwidthTx = [math]::Round($tx*8/($IntervalSeconds*1000000),2) # Mbps
        $results += [PSCustomObject]@{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Adapter = $adapter.Name
            Rx_Mbps = $bandwidthRx
            Tx_Mbps = $bandwidthTx
        }
        $prevStats[$adapter.Name] = @($stats.ReceivedBytes, $stats.SentBytes)
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
