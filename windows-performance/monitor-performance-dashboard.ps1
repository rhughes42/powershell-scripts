<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Real-time Windows Performance Monitoring Dashboard with multi-metric tracking and alerts.
.DESCRIPTION
    Comprehensive performance monitoring solution that tracks CPU, memory, disk I/O, network, 
    and process metrics in real-time. Provides configurable thresholds with alerting capabilities
    and exports trending data for analysis.
.PARAMETER IntervalSeconds
    Sampling interval in seconds (default: 5)
.PARAMETER DurationSeconds
    Total monitoring duration in seconds (default: 300)
.PARAMETER CpuThreshold
    CPU usage alert threshold percentage (default: 80)
.PARAMETER MemoryThreshold
    Memory usage alert threshold percentage (default: 85)
.PARAMETER DiskQueueThreshold
    Disk queue length alert threshold (default: 5)
.PARAMETER NetworkMbpsThreshold
    Network throughput alert threshold in Mbps (default: 100)
.PARAMETER OutputCsv
    Path to export performance metrics (default: PerformanceDashboard.csv)
.PARAMETER EnableWebhook
    Enable webhook notifications for alerts
.PARAMETER WebhookUrl
    Webhook URL for alert notifications (Teams, Slack, etc.)
.EXAMPLE
    .\monitor-performance-dashboard.ps1 -DurationSeconds 600 -IntervalSeconds 10
    Monitors performance for 10 minutes with 10-second intervals
.EXAMPLE
    .\monitor-performance-dashboard.ps1 -EnableWebhook -WebhookUrl "https://hooks.slack.com/..." -CpuThreshold 70
    Monitors with Slack webhook alerts when CPU exceeds 70%
#>

param(
    [int]$IntervalSeconds = 5,
    [int]$DurationSeconds = 300,
    [int]$CpuThreshold = 80,
    [int]$MemoryThreshold = 85,
    [int]$DiskQueueThreshold = 5,
    [int]$NetworkMbpsThreshold = 100,
    [string]$OutputCsv = 'PerformanceDashboard.csv',
    [switch]$EnableWebhook,
    [string]$WebhookUrl = ''
)

# Validate PowerShell Version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "This script is optimized for PowerShell 7+. Some features may not work on earlier versions."
}

#region Helper Functions

<#
.SYNOPSIS
    Sends alert notification via webhook
#>
function Send-AlertNotification {
    param(
        [string]$Message,
        [string]$Severity = 'Warning'
    )
    
    if (-not $EnableWebhook -or [string]::IsNullOrEmpty($WebhookUrl)) {
        return
    }
    
    try {
        $payload = @{
            text = "[$Severity] Performance Alert"
            attachments = @(@{
                color = if ($Severity -eq 'Critical') { 'danger' } else { 'warning' }
                text = $Message
                footer = "Graph Performance Monitor"
                ts = [int][double]::Parse((Get-Date -UFormat %s))
            })
        } | ConvertTo-Json -Depth 3
        
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType 'application/json' -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to send webhook notification: $_"
    }
}

<#
.SYNOPSIS
    Collects comprehensive performance metrics
#>
function Get-PerformanceSnapshot {
    try {
        # CPU Metrics
        $cpuTotal = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        
        # Memory Metrics
        $memCommitted = (Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $memAvailableMB = (Get-Counter '\Memory\Available MBytes' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        
        # Disk Metrics
        $diskQueue = (Get-Counter '\PhysicalDisk(_Total)\Current Disk Queue Length' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $diskReadBps = (Get-Counter '\PhysicalDisk(_Total)\Disk Read Bytes/sec' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $diskWriteBps = (Get-Counter '\PhysicalDisk(_Total)\Disk Write Bytes/sec' -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        
        # Network Metrics - filter to physical adapters only
        $physicalAdapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' }
        $netBytesBps = 0
        if ($physicalAdapters) {
            $netCounters = (Get-Counter '\Network Interface(*)\Bytes Total/sec' -ErrorAction SilentlyContinue).CounterSamples
            foreach ($adapter in $physicalAdapters) {
                $matchingCounters = $netCounters | Where-Object { $_.InstanceName -like "*$($adapter.InterfaceDescription)*" -or $_.InstanceName -eq $adapter.Name }
                $netBytesBps += ($matchingCounters | Measure-Object -Property CookedValue -Sum).Sum
            }
        }
        
        # Process Metrics
        $processCount = (Get-Process).Count
        $topCpuProcess = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1
        $topMemProcess = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 1
        
        return [PSCustomObject]@{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            CpuPercent = [math]::Round($cpuTotal, 2)
            MemoryPercent = [math]::Round($memCommitted, 2)
            MemoryAvailableMB = [math]::Round($memAvailableMB, 2)
            DiskQueueLength = [math]::Round($diskQueue, 2)
            DiskReadMBps = [math]::Round($diskReadBps / 1MB, 2)
            DiskWriteMBps = [math]::Round($diskWriteBps / 1MB, 2)
            NetworkMbps = [math]::Round(($netBytesBps * 8) / 1MB, 2)
            ProcessCount = $processCount
            TopCpuProcess = $topCpuProcess.ProcessName
            TopCpuProcessCPU = [math]::Round($topCpuProcess.CPU, 2)
            TopMemProcess = $topMemProcess.ProcessName
            TopMemProcessMB = [math]::Round($topMemProcess.WorkingSet64 / 1MB, 2)
        }
    }
    catch {
        Write-Warning "Failed to collect performance snapshot: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Checks metrics against thresholds and generates alerts
#>
function Test-PerformanceThresholds {
    param($Snapshot)
    
    $alerts = @()
    
    if ($Snapshot.CpuPercent -ge $CpuThreshold) {
        $alert = "CPU usage at $($Snapshot.CpuPercent)% (threshold: $CpuThreshold%) - Top process: $($Snapshot.TopCpuProcess)"
        $alerts += $alert
        Write-Host "[ALERT] $alert" -ForegroundColor Red
        Send-AlertNotification -Message $alert -Severity 'Warning'
    }
    
    if ($Snapshot.MemoryPercent -ge $MemoryThreshold) {
        $alert = "Memory usage at $($Snapshot.MemoryPercent)% (threshold: $MemoryThreshold%) - Available: $($Snapshot.MemoryAvailableMB) MB"
        $alerts += $alert
        Write-Host "[ALERT] $alert" -ForegroundColor Red
        Send-AlertNotification -Message $alert -Severity 'Warning'
    }
    
    if ($Snapshot.DiskQueueLength -ge $DiskQueueThreshold) {
        $alert = "Disk queue length at $($Snapshot.DiskQueueLength) (threshold: $DiskQueueThreshold)"
        $alerts += $alert
        Write-Host "[ALERT] $alert" -ForegroundColor Yellow
        Send-AlertNotification -Message $alert -Severity 'Warning'
    }
    
    if ($Snapshot.NetworkMbps -ge $NetworkMbpsThreshold) {
        $alert = "Network throughput at $($Snapshot.NetworkMbps) Mbps (threshold: $NetworkMbpsThreshold Mbps)"
        $alerts += $alert
        Write-Host "[ALERT] $alert" -ForegroundColor Yellow
        Send-AlertNotification -Message $alert -Severity 'Warning'
    }
    
    return $alerts
}

<#
.SYNOPSIS
    Displays performance dashboard in console
#>
function Show-PerformanceDashboard {
    param($Snapshot, $Stats)
    
    Clear-Host
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                 Graph Technologies - Performance Dashboard                    " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Timestamp: $($Snapshot.Timestamp)                     Monitoring: $($Stats.SamplesCollected)/$($Stats.TotalSamples) samples" -ForegroundColor Gray
    Write-Host ""
    
    # CPU Section
    $cpuColor = if ($Snapshot.CpuPercent -ge $CpuThreshold) { 'Red' } elseif ($Snapshot.CpuPercent -ge ($CpuThreshold * 0.8)) { 'Yellow' } else { 'Green' }
    Write-Host "┌─ CPU Usage ────────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "│ Current: " -NoNewline -ForegroundColor White
    Write-Host "$($Snapshot.CpuPercent)%" -NoNewline -ForegroundColor $cpuColor
    Write-Host " │ Avg: $($Stats.AvgCpu)% │ Max: $($Stats.MaxCpu)% │ Min: $($Stats.MinCpu)%         " -ForegroundColor White
    Write-Host "│ Top Process: $($Snapshot.TopCpuProcess) (Total CPU: $($Snapshot.TopCpuProcessCPU)s)                              " -ForegroundColor Gray
    Write-Host "└────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    # Memory Section
    $memColor = if ($Snapshot.MemoryPercent -ge $MemoryThreshold) { 'Red' } elseif ($Snapshot.MemoryPercent -ge ($MemoryThreshold * 0.8)) { 'Yellow' } else { 'Green' }
    Write-Host "┌─ Memory Usage ─────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "│ Current: " -NoNewline -ForegroundColor White
    Write-Host "$($Snapshot.MemoryPercent)%" -NoNewline -ForegroundColor $memColor
    Write-Host " │ Available: $($Snapshot.MemoryAvailableMB) MB                                     " -ForegroundColor White
    Write-Host "│ Top Process: $($Snapshot.TopMemProcess) ($($Snapshot.TopMemProcessMB) MB)                              " -ForegroundColor Gray
    Write-Host "└────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    # Disk Section
    $diskColor = if ($Snapshot.DiskQueueLength -ge $DiskQueueThreshold) { 'Red' } else { 'Green' }
    Write-Host "┌─ Disk I/O ─────────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "│ Queue Length: " -NoNewline -ForegroundColor White
    Write-Host "$($Snapshot.DiskQueueLength)" -NoNewline -ForegroundColor $diskColor
    Write-Host "                                                               " -ForegroundColor White
    Write-Host "│ Read: $($Snapshot.DiskReadMBps) MB/s │ Write: $($Snapshot.DiskWriteMBps) MB/s                              " -ForegroundColor Gray
    Write-Host "└────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    # Network Section
    $netColor = if ($Snapshot.NetworkMbps -ge $NetworkMbpsThreshold) { 'Red' } elseif ($Snapshot.NetworkMbps -ge ($NetworkMbpsThreshold * 0.8)) { 'Yellow' } else { 'Green' }
    Write-Host "┌─ Network ──────────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "│ Throughput: " -NoNewline -ForegroundColor White
    Write-Host "$($Snapshot.NetworkMbps) Mbps" -NoNewline -ForegroundColor $netColor
    Write-Host "                                                         " -ForegroundColor White
    Write-Host "└────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    # Process Count
    Write-Host "┌─ System ───────────────────────────────────────────────────────────────────┐" -ForegroundColor White
    Write-Host "│ Running Processes: $($Snapshot.ProcessCount)                                                     " -ForegroundColor Gray
    Write-Host "└────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor White
    Write-Host ""
    
    if ($Stats.TotalAlerts -gt 0) {
        Write-Host "⚠ Total Alerts: $($Stats.TotalAlerts)" -ForegroundColor Red
    }
    
    Write-Host "Press Ctrl+C to stop monitoring..." -ForegroundColor DarkGray
}

#endregion

# Main Execution
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "         Graph Technologies - Windows Performance Monitoring Dashboard          " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  • Duration: $DurationSeconds seconds ($($DurationSeconds/60) minutes)" -ForegroundColor Gray
Write-Host "  • Interval: $IntervalSeconds seconds" -ForegroundColor Gray
Write-Host "  • CPU Threshold: $CpuThreshold%" -ForegroundColor Gray
Write-Host "  • Memory Threshold: $MemoryThreshold%" -ForegroundColor Gray
Write-Host "  • Disk Queue Threshold: $DiskQueueThreshold" -ForegroundColor Gray
Write-Host "  • Network Threshold: $NetworkMbpsThreshold Mbps" -ForegroundColor Gray
Write-Host "  • Output CSV: $OutputCsv" -ForegroundColor Gray
if ($EnableWebhook) {
    Write-Host "  • Webhook Alerts: Enabled" -ForegroundColor Green
}
Write-Host ""
Write-Host "Starting monitoring in 3 seconds..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

$endTime = (Get-Date).AddSeconds($DurationSeconds)
$results = @()
$totalAlerts = 0
$sampleCount = 0
$totalSamples = [math]::Ceiling($DurationSeconds / $IntervalSeconds)

# Initialize statistics
$cpuStats = @()
$memStats = @()

try {
    while ((Get-Date) -lt $endTime) {
        $snapshot = Get-PerformanceSnapshot
        
        if ($null -eq $snapshot) {
            Write-Warning "Failed to collect performance snapshot. Retrying..."
            Start-Sleep -Seconds $IntervalSeconds
            continue
        }
        
        $sampleCount++
        $results += $snapshot
        $cpuStats += $snapshot.CpuPercent
        $memStats += $snapshot.MemoryPercent
        
        # Check thresholds and alert
        $alerts = Test-PerformanceThresholds -Snapshot $snapshot
        $totalAlerts += $alerts.Count
        
        # Calculate statistics
        $stats = @{
            SamplesCollected = $sampleCount
            TotalSamples = $totalSamples
            TotalAlerts = $totalAlerts
            AvgCpu = [math]::Round(($cpuStats | Measure-Object -Average).Average, 2)
            MaxCpu = [math]::Round(($cpuStats | Measure-Object -Maximum).Maximum, 2)
            MinCpu = [math]::Round(($cpuStats | Measure-Object -Minimum).Minimum, 2)
            AvgMem = [math]::Round(($memStats | Measure-Object -Average).Average, 2)
        }
        
        # Display dashboard
        Show-PerformanceDashboard -Snapshot $snapshot -Stats $stats
        
        Start-Sleep -Seconds $IntervalSeconds
    }
}
catch {
    Write-Host "`n`nMonitoring interrupted." -ForegroundColor Yellow
}

# Final Report
Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                           Monitoring Complete                                  " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary Statistics:" -ForegroundColor Yellow
Write-Host "  • Total Samples: $sampleCount" -ForegroundColor Gray
Write-Host "  • Total Alerts: $totalAlerts" -ForegroundColor Gray
Write-Host "  • Average CPU: $([math]::Round(($cpuStats | Measure-Object -Average).Average, 2))%" -ForegroundColor Gray
Write-Host "  • Peak CPU: $([math]::Round(($cpuStats | Measure-Object -Maximum).Maximum, 2))%" -ForegroundColor Gray
Write-Host "  • Average Memory: $([math]::Round(($memStats | Measure-Object -Average).Average, 2))%" -ForegroundColor Gray
Write-Host ""

# Export to CSV
Write-Host "Exporting performance data to $OutputCsv..." -ForegroundColor Yellow
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
Write-Host "Export complete. Data saved to: $OutputCsv" -ForegroundColor Green
Write-Host ""
Write-Host "Graph Technologies · https://graphtechnologies.xyz/" -ForegroundColor Cyan
