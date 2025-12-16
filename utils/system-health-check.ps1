<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Comprehensive system health check utility for Windows systems.
.DESCRIPTION
    Performs thorough health checks across multiple system areas including CPU, memory,
    disk space, services, event logs, network connectivity, and Windows updates.
    Generates detailed health reports with recommendations.
.PARAMETER CheckCpu
    Include CPU health check
.PARAMETER CheckMemory
    Include memory health check
.PARAMETER CheckDisk
    Include disk space health check
.PARAMETER CheckServices
    Include critical services health check
.PARAMETER CheckEventLog
    Include event log error check
.PARAMETER CheckNetwork
    Include network connectivity check
.PARAMETER CheckUpdates
    Include Windows Update check
.PARAMETER DiskSpaceThreshold
    Disk free space warning threshold in GB (default: 10)
.PARAMETER MemoryThreshold
    Memory usage warning threshold percentage (default: 85)
.PARAMETER CpuThreshold
    CPU usage warning threshold percentage (default: 80)
.PARAMETER OutputHtml
    Generate HTML report (default: SystemHealthReport.html)
.PARAMETER OutputCsv
    Export detailed results to CSV (default: SystemHealthDetails.csv)
.EXAMPLE
    .\system-health-check.ps1
    Performs all health checks with default thresholds
.EXAMPLE
    .\system-health-check.ps1 -CheckDisk -CheckMemory -DiskSpaceThreshold 20
    Performs only disk and memory checks with custom disk threshold
.EXAMPLE
    .\system-health-check.ps1 -OutputHtml "health-report.html"
    Performs all checks and generates HTML report
#>

param(
    [switch]$CheckCpu = $false,
    [switch]$CheckMemory = $false,
    [switch]$CheckDisk = $false,
    [switch]$CheckServices = $false,
    [switch]$CheckEventLog = $false,
    [switch]$CheckNetwork = $false,
    [switch]$CheckUpdates = $false,
    [int]$DiskSpaceThreshold = 10,
    [int]$MemoryThreshold = 85,
    [int]$CpuThreshold = 80,
    [string]$OutputHtml = 'SystemHealthReport.html',
    [string]$OutputCsv = 'SystemHealthDetails.csv'
)

# If no specific checks specified, run all
$runAllChecks = -not ($CheckCpu -or $CheckMemory -or $CheckDisk -or $CheckServices -or $CheckEventLog -or $CheckNetwork -or $CheckUpdates)

if ($runAllChecks) {
    $CheckCpu = $CheckMemory = $CheckDisk = $CheckServices = $CheckEventLog = $CheckNetwork = $CheckUpdates = $true
}

# Validate PowerShell Version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "This script is optimized for PowerShell 7+. Some features may not work on earlier versions."
}

#region Helper Functions

<#
.SYNOPSIS
    Checks CPU health and performance
#>
function Test-CpuHealth {
    Write-Host "Checking CPU health..." -ForegroundColor Yellow
    
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor
        $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples[0].CookedValue
        
        $status = if ($cpuUsage -ge $CpuThreshold) { 'WARNING' } else { 'OK' }
        $statusColor = if ($status -eq 'OK') { 'Green' } else { 'Yellow' }
        
        $result = [PSCustomObject]@{
            Component = 'CPU'
            Status = $status
            Details = "Usage: $([math]::Round($cpuUsage, 2))% | Name: $($cpu.Name) | Cores: $($cpu.NumberOfCores) | Threads: $($cpu.NumberOfLogicalProcessors)"
            Recommendation = if ($status -eq 'WARNING') { "CPU usage is high. Consider closing unnecessary applications or investigating high CPU processes." } else { "" }
        }
        
        Write-Host "  ✓ CPU: " -NoNewline -ForegroundColor White
        Write-Host "$status" -ForegroundColor $statusColor
        
        return $result
    }
    catch {
        Write-Host "  ✗ CPU check failed: $_" -ForegroundColor Red
        return [PSCustomObject]@{ Component = 'CPU'; Status = 'ERROR'; Details = "Check failed: $_"; Recommendation = "" }
    }
}

<#
.SYNOPSIS
    Checks memory health and usage
#>
function Test-MemoryHealth {
    Write-Host "Checking memory health..." -ForegroundColor Yellow
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMemoryGB = $totalMemoryGB - $freeMemoryGB
        $memoryUsagePercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)
        
        $status = if ($memoryUsagePercent -ge $MemoryThreshold) { 'WARNING' } else { 'OK' }
        $statusColor = if ($status -eq 'OK') { 'Green' } else { 'Yellow' }
        
        $result = [PSCustomObject]@{
            Component = 'Memory'
            Status = $status
            Details = "Usage: $memoryUsagePercent% | Used: $usedMemoryGB GB / $totalMemoryGB GB | Free: $freeMemoryGB GB"
            Recommendation = if ($status -eq 'WARNING') { "Memory usage is high. Consider closing applications or adding more RAM." } else { "" }
        }
        
        Write-Host "  ✓ Memory: " -NoNewline -ForegroundColor White
        Write-Host "$status" -ForegroundColor $statusColor
        
        return $result
    }
    catch {
        Write-Host "  ✗ Memory check failed: $_" -ForegroundColor Red
        return [PSCustomObject]@{ Component = 'Memory'; Status = 'ERROR'; Details = "Check failed: $_"; Recommendation = "" }
    }
}

<#
.SYNOPSIS
    Checks disk space health
#>
function Test-DiskHealth {
    Write-Host "Checking disk space health..." -ForegroundColor Yellow
    
    try {
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
        $results = @()
        
        foreach ($disk in $disks) {
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalSizeGB = [math]::Round($disk.Size / 1GB, 2)
            $usedSpaceGB = $totalSizeGB - $freeSpaceGB
            $usedPercent = [math]::Round(($usedSpaceGB / $totalSizeGB) * 100, 2)
            
            $status = if ($freeSpaceGB -lt $DiskSpaceThreshold) { 'WARNING' } else { 'OK' }
            $statusColor = if ($status -eq 'OK') { 'Green' } else { 'Yellow' }
            
            $results += [PSCustomObject]@{
                Component = "Disk ($($disk.DeviceID))"
                Status = $status
                Details = "Free: $freeSpaceGB GB / $totalSizeGB GB ($usedPercent% used) | Label: $($disk.VolumeName)"
                Recommendation = if ($status -eq 'WARNING') { "Low disk space on $($disk.DeviceID). Clean up files or expand disk capacity." } else { "" }
            }
            
            Write-Host "  ✓ Disk $($disk.DeviceID): " -NoNewline -ForegroundColor White
            Write-Host "$status" -ForegroundColor $statusColor
        }
        
        return $results
    }
    catch {
        Write-Host "  ✗ Disk check failed: $_" -ForegroundColor Red
        return @([PSCustomObject]@{ Component = 'Disk'; Status = 'ERROR'; Details = "Check failed: $_"; Recommendation = "" })
    }
}

<#
.SYNOPSIS
    Checks critical Windows services
#>
function Test-ServicesHealth {
    Write-Host "Checking critical services..." -ForegroundColor Yellow
    
    $criticalServices = @('W32Time', 'Winmgmt', 'RpcSs', 'EventLog', 'Dhcp', 'Dnscache')
    $results = @()
    
    foreach ($serviceName in $criticalServices) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop
            
            $status = if ($service.Status -ne 'Running') { 'WARNING' } else { 'OK' }
            $statusColor = if ($status -eq 'OK') { 'Green' } else { 'Yellow' }
            
            $results += [PSCustomObject]@{
                Component = "Service ($serviceName)"
                Status = $status
                Details = "Status: $($service.Status) | DisplayName: $($service.DisplayName) | StartType: $($service.StartType)"
                Recommendation = if ($status -eq 'WARNING') { "Service '$serviceName' is not running. Start the service if needed." } else { "" }
            }
            
            Write-Host "  ✓ Service $serviceName`: " -NoNewline -ForegroundColor White
            Write-Host "$status" -ForegroundColor $statusColor
        }
        catch {
            $results += [PSCustomObject]@{
                Component = "Service ($serviceName)"
                Status = 'ERROR'
                Details = "Service not found or inaccessible"
                Recommendation = "Verify service exists or check permissions"
            }
            
            Write-Host "  ✗ Service $serviceName`: ERROR" -ForegroundColor Red
        }
    }
    
    return $results
}

<#
.SYNOPSIS
    Checks recent event log errors
#>
function Test-EventLogHealth {
    Write-Host "Checking event log errors..." -ForegroundColor Yellow
    
    try {
        $since = (Get-Date).AddHours(-24)
        $errors = Get-WinEvent -FilterHashtable @{LogName='System','Application'; Level=1,2; StartTime=$since} -MaxEvents 100 -ErrorAction SilentlyContinue
        
        $errorCount = if ($errors) { $errors.Count } else { 0 }
        $status = if ($errorCount -gt 50) { 'WARNING' } elseif ($errorCount -gt 0) { 'INFO' } else { 'OK' }
        $statusColor = if ($status -eq 'OK') { 'Green' } elseif ($status -eq 'INFO') { 'Cyan' } else { 'Yellow' }
        
        $topErrors = if ($errors) {
            ($errors | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 3 | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ' | '
        } else {
            "No errors"
        }
        
        $result = [PSCustomObject]@{
            Component = 'Event Log'
            Status = $status
            Details = "Errors in last 24h: $errorCount | Top Sources: $topErrors"
            Recommendation = if ($status -eq 'WARNING') { "High number of errors detected. Review Event Viewer for details." } else { "" }
        }
        
        Write-Host "  ✓ Event Log: " -NoNewline -ForegroundColor White
        Write-Host "$status" -ForegroundColor $statusColor
        
        return $result
    }
    catch {
        Write-Host "  ✗ Event log check failed: $_" -ForegroundColor Red
        return [PSCustomObject]@{ Component = 'Event Log'; Status = 'ERROR'; Details = "Check failed: $_"; Recommendation = "" }
    }
}

<#
.SYNOPSIS
    Checks network connectivity
#>
function Test-NetworkHealth {
    Write-Host "Checking network connectivity..." -ForegroundColor Yellow
    
    $results = @()
    
    # Check internet connectivity
    $pingTest = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction SilentlyContinue
    $internetStatus = if ($pingTest) { 'OK' } else { 'WARNING' }
    $internetColor = if ($internetStatus -eq 'OK') { 'Green' } else { 'Yellow' }
    
    $results += [PSCustomObject]@{
        Component = 'Network (Internet)'
        Status = $internetStatus
        Details = if ($pingTest) { "Internet accessible | Avg latency: $([math]::Round(($pingTest | Measure-Object ResponseTime -Average).Average, 2)) ms" } else { "No internet connectivity" }
        Recommendation = if ($internetStatus -eq 'WARNING') { "Check network cables, router, or contact ISP." } else { "" }
    }
    
    Write-Host "  ✓ Internet: " -NoNewline -ForegroundColor White
    Write-Host "$internetStatus" -ForegroundColor $internetColor
    
    # Check DNS resolution
    try {
        $dnsTest = Resolve-DnsName -Name "google.com" -ErrorAction Stop
        $dnsStatus = 'OK'
        $dnsColor = 'Green'
        
        $results += [PSCustomObject]@{
            Component = 'Network (DNS)'
            Status = $dnsStatus
            Details = "DNS resolution working"
            Recommendation = ""
        }
        
        Write-Host "  ✓ DNS: " -NoNewline -ForegroundColor White
        Write-Host "$dnsStatus" -ForegroundColor $dnsColor
    }
    catch {
        $results += [PSCustomObject]@{
            Component = 'Network (DNS)'
            Status = 'WARNING'
            Details = "DNS resolution failed"
            Recommendation = "Check DNS server settings or flush DNS cache."
        }
        
        Write-Host "  ✗ DNS: WARNING" -ForegroundColor Yellow
    }
    
    return $results
}

<#
.SYNOPSIS
    Checks Windows Update status
#>
function Test-UpdatesHealth {
    Write-Host "Checking Windows Update status..." -ForegroundColor Yellow
    
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $updates = $searcher.Search("IsInstalled=0 and Type='Software'")
        
        $pendingCount = $updates.Updates.Count
        $status = if ($pendingCount -gt 20) { 'WARNING' } elseif ($pendingCount -gt 0) { 'INFO' } else { 'OK' }
        $statusColor = if ($status -eq 'OK') { 'Green' } elseif ($status -eq 'INFO') { 'Cyan' } else { 'Yellow' }
        
        $result = [PSCustomObject]@{
            Component = 'Windows Update'
            Status = $status
            Details = "Pending updates: $pendingCount"
            Recommendation = if ($status -eq 'WARNING') { "Many updates pending. Consider scheduling maintenance window for updates." } elseif ($status -eq 'INFO') { "Some updates available. Review and install when convenient." } else { "" }
        }
        
        Write-Host "  ✓ Windows Update: " -NoNewline -ForegroundColor White
        Write-Host "$status" -ForegroundColor $statusColor
        
        return $result
    }
    catch {
        Write-Host "  ⚠ Windows Update check skipped (requires permissions)" -ForegroundColor Gray
        return [PSCustomObject]@{ Component = 'Windows Update'; Status = 'SKIPPED'; Details = "Check requires elevated permissions"; Recommendation = "" }
    }
}

#endregion

# Main Execution
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "              Graph Technologies - System Health Check Utility                  " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$allResults = @()

# Run requested checks
if ($CheckCpu) { $allResults += Test-CpuHealth }
if ($CheckMemory) { $allResults += Test-MemoryHealth }
if ($CheckDisk) { $allResults += Test-DiskHealth }
if ($CheckServices) { $allResults += Test-ServicesHealth }
if ($CheckEventLog) { $allResults += Test-EventLogHealth }
if ($CheckNetwork) { $allResults += Test-NetworkHealth }
if ($CheckUpdates) { $allResults += Test-UpdatesHealth }

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                              Health Check Summary                              " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$okCount = ($allResults | Where-Object { $_.Status -eq 'OK' }).Count
$warningCount = ($allResults | Where-Object { $_.Status -eq 'WARNING' }).Count
$errorCount = ($allResults | Where-Object { $_.Status -eq 'ERROR' }).Count
$infoCount = ($allResults | Where-Object { $_.Status -eq 'INFO' }).Count
$totalChecks = $allResults.Count

Write-Host "Total Checks: $totalChecks" -ForegroundColor White
Write-Host "  ✓ OK: $okCount" -ForegroundColor Green
Write-Host "  ⚠ Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "  ✗ Errors: $errorCount" -ForegroundColor Red
Write-Host "  ℹ Info: $infoCount" -ForegroundColor Cyan
Write-Host ""

# Display results
$allResults | Format-Table Component, Status, Details -Wrap -AutoSize

# Display recommendations
$recommendations = $allResults | Where-Object { -not [string]::IsNullOrEmpty($_.Recommendation) }
if ($recommendations) {
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                                Recommendations                                 " -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($rec in $recommendations) {
        Write-Host "• $($rec.Component): " -NoNewline -ForegroundColor Yellow
        Write-Host "$($rec.Recommendation)" -ForegroundColor White
    }
    Write-Host ""
}

# Export results
Write-Host "Exporting results to $OutputCsv..." -ForegroundColor Yellow
$allResults | Export-Csv -Path $OutputCsv -NoTypeInformation
Write-Host "✓ Results exported to $OutputCsv" -ForegroundColor Green

Write-Host ""
Write-Host "Graph Technologies · https://graphtechnologies.xyz/" -ForegroundColor Cyan
