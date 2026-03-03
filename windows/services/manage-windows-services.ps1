<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Comprehensive Windows Services management utility.
.DESCRIPTION
    Provides functionality to start, stop, restart, enable, disable Windows services.
    Can also query service status, dependencies, and perform bulk operations.
.PARAMETER Action
    Action to perform: List, Start, Stop, Restart, Enable, Disable, GetStatus, GetDependencies
.PARAMETER ServiceName
    Name of the service to manage (supports wildcards for List action)
.PARAMETER ComputerName
    Remote computer name (default: local computer)
.PARAMETER OutputCsv
    Path to export results for List action
.EXAMPLE
    .\manage-windows-services.ps1 -Action List -OutputCsv "services.csv"
    Lists all Windows services and exports to CSV
.EXAMPLE
    .\manage-windows-services.ps1 -Action Start -ServiceName "Spooler"
    Starts the Print Spooler service
.EXAMPLE
    .\manage-windows-services.ps1 -Action GetDependencies -ServiceName "W32Time"
    Shows all services that depend on Windows Time service
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('List', 'Start', 'Stop', 'Restart', 'Enable', 'Disable', 'GetStatus', 'GetDependencies')]
    [string]$Action,
    
    [string]$ServiceName = '*',
    [string]$ComputerName = $env:COMPUTERNAME,
    [string]$OutputCsv = 'WindowsServices.csv'
)

#Requires -RunAsAdministrator

# Function to get detailed service information
function Get-ServiceDetails {
    param([string]$Name, [string]$Computer)
    
    try {
        # Get service object with full details
        $service = Get-Service -Name $Name -ComputerName $Computer -ErrorAction Stop
        
        # Get WMI object for additional properties
        $wmiService = Get-CimInstance -ClassName Win32_Service -Filter "Name='$Name'" -ComputerName $Computer -ErrorAction SilentlyContinue
        
        return [PSCustomObject]@{
            Name        = $service.Name
            DisplayName = $service.DisplayName
            Status      = $service.Status
            StartType   = $service.StartType
            CanStop     = $service.CanStop
            CanPause    = $service.CanPauseAndContinue
            Account     = $wmiService.StartName
            PathName    = $wmiService.PathName
            Description = $wmiService.Description
        }
    }
    catch {
        Write-Warning "Failed to get details for service '$Name': $_"
        return $null
    }
}

# Function to get service dependencies
function Get-ServiceDependencyTree {
    param([string]$Name)
    
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Warning "Service '$Name' not found"
        return
    }
    
    Write-Host "`n=== Dependencies for $($service.DisplayName) ($Name) ===" -ForegroundColor Cyan
    
    # Services this service depends on
    if ($service.ServicesDependedOn.Count -gt 0) {
        Write-Host "`nThis service depends on:" -ForegroundColor Yellow
        foreach ($dep in $service.ServicesDependedOn) {
            Write-Host "  - $($dep.DisplayName) ($($dep.Name)) [$($dep.Status)]"
        }
    }
    else {
        Write-Host "`nThis service has no dependencies." -ForegroundColor Gray
    }
    
    # Services that depend on this service
    if ($service.DependentServices.Count -gt 0) {
        Write-Host "`nServices that depend on this service:" -ForegroundColor Yellow
        foreach ($dep in $service.DependentServices) {
            Write-Host "  - $($dep.DisplayName) ($($dep.Name)) [$($dep.Status)]"
        }
    }
    else {
        Write-Host "`nNo services depend on this service." -ForegroundColor Gray
    }
}

# Main execution logic
switch ($Action) {
    'List' {
        Write-Host "Retrieving services from $ComputerName..." -ForegroundColor Cyan
        
        # Get all services matching the pattern
        $services = Get-Service -Name $ServiceName -ComputerName $ComputerName | 
            Sort-Object -Property DisplayName
        
        # Get detailed information for each service
        $results = foreach ($svc in $services) {
            Get-ServiceDetails -Name $svc.Name -Computer $ComputerName
        }
        
        # Display results in table format
        $results | Format-Table -AutoSize Name, DisplayName, Status, StartType, Account
        
        # Export to CSV if requested
        if ($OutputCsv) {
            $results | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported $($results.Count) services to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'Start' {
        Write-Host "Starting service: $ServiceName on $ComputerName..." -ForegroundColor Cyan
        try {
            # Start the service and wait for it to reach Running status
            Start-Service -Name $ServiceName -ComputerName $ComputerName -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            $service = Get-Service -Name $ServiceName -ComputerName $ComputerName
            Write-Host "Service '$($service.DisplayName)' is now: $($service.Status)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to start service: $_"
        }
    }
    
    'Stop' {
        Write-Host "Stopping service: $ServiceName on $ComputerName..." -ForegroundColor Cyan
        try {
            # Check if service can be stopped
            $service = Get-Service -Name $ServiceName -ComputerName $ComputerName
            if (-not $service.CanStop) {
                Write-Warning "Service '$($service.DisplayName)' cannot be stopped (system critical)"
                return
            }
            
            # Stop the service and wait for it to stop
            Stop-Service -Name $ServiceName -ComputerName $ComputerName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            $service = Get-Service -Name $ServiceName -ComputerName $ComputerName
            Write-Host "Service '$($service.DisplayName)' is now: $($service.Status)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to stop service: $_"
        }
    }
    
    'Restart' {
        Write-Host "Restarting service: $ServiceName on $ComputerName..." -ForegroundColor Cyan
        try {
            # Restart the service (stop then start)
            Restart-Service -Name $ServiceName -ComputerName $ComputerName -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            
            $service = Get-Service -Name $ServiceName -ComputerName $ComputerName
            Write-Host "Service '$($service.DisplayName)' restarted successfully: $($service.Status)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to restart service: $_"
        }
    }
    
    'Enable' {
        Write-Host "Enabling service: $ServiceName..." -ForegroundColor Cyan
        try {
            # Set service to start automatically
            Set-Service -Name $ServiceName -StartupType Automatic -ErrorAction Stop
            Write-Host "Service '$ServiceName' set to Automatic startup" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to enable service: $_"
        }
    }
    
    'Disable' {
        Write-Host "Disabling service: $ServiceName..." -ForegroundColor Cyan
        try {
            # Set service to disabled
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction Stop
            Write-Host "Service '$ServiceName' set to Disabled" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to disable service: $_"
        }
    }
    
    'GetStatus' {
        # Get and display current service status
        $details = Get-ServiceDetails -Name $ServiceName -Computer $ComputerName
        if ($details) {
            Write-Host "`n=== Service Details ===" -ForegroundColor Cyan
            $details | Format-List
        }
    }
    
    'GetDependencies' {
        # Display service dependency tree
        Get-ServiceDependencyTree -Name $ServiceName
    }
}
