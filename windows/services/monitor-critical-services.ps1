<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Monitor critical Windows services and auto-restart if stopped.
.DESCRIPTION
    Continuously monitors specified Windows services and automatically restarts them if they stop unexpectedly.
    Logs all actions and can send alerts. Useful for maintaining critical service availability.
.PARAMETER ServiceNames
    Array of service names to monitor
.PARAMETER CheckIntervalSeconds
    How often to check service status (default: 60 seconds)
.PARAMETER AutoRestart
    Automatically restart stopped services (default: true)
.PARAMETER LogFile
    Path to log file for monitoring actions
.PARAMETER MaxRestartAttempts
    Maximum restart attempts before alerting (default: 3)
.EXAMPLE
    .\monitor-critical-services.ps1 -ServiceNames "W32Time","Spooler" -CheckIntervalSeconds 30
    Monitors Windows Time and Print Spooler services every 30 seconds
#>

param(
    [Parameter(Mandatory)]
    [string[]]$ServiceNames,
    
    [int]$CheckIntervalSeconds = 60,
    [bool]$AutoRestart = $true,
    [string]$LogFile = "ServiceMonitor_$(Get-Date -Format 'yyyyMMdd').log",
    [int]$MaxRestartAttempts = 3
)

#Requires -RunAsAdministrator

# Hashtable to track restart attempts per service
$restartAttempts = @{}
foreach ($svc in $ServiceNames) {
    $restartAttempts[$svc] = 0
}

# Logging function with timestamp
function Write-ServiceLog {
    param([string]$Message, [string]$Level = 'INFO')
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Console output with color based on level
    $color = switch ($Level) {
        'ERROR' { 'Red' }
        'WARNING' { 'Yellow' }
        'SUCCESS' { 'Green' }
        default { 'White' }
    }
    Write-Host $logEntry -ForegroundColor $color
    
    # Append to log file
    $logEntry | Out-File -FilePath $LogFile -Append -Encoding utf8
}

# Function to check and restart a service
function Test-AndRestartService {
    param([string]$ServiceName)
    
    try {
        # Get current service status
        $service = Get-Service -Name $ServiceName -ErrorAction Stop
        
        # Check if service is stopped or in an unhealthy state
        if ($service.Status -ne 'Running') {
            Write-ServiceLog "Service '$($service.DisplayName)' is $($service.Status)" 'WARNING'
            
            # Check if we've exceeded max restart attempts
            if ($restartAttempts[$ServiceName] -ge $MaxRestartAttempts) {
                Write-ServiceLog "Service '$($service.DisplayName)' has exceeded max restart attempts ($MaxRestartAttempts)" 'ERROR'
                Write-ServiceLog "Manual intervention required for $ServiceName" 'ERROR'
                return $false
            }
            
            # Attempt to restart if auto-restart is enabled
            if ($AutoRestart) {
                Write-ServiceLog "Attempting to restart '$($service.DisplayName)'..." 'WARNING'
                
                try {
                    Start-Service -Name $ServiceName -ErrorAction Stop
                    Start-Sleep -Seconds 3
                    
                    # Verify service started successfully
                    $service = Get-Service -Name $ServiceName
                    if ($service.Status -eq 'Running') {
                        $restartAttempts[$ServiceName]++
                        Write-ServiceLog "Successfully restarted '$($service.DisplayName)' (Attempt $($restartAttempts[$ServiceName])/$MaxRestartAttempts)" 'SUCCESS'
                        return $true
                    }
                    else {
                        $restartAttempts[$ServiceName]++
                        Write-ServiceLog "Failed to restart '$($service.DisplayName)' - Status: $($service.Status)" 'ERROR'
                        return $false
                    }
                }
                catch {
                    $restartAttempts[$ServiceName]++
                    Write-ServiceLog "Exception while restarting '$ServiceName': $_" 'ERROR'
                    return $false
                }
            }
        }
        else {
            # Service is running - reset restart counter
            if ($restartAttempts[$ServiceName] -gt 0) {
                Write-ServiceLog "Service '$($service.DisplayName)' is stable - resetting restart counter" 'INFO'
                $restartAttempts[$ServiceName] = 0
            }
            return $true
        }
    }
    catch {
        Write-ServiceLog "Error checking service '$ServiceName': $_" 'ERROR'
        return $false
    }
    
    return $false
}

# Main monitoring loop
Write-ServiceLog "=== Service Monitoring Started ===" 'INFO'
Write-ServiceLog "Monitoring services: $($ServiceNames -join ', ')" 'INFO'
Write-ServiceLog "Check interval: $CheckIntervalSeconds seconds" 'INFO'
Write-ServiceLog "Auto-restart: $AutoRestart" 'INFO'
Write-ServiceLog "Log file: $LogFile" 'INFO'
Write-Host "`nPress Ctrl+C to stop monitoring...`n" -ForegroundColor Cyan

try {
    while ($true) {
        # Check each service in the list
        foreach ($serviceName in $ServiceNames) {
            Test-AndRestartService -ServiceName $serviceName | Out-Null
        }
        
        # Wait for next check interval
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
}
finally {
    Write-ServiceLog "=== Service Monitoring Stopped ===" 'INFO'
}
