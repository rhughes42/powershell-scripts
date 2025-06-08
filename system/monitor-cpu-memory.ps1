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

$end = (Get-Date).AddSeconds($DurationSeconds)
$results = @()
while ((Get-Date) -lt $end) {
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
    $mem = (Get-Counter '\Memory\% Committed Bytes In Use').CounterSamples[0].CookedValue
    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    if ($cpu -ge $CpuThreshold) { Write-Host "[ALERT] CPU usage high: $([math]::Round($cpu,2))% at $now" -ForegroundColor Red }
    if ($mem -ge $MemoryThreshold) { Write-Host "[ALERT] Memory usage high: $([math]::Round($mem,2))% at $now" -ForegroundColor Red }
    $results += [PSCustomObject]@{ Timestamp = $now; CpuPercent = [math]::Round($cpu, 2); MemoryPercent = [math]::Round($mem, 2) }
    Start-Sleep -Seconds $IntervalSeconds
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
