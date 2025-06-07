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
    [int]$IntervalSeconds = 2, # How often to sample (in seconds)
    [int]$DurationSeconds = 60, # Total duration to monitor (in seconds)
    [string]$OutputCsv = 'BandwidthUsage.csv' # Output CSV file path
)

# Calculate the end time for monitoring
$end = (Get-Date).AddSeconds($DurationSeconds)

# Get all network adapters that are currently up
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

# Initialize a hashtable to store previous byte counters for each adapter
$prevStats = @{}
foreach ($adapter in $adapters) {
    # Get initial statistics for each adapter
    $stats = Get-NetAdapterStatistics -Name $adapter.Name
    # Store received and sent bytes as the baseline
    $prevStats[$adapter.Name] = @($stats.ReceivedBytes, $stats.SentBytes)
}

$results = @() # Array to hold results for all samples

# Main monitoring loop: run until the end time is reached
while ((Get-Date) -lt $end) {
    Start-Sleep -Seconds $IntervalSeconds # Wait for the specified interval

    foreach ($adapter in $adapters) {
        # Get current statistics for the adapter
        $stats = Get-NetAdapterStatistics -Name $adapter.Name
        # Retrieve previous received/sent byte counts
        $prev = $prevStats[$adapter.Name]
        # Calculate bytes received and sent since last sample
        $rx = $stats.ReceivedBytes - $prev[0]
        $tx = $stats.SentBytes - $prev[1]
        # Convert bytes to megabits per second (Mbps)
        $bandwidthRx = [math]::Round($rx * 8 / ($IntervalSeconds * 1000000), 2) # Mbps received
        $bandwidthTx = [math]::Round($tx * 8 / ($IntervalSeconds * 1000000), 2) # Mbps sent
        # Store the results with timestamp and adapter name
        $results += [PSCustomObject]@{
            Timestamp = Get-Date -Format 'dd-MM-yyyy HH:mm:ss'
            Adapter   = $adapter.Name
            Rx_Mbps   = $bandwidthRx
            Tx_Mbps   = $bandwidthTx
        }
        # Update previous stats for the next interval
        $prevStats[$adapter.Name] = @($stats.ReceivedBytes, $stats.SentBytes)
    }
}

# Output results to the console in table format
$results | Format-Table -AutoSize

# Export results to CSV file
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
