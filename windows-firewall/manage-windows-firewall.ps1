<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Comprehensive Windows Firewall management utility.
.DESCRIPTION
    Manage Windows Firewall rules: create, delete, enable, disable, list, and audit.
    Supports inbound/outbound rules, port-based and application-based rules.
.PARAMETER Action
    Action to perform: List, Create, Delete, Enable, Disable, Audit, BlockPort, AllowPort, AllowApp
.PARAMETER RuleName
    Name of the firewall rule
.PARAMETER Port
    Port number for port-based rules
.PARAMETER Protocol
    Protocol: TCP or UDP (default: TCP)
.PARAMETER Direction
    Direction: Inbound or Outbound (default: Inbound)
.PARAMETER AppPath
    Full path to application for application-based rules
.PARAMETER Profile
    Firewall profile: Domain, Private, Public, or Any (default: Any)
.PARAMETER OutputCsv
    Path to export rule list
.EXAMPLE
    .\manage-windows-firewall.ps1 -Action AllowPort -RuleName "Allow SSH" -Port 22 -Protocol TCP -Direction Inbound
    Creates inbound rule to allow SSH on port 22
.EXAMPLE
    .\manage-windows-firewall.ps1 -Action AllowApp -RuleName "MyApp" -AppPath "C:\Program Files\MyApp\app.exe"
    Creates rule to allow application through firewall
.EXAMPLE
    .\manage-windows-firewall.ps1 -Action Audit -OutputCsv "firewall-rules.csv"
    Audits all firewall rules and exports to CSV
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('List', 'Create', 'Delete', 'Enable', 'Disable', 'Audit', 'BlockPort', 'AllowPort', 'AllowApp', 'GetStatus')]
    [string]$Action,
    
    [string]$RuleName,
    [int]$Port,
    [ValidateSet('TCP', 'UDP')]
    [string]$Protocol = 'TCP',
    [ValidateSet('Inbound', 'Outbound')]
    [string]$Direction = 'Inbound',
    [string]$AppPath,
    [ValidateSet('Domain', 'Private', 'Public', 'Any')]
    [string]$Profile = 'Any',
    [string]$OutputCsv = 'FirewallRules.csv'
)

#Requires -RunAsAdministrator

# Function to get firewall status for all profiles
function Get-FirewallStatus {
    Write-Host "`n=== Windows Firewall Status ===" -ForegroundColor Cyan
    
    # Get firewall profiles
    $profiles = Get-NetFirewallProfile
    
    foreach ($prof in $profiles) {
        Write-Host "`n$($prof.Name) Profile:" -ForegroundColor Yellow
        Write-Host "  Enabled: $($prof.Enabled)"
        Write-Host "  Default Inbound Action: $($prof.DefaultInboundAction)"
        Write-Host "  Default Outbound Action: $($prof.DefaultOutboundAction)"
        Write-Host "  Allow Inbound Rules: $($prof.AllowInboundRules)"
        Write-Host "  Allow Local Firewall Rules: $($prof.AllowLocalFirewallRules)"
        Write-Host "  Allow Local IPsec Rules: $($prof.AllowLocalIPsecRules)"
        Write-Host "  Notify on Listen: $($prof.NotifyOnListen)"
        Write-Host "  Log File Name: $($prof.LogFileName)"
    }
}

# Function to audit firewall rules
function Get-FirewallAudit {
    Write-Host "Auditing Windows Firewall rules..." -ForegroundColor Cyan
    
    # Get all firewall rules with details
    $rules = Get-NetFirewallRule | Where-Object { $_.Enabled -eq $true } | 
        Select-Object DisplayName, Direction, Action, Enabled, Profile, 
                     @{N='Protocol';E={(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_).Protocol}},
                     @{N='LocalPort';E={(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_).LocalPort}},
                     @{N='RemotePort';E={(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_).RemotePort}},
                     @{N='Program';E={(Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $_).Program}}
    
    # Display summary statistics
    Write-Host "`n=== Firewall Rules Summary ===" -ForegroundColor Yellow
    Write-Host "Total Enabled Rules: $($rules.Count)"
    Write-Host "Inbound Rules: $(($rules | Where-Object Direction -eq 'Inbound').Count)"
    Write-Host "Outbound Rules: $(($rules | Where-Object Direction -eq 'Outbound').Count)"
    Write-Host "Allow Rules: $(($rules | Where-Object Action -eq 'Allow').Count)"
    Write-Host "Block Rules: $(($rules | Where-Object Action -eq 'Block').Count)"
    
    return $rules
}

# Main execution logic
switch ($Action) {
    'GetStatus' {
        Get-FirewallStatus
    }
    
    'List' {
        Write-Host "Retrieving firewall rules..." -ForegroundColor Cyan
        
        # Get all firewall rules
        $rules = Get-NetFirewallRule | 
            Select-Object DisplayName, Enabled, Direction, Action, Profile, Description |
            Sort-Object DisplayName
        
        $rules | Format-Table -AutoSize
        
        if ($OutputCsv) {
            $rules | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported $($rules.Count) rules to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'AllowPort' {
        if (-not $RuleName -or -not $Port) {
            Write-Error "RuleName and Port parameters are required for AllowPort action"
            return
        }
        
        Write-Host "Creating firewall rule to allow $Direction traffic on port $Port ($Protocol)..." -ForegroundColor Cyan
        
        try {
            # Create new firewall rule to allow port
            New-NetFirewallRule -DisplayName $RuleName -Direction $Direction -Protocol $Protocol `
                -LocalPort $Port -Action Allow -Profile $Profile -ErrorAction Stop | Out-Null
            
            Write-Host "Successfully created rule: $RuleName" -ForegroundColor Green
            Write-Host "  Direction: $Direction"
            Write-Host "  Protocol: $Protocol"
            Write-Host "  Port: $Port"
            Write-Host "  Profile: $Profile"
        }
        catch {
            Write-Error "Failed to create firewall rule: $_"
        }
    }
    
    'BlockPort' {
        if (-not $RuleName -or -not $Port) {
            Write-Error "RuleName and Port parameters are required for BlockPort action"
            return
        }
        
        Write-Host "Creating firewall rule to block $Direction traffic on port $Port ($Protocol)..." -ForegroundColor Cyan
        
        try {
            # Create new firewall rule to block port
            New-NetFirewallRule -DisplayName $RuleName -Direction $Direction -Protocol $Protocol `
                -LocalPort $Port -Action Block -Profile $Profile -ErrorAction Stop | Out-Null
            
            Write-Host "Successfully created rule: $RuleName" -ForegroundColor Green
            Write-Host "  Direction: $Direction"
            Write-Host "  Protocol: $Protocol"
            Write-Host "  Port: $Port"
            Write-Host "  Action: Block"
            Write-Host "  Profile: $Profile"
        }
        catch {
            Write-Error "Failed to create firewall rule: $_"
        }
    }
    
    'AllowApp' {
        if (-not $RuleName -or -not $AppPath) {
            Write-Error "RuleName and AppPath parameters are required for AllowApp action"
            return
        }
        
        # Validate application path
        if (-not (Test-Path $AppPath)) {
            Write-Error "Application not found: $AppPath"
            return
        }
        
        Write-Host "Creating firewall rule to allow application: $AppPath..." -ForegroundColor Cyan
        
        try {
            # Create new firewall rule for application
            New-NetFirewallRule -DisplayName $RuleName -Direction $Direction -Program $AppPath `
                -Action Allow -Profile $Profile -ErrorAction Stop | Out-Null
            
            Write-Host "Successfully created rule: $RuleName" -ForegroundColor Green
            Write-Host "  Application: $AppPath"
            Write-Host "  Direction: $Direction"
            Write-Host "  Profile: $Profile"
        }
        catch {
            Write-Error "Failed to create firewall rule: $_"
        }
    }
    
    'Delete' {
        if (-not $RuleName) {
            Write-Error "RuleName parameter is required for Delete action"
            return
        }
        
        Write-Host "Deleting firewall rule: $RuleName..." -ForegroundColor Cyan
        
        try {
            # Remove the firewall rule
            Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction Stop
            Write-Host "Successfully deleted rule: $RuleName" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to delete firewall rule: $_"
        }
    }
    
    'Enable' {
        if (-not $RuleName) {
            Write-Error "RuleName parameter is required for Enable action"
            return
        }
        
        Write-Host "Enabling firewall rule: $RuleName..." -ForegroundColor Cyan
        
        try {
            # Enable the firewall rule
            Enable-NetFirewallRule -DisplayName $RuleName -ErrorAction Stop
            Write-Host "Successfully enabled rule: $RuleName" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to enable firewall rule: $_"
        }
    }
    
    'Disable' {
        if (-not $RuleName) {
            Write-Error "RuleName parameter is required for Disable action"
            return
        }
        
        Write-Host "Disabling firewall rule: $RuleName..." -ForegroundColor Cyan
        
        try {
            # Disable the firewall rule
            Disable-NetFirewallRule -DisplayName $RuleName -ErrorAction Stop
            Write-Host "Successfully disabled rule: $RuleName" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to disable firewall rule: $_"
        }
    }
    
    'Audit' {
        # Perform comprehensive audit
        $auditResults = Get-FirewallAudit
        
        if ($OutputCsv) {
            $auditResults | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported audit results to $OutputCsv" -ForegroundColor Green
        }
        
        # Display some audit results
        Write-Host "`nSample of enabled rules:" -ForegroundColor Cyan
        $auditResults | Select-Object -First 20 | Format-Table -AutoSize DisplayName, Direction, Action, Protocol, LocalPort
    }
}
