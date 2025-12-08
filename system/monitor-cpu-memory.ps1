<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics
#>

<#
.SYNOPSIS
    Monitor CPU and memory usage over time.
.DESCRIPTION
    Samples CPU and memory usage at intervals, logs to console and CSV, and alerts if thresholds are exceeded.
.PARAMETER IntervalSeconds
    Sampling interval in seconds.
.PARAMETER DurationSeconds
    Total monitoring duration in seconds.
.PARAMETER CpuThreshold
    CPU usage alert threshold (percent).
.PARAMETER MemoryThreshold
    Memory usage alert threshold (percent).
.PARAMETER OutputCsv
    Path to export monitoring data.
#>
param(
    [int]$IntervalSeconds = 5,
    [int]$DurationSeconds = 60,
    [int]$CpuThreshold = 80,
    [int]$MemoryThreshold = 80,
    [string]$OutputCsv = 'CpuMemMonitor.csv'
)

# Calculate monitoring end time
$end = (Get-Date).AddSeconds($DurationSeconds)
$results = @()

# Continuous monitoring loop until duration expires
while ((Get-Date) -lt $end) {
    # Query Windows Performance Counters for CPU usage (all cores combined)
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
    # Query memory usage as percentage of committed bytes
    $mem = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples[0].CookedValue
    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    # Alert when thresholds are exceeded
    if ($cpu -ge $CpuThreshold) { Write-Host "[ALERT] CPU usage high: $([math]::Round($cpu,2))% at $now" -ForegroundColor Red }
    if ($mem -ge $MemoryThreshold) { Write-Host "[ALERT] Memory usage high: $([math]::Round($mem,2))% at $now" -ForegroundColor Red }
    
    # Store sample data for export
    $results += [PSCustomObject]@{ Timestamp = $now; CpuPercent = [math]::Round($cpu, 2); MemoryPercent = [math]::Round($mem, 2) }
    
    # Wait for next sampling interval
    Start-Sleep -Seconds $IntervalSeconds
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
