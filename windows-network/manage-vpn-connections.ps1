<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Comprehensive VPN Connection Manager for Windows with automation and monitoring.
.DESCRIPTION
    Manages Windows VPN connections including creation, deletion, connection, disconnection,
    status monitoring, and automated connection testing. Supports multiple VPN types including
    PPTP, L2TP/IPSec, SSTP, and IKEv2.
.PARAMETER Action
    Action to perform: List, Create, Connect, Disconnect, Remove, Status, Monitor, Test
.PARAMETER ConnectionName
    Name of the VPN connection
.PARAMETER ServerAddress
    VPN server address (hostname or IP)
.PARAMETER VpnType
    Type of VPN: PPTP, L2TP, SSTP, IKEv2 (default: IKEv2)
.PARAMETER AuthMethod
    Authentication method: Eap, MSChapv2, Pap (default: Eap)
.PARAMETER SplitTunneling
    Enable split tunneling (routes only specific traffic through VPN)
.PARAMETER PreSharedKey
    Pre-shared key for L2TP/IPSec connections
.PARAMETER MonitorInterval
    Monitoring interval in seconds for Monitor action (default: 30)
.PARAMETER AutoReconnect
    Automatically reconnect if connection drops during monitoring
.PARAMETER OutputCsv
    Path to export VPN connection list (default: VpnConnections.csv)
.EXAMPLE
    .\manage-vpn-connections.ps1 -Action List -OutputCsv "vpn-list.csv"
    Lists all VPN connections and exports to CSV
.EXAMPLE
    .\manage-vpn-connections.ps1 -Action Create -ConnectionName "CorpVPN" -ServerAddress "vpn.company.com" -VpnType IKEv2
    Creates a new IKEv2 VPN connection
.EXAMPLE
    .\manage-vpn-connections.ps1 -Action Connect -ConnectionName "CorpVPN"
    Connects to the specified VPN
.EXAMPLE
    .\manage-vpn-connections.ps1 -Action Monitor -ConnectionName "CorpVPN" -MonitorInterval 60 -AutoReconnect
    Monitors VPN connection and auto-reconnects if dropped
.EXAMPLE
    .\manage-vpn-connections.ps1 -Action Test -ConnectionName "CorpVPN"
    Tests VPN connection with connectivity checks
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('List', 'Create', 'Connect', 'Disconnect', 'Remove', 'Status', 'Monitor', 'Test')]
    [string]$Action,
    
    [string]$ConnectionName = '',
    [string]$ServerAddress = '',
    [ValidateSet('PPTP', 'L2TP', 'SSTP', 'IKEv2')]
    [string]$VpnType = 'IKEv2',
    [ValidateSet('Eap', 'MSChapv2', 'Pap')]
    [string]$AuthMethod = 'Eap',
    [switch]$SplitTunneling,
    [string]$PreSharedKey = '',
    [int]$MonitorInterval = 30,
    [switch]$AutoReconnect,
    [string]$OutputCsv = 'VpnConnections.csv'
)

# Validate PowerShell Version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "This script is optimized for PowerShell 7+. Some features may not work on earlier versions."
}

#region Helper Functions

<#
.SYNOPSIS
    Gets detailed information about VPN connections
#>
function Get-VpnConnectionDetails {
    param([string]$Name = '*')
    
    try {
        $connections = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction SilentlyContinue
        
        if (-not $connections) {
            return @()
        }
        
        $results = @()
        foreach ($conn in $connections) {
            $results += [PSCustomObject]@{
                Name = $conn.Name
                ServerAddress = $conn.ServerAddress
                ConnectionStatus = $conn.ConnectionStatus
                TunnelType = $conn.TunnelType
                AuthenticationMethod = $conn.AuthenticationMethod
                SplitTunneling = $conn.SplitTunneling
                RememberCredential = $conn.RememberCredential
                Guid = $conn.Guid
            }
        }
        
        return $results
    }
    catch {
        Write-Warning "Failed to retrieve VPN connections: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Creates a new VPN connection
#>
function New-VpnConnectionProfile {
    param(
        [string]$Name,
        [string]$Server,
        [string]$Type,
        [string]$Auth,
        [bool]$Split,
        [string]$PresharedKey
    )
    
    try {
        Write-Host "Creating VPN connection '$Name'..." -ForegroundColor Yellow
        
        $params = @{
            Name = $Name
            ServerAddress = $Server
            TunnelType = $Type
            AuthenticationMethod = $Auth
            RememberCredential = $true
            AllUserConnection = $true
            Force = $true
        }
        
        if ($Split) {
            $params['SplitTunneling'] = $true
        }
        
        if ($Type -eq 'L2TP' -and -not [string]::IsNullOrEmpty($PresharedKey)) {
            $params['L2tpPsk'] = $PresharedKey
        }
        
        Add-VpnConnection @params -ErrorAction Stop
        
        Write-Host "✓ VPN connection '$Name' created successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to create VPN connection: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Connects to a VPN
#>
function Connect-VpnProfile {
    param([string]$Name)
    
    try {
        Write-Host "Connecting to VPN '$Name'..." -ForegroundColor Yellow
        
        $conn = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction Stop
        
        if ($conn.ConnectionStatus -eq 'Connected') {
            Write-Host "✓ Already connected to '$Name'" -ForegroundColor Green
            return $true
        }
        
        # Use native PowerShell cmdlet for better error handling
        try {
            Connect-VpnConnection -Name $Name -AllUserConnection -ErrorAction Stop
            Start-Sleep -Seconds 3
            
            $conn = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction Stop
            
            if ($conn.ConnectionStatus -eq 'Connected') {
                Write-Host "✓ Successfully connected to '$Name'" -ForegroundColor Green
                return $true
            }
            else {
                Write-Host "✗ Failed to connect to '$Name'" -ForegroundColor Red
                return $false
            }
        }
        catch {
            # Fallback to rasdial if Connect-VpnConnection fails (requires credentials)
            Write-Warning "Connect-VpnConnection failed, credentials may be required. Use rasdial manually with credentials."
            Write-Host "✗ Failed to connect to '$Name': $_" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Connection failed: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Disconnects from a VPN
#>
function Disconnect-VpnProfile {
    param([string]$Name)
    
    try {
        Write-Host "Disconnecting from VPN '$Name'..." -ForegroundColor Yellow
        
        $conn = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction Stop
        
        if ($conn.ConnectionStatus -ne 'Connected') {
            Write-Host "✓ VPN '$Name' is not connected" -ForegroundColor Green
            return $true
        }
        
        # Use native PowerShell cmdlet for better error handling
        Disconnect-VpnConnection -Name $Name -AllUserConnection -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        
        $conn = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction Stop
        
        if ($conn.ConnectionStatus -ne 'Connected') {
            Write-Host "✓ Successfully disconnected from '$Name'" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "✗ Failed to disconnect from '$Name'" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Disconnection failed: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Removes a VPN connection
#>
function Remove-VpnProfile {
    param([string]$Name)
    
    try {
        Write-Host "Removing VPN connection '$Name'..." -ForegroundColor Yellow
        
        # Disconnect first if connected
        $conn = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction Stop
        if ($conn.ConnectionStatus -eq 'Connected') {
            Disconnect-VpnProfile -Name $Name
        }
        
        Remove-VpnConnection -Name $Name -AllUserConnection -Force -ErrorAction Stop
        
        Write-Host "✓ VPN connection '$Name' removed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ Failed to remove VPN connection: $_" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    Tests VPN connection with connectivity checks
#>
function Test-VpnConnectivity {
    param([string]$Name)
    
    Write-Host "`n=== Testing VPN Connection: $Name ===" -ForegroundColor Cyan
    
    try {
        $conn = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction Stop
        
        Write-Host "`nVPN Configuration:" -ForegroundColor Yellow
        Write-Host "  Server: $($conn.ServerAddress)"
        Write-Host "  Type: $($conn.TunnelType)"
        Write-Host "  Status: $($conn.ConnectionStatus)"
        
        if ($conn.ConnectionStatus -ne 'Connected') {
            Write-Host "`n✗ VPN is not connected. Connect first to perform connectivity tests." -ForegroundColor Red
            return
        }
        
        Write-Host "`nConnectivity Tests:" -ForegroundColor Yellow
        
        # Get VPN adapter details
        $adapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*VPN*" -or $_.Name -like "*$Name*" } | Select-Object -First 1
        
        if ($adapter) {
            Write-Host "  ✓ VPN Adapter: $($adapter.Name) ($($adapter.Status))" -ForegroundColor Green
            
            # Get IP configuration
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue | Where-Object { $_.AddressFamily -eq 'IPv4' }
            if ($ipConfig) {
                Write-Host "  ✓ VPN IP Address: $($ipConfig.IPAddress)" -ForegroundColor Green
            }
        }
        
        # Test DNS resolution through VPN
        Write-Host "`n  Testing DNS resolution..."
        $dnsTest = Test-Connection -ComputerName "google.com" -Count 2 -ErrorAction SilentlyContinue
        if ($dnsTest) {
            Write-Host "  ✓ DNS resolution working" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ DNS resolution failed" -ForegroundColor Red
        }
        
        # Test internet connectivity
        Write-Host "  Testing internet connectivity..."
        $pingTest = Test-Connection -ComputerName "8.8.8.8" -Count 2 -ErrorAction SilentlyContinue
        if ($pingTest) {
            $avgLatency = ($pingTest | Measure-Object -Property ResponseTime -Average).Average
            Write-Host "  ✓ Internet connectivity OK (avg latency: $([math]::Round($avgLatency, 2)) ms)" -ForegroundColor Green
        }
        else {
            Write-Host "  ✗ Internet connectivity failed" -ForegroundColor Red
        }
        
        Write-Host "`n✓ VPN connectivity test complete" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ VPN test failed: $_" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Monitors VPN connection status
#>
function Start-VpnMonitoring {
    param(
        [string]$Name,
        [int]$Interval,
        [bool]$AutoReconnect
    )
    
    Write-Host "`n=== Starting VPN Monitoring: $Name ===" -ForegroundColor Cyan
    Write-Host "Interval: $Interval seconds" -ForegroundColor Gray
    Write-Host "Auto-Reconnect: $AutoReconnect" -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop monitoring...`n" -ForegroundColor Gray
    
    $disconnectCount = 0
    $reconnectCount = 0
    
    try {
        while ($true) {
            $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            $conn = Get-VpnConnection -Name $Name -AllUserConnection -ErrorAction SilentlyContinue
            
            if (-not $conn) {
                Write-Host "[$timestamp] ✗ VPN connection '$Name' not found" -ForegroundColor Red
                break
            }
            
            if ($conn.ConnectionStatus -eq 'Connected') {
                Write-Host "[$timestamp] ✓ VPN '$Name' is connected" -ForegroundColor Green
            }
            else {
                $disconnectCount++
                Write-Host "[$timestamp] ✗ VPN '$Name' is disconnected (Count: $disconnectCount)" -ForegroundColor Red
                
                if ($AutoReconnect) {
                    Write-Host "[$timestamp] → Attempting to reconnect..." -ForegroundColor Yellow
                    $success = Connect-VpnProfile -Name $Name
                    if ($success) {
                        $reconnectCount++
                        Write-Host "[$timestamp] ✓ Reconnected successfully (Count: $reconnectCount)" -ForegroundColor Green
                    }
                }
            }
            
            Start-Sleep -Seconds $Interval
        }
    }
    catch {
        Write-Host "`n✗ Monitoring interrupted: $_" -ForegroundColor Red
    }
    
    Write-Host "`nMonitoring Summary:" -ForegroundColor Yellow
    Write-Host "  Disconnects: $disconnectCount" -ForegroundColor Gray
    Write-Host "  Reconnects: $reconnectCount" -ForegroundColor Gray
}

#endregion

# Main Execution
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "              Graph Technologies - VPN Connection Manager                      " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    'List' {
        Write-Host "Listing all VPN connections...`n" -ForegroundColor Yellow
        $connections = Get-VpnConnectionDetails
        
        if ($connections.Count -eq 0) {
            Write-Host "No VPN connections found." -ForegroundColor Gray
        }
        else {
            $connections | Format-Table -AutoSize
            
            Write-Host "`nExporting to $OutputCsv..." -ForegroundColor Yellow
            $connections | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "✓ Exported $($connections.Count) VPN connection(s) to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'Create' {
        if ([string]::IsNullOrEmpty($ConnectionName) -or [string]::IsNullOrEmpty($ServerAddress)) {
            Write-Host "✗ ConnectionName and ServerAddress are required for Create action" -ForegroundColor Red
            exit 1
        }
        
        $result = New-VpnConnectionProfile -Name $ConnectionName -Server $ServerAddress -Type $VpnType -Auth $AuthMethod -Split $SplitTunneling -PresharedKey $PreSharedKey
        
        if ($result) {
            $connections = Get-VpnConnectionDetails -Name $ConnectionName
            $connections | Format-Table -AutoSize
        }
    }
    
    'Connect' {
        if ([string]::IsNullOrEmpty($ConnectionName)) {
            Write-Host "✗ ConnectionName is required for Connect action" -ForegroundColor Red
            exit 1
        }
        
        Connect-VpnProfile -Name $ConnectionName
    }
    
    'Disconnect' {
        if ([string]::IsNullOrEmpty($ConnectionName)) {
            Write-Host "✗ ConnectionName is required for Disconnect action" -ForegroundColor Red
            exit 1
        }
        
        Disconnect-VpnProfile -Name $ConnectionName
    }
    
    'Remove' {
        if ([string]::IsNullOrEmpty($ConnectionName)) {
            Write-Host "✗ ConnectionName is required for Remove action" -ForegroundColor Red
            exit 1
        }
        
        Remove-VpnProfile -Name $ConnectionName
    }
    
    'Status' {
        if ([string]::IsNullOrEmpty($ConnectionName)) {
            Write-Host "Retrieving status for all VPN connections...`n" -ForegroundColor Yellow
            $connections = Get-VpnConnectionDetails
        }
        else {
            Write-Host "Retrieving status for VPN '$ConnectionName'...`n" -ForegroundColor Yellow
            $connections = Get-VpnConnectionDetails -Name $ConnectionName
        }
        
        if ($connections.Count -eq 0) {
            Write-Host "No VPN connections found." -ForegroundColor Gray
        }
        else {
            foreach ($conn in $connections) {
                $statusColor = if ($conn.ConnectionStatus -eq 'Connected') { 'Green' } else { 'Yellow' }
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
                Write-Host "Name: $($conn.Name)" -ForegroundColor White
                Write-Host "Server: $($conn.ServerAddress)" -ForegroundColor Gray
                Write-Host "Status: " -NoNewline -ForegroundColor Gray
                Write-Host "$($conn.ConnectionStatus)" -ForegroundColor $statusColor
                Write-Host "Type: $($conn.TunnelType)" -ForegroundColor Gray
                Write-Host "Split Tunneling: $($conn.SplitTunneling)" -ForegroundColor Gray
                Write-Host ""
            }
        }
    }
    
    'Monitor' {
        if ([string]::IsNullOrEmpty($ConnectionName)) {
            Write-Host "✗ ConnectionName is required for Monitor action" -ForegroundColor Red
            exit 1
        }
        
        Start-VpnMonitoring -Name $ConnectionName -Interval $MonitorInterval -AutoReconnect $AutoReconnect
    }
    
    'Test' {
        if ([string]::IsNullOrEmpty($ConnectionName)) {
            Write-Host "✗ ConnectionName is required for Test action" -ForegroundColor Red
            exit 1
        }
        
        Test-VpnConnectivity -Name $ConnectionName
    }
}

Write-Host ""
Write-Host "Graph Technologies · https://graphtechnologies.xyz/" -ForegroundColor Cyan
