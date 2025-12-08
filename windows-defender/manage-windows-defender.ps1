<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Windows Defender management and monitoring utility.
.DESCRIPTION
    Manage Windows Defender: run scans, update definitions, manage exclusions, check threat history.
    Provides comprehensive control over Windows Defender Antivirus.
.PARAMETER Action
    Action to perform: Status, QuickScan, FullScan, CustomScan, UpdateSignatures, GetThreats, AddExclusion, RemoveExclusion, GetExclusions
.PARAMETER Path
    Path for custom scan or exclusion operations
.PARAMETER ExclusionType
    Type of exclusion: Path, Extension, Process (default: Path)
.PARAMETER OutputCsv
    Path to export results
.EXAMPLE
    .\manage-windows-defender.ps1 -Action Status
    Displays Windows Defender status and settings
.EXAMPLE
    .\manage-windows-defender.ps1 -Action QuickScan
    Runs a quick scan
.EXAMPLE
    .\manage-windows-defender.ps1 -Action AddExclusion -Path "C:\MyApp" -ExclusionType Path
    Adds path exclusion to Windows Defender
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Status', 'QuickScan', 'FullScan', 'CustomScan', 'UpdateSignatures', 'GetThreats', 'AddExclusion', 'RemoveExclusion', 'GetExclusions')]
    [string]$Action,
    
    [string]$Path,
    [ValidateSet('Path', 'Extension', 'Process')]
    [string]$ExclusionType = 'Path',
    [string]$OutputCsv = 'DefenderResults.csv'
)

#Requires -RunAsAdministrator

# Function to display Windows Defender status
function Get-DefenderStatus {
    Write-Host "`n=== Windows Defender Status ===" -ForegroundColor Cyan
    
    try {
        # Get Windows Defender preferences and status
        $prefs = Get-MpPreference
        $status = Get-MpComputerStatus
        
        Write-Host "`nProtection Status:" -ForegroundColor Yellow
        Write-Host "  Antivirus Enabled: $($status.AntivirusEnabled)"
        Write-Host "  Real-time Protection: $($status.RealTimeProtectionEnabled)"
        Write-Host "  Behavior Monitor: $($status.BehaviorMonitorEnabled)"
        Write-Host "  IO Protection: $($status.IoavProtectionEnabled)"
        Write-Host "  Network Protection: $($status.NISEnabled)"
        Write-Host "  Cloud Protection: $($prefs.MAPSReporting -ne 0)"
        Write-Host "  Tamper Protection: $($status.IsTamperProtected)"
        
        Write-Host "`nSignature Information:" -ForegroundColor Yellow
        Write-Host "  Antivirus Signature Version: $($status.AntivirusSignatureVersion)"
        Write-Host "  Antivirus Signature Age: $($status.AntivirusSignatureAge) days"
        Write-Host "  Antivirus Signature Last Updated: $($status.AntivirusSignatureLastUpdated)"
        Write-Host "  NIS Signature Version: $($status.NISSignatureVersion)"
        Write-Host "  NIS Signature Age: $($status.NISSignatureAge) days"
        
        Write-Host "`nScan Information:" -ForegroundColor Yellow
        Write-Host "  Last Quick Scan: $($status.QuickScanEndTime)"
        Write-Host "  Last Full Scan: $($status.FullScanEndTime)"
        Write-Host "  Days Since Last Quick Scan: $((Get-Date) - $status.QuickScanEndTime).Days"
        Write-Host "  Days Since Last Full Scan: $((Get-Date) - $status.FullScanEndTime).Days"
        
        Write-Host "`nThreat Detection:" -ForegroundColor Yellow
        Write-Host "  Computer State: $($status.ComputerState)"
        
        # Display scan settings
        Write-Host "`nScan Settings:" -ForegroundColor Yellow
        Write-Host "  Scan Archive Files: $($prefs.DisableArchiveScanning -eq $false)"
        Write-Host "  Scan Removable Drives: $($prefs.DisableRemovableDriveScanning -eq $false)"
        Write-Host "  Scan Network Files: $($prefs.DisableScanningNetworkFiles -eq $false)"
        Write-Host "  Scan Email: $($prefs.DisableEmailScanning -eq $false)"
        Write-Host "  Scan Scripts: $($prefs.DisableScriptScanning -eq $false)"
        
    }
    catch {
        Write-Error "Failed to retrieve Windows Defender status: $_"
    }
}

# Function to get threat history
function Get-ThreatHistory {
    Write-Host "Retrieving threat detection history..." -ForegroundColor Cyan
    
    try {
        # Get detected threats
        $threats = Get-MpThreat
        
        if ($threats) {
            Write-Host "`nFound $($threats.Count) threat(s) in history" -ForegroundColor Yellow
            
            $threatDetails = foreach ($threat in $threats) {
                [PSCustomObject]@{
                    ThreatName       = $threat.ThreatName
                    SeverityID       = $threat.SeverityID
                    InitialDetection = $threat.InitialDetectionTime
                    Resources        = $threat.Resources -join '; '
                    ProcessName      = $threat.ProcessName
                    IsActive         = $threat.IsActive
                }
            }
            
            $threatDetails | Format-Table -AutoSize
            return $threatDetails
        }
        else {
            Write-Host "`nNo threats detected in history" -ForegroundColor Green
            return $null
        }
    }
    catch {
        Write-Warning "Unable to retrieve threat history: $_"
    }
}

# Function to get exclusions
function Get-DefenderExclusions {
    Write-Host "Retrieving Windows Defender exclusions..." -ForegroundColor Cyan
    
    try {
        $prefs = Get-MpPreference
        
        Write-Host "`n=== Exclusions ===" -ForegroundColor Yellow
        
        Write-Host "`nPath Exclusions:" -ForegroundColor Cyan
        if ($prefs.ExclusionPath) {
            $prefs.ExclusionPath | ForEach-Object { Write-Host "  $_" }
        }
        else {
            Write-Host "  None" -ForegroundColor Gray
        }
        
        Write-Host "`nExtension Exclusions:" -ForegroundColor Cyan
        if ($prefs.ExclusionExtension) {
            $prefs.ExclusionExtension | ForEach-Object { Write-Host "  $_" }
        }
        else {
            Write-Host "  None" -ForegroundColor Gray
        }
        
        Write-Host "`nProcess Exclusions:" -ForegroundColor Cyan
        if ($prefs.ExclusionProcess) {
            $prefs.ExclusionProcess | ForEach-Object { Write-Host "  $_" }
        }
        else {
            Write-Host "  None" -ForegroundColor Gray
        }
        
        # Return structured data
        return [PSCustomObject]@{
            PathExclusions      = $prefs.ExclusionPath
            ExtensionExclusions = $prefs.ExclusionExtension
            ProcessExclusions   = $prefs.ExclusionProcess
        }
    }
    catch {
        Write-Error "Failed to retrieve exclusions: $_"
    }
}

# Main execution logic
switch ($Action) {
    'Status' {
        Get-DefenderStatus
    }
    
    'QuickScan' {
        Write-Host "Starting Windows Defender Quick Scan..." -ForegroundColor Cyan
        Write-Host "This may take several minutes..." -ForegroundColor Yellow
        
        try {
            # Start quick scan
            Start-MpScan -ScanType QuickScan
            Write-Host "`nQuick scan completed successfully" -ForegroundColor Green
            
            # Display scan results
            $status = Get-MpComputerStatus
            Write-Host "`nScan completed at: $($status.QuickScanEndTime)" -ForegroundColor Cyan
        }
        catch {
            Write-Error "Failed to run quick scan: $_"
        }
    }
    
    'FullScan' {
        Write-Host "Starting Windows Defender Full Scan..." -ForegroundColor Cyan
        Write-Host "This will take a considerable amount of time..." -ForegroundColor Yellow
        
        try {
            # Start full scan
            Start-MpScan -ScanType FullScan
            Write-Host "`nFull scan completed successfully" -ForegroundColor Green
            
            # Display scan results
            $status = Get-MpComputerStatus
            Write-Host "`nScan completed at: $($status.FullScanEndTime)" -ForegroundColor Cyan
        }
        catch {
            Write-Error "Failed to run full scan: $_"
        }
    }
    
    'CustomScan' {
        if (-not $Path) {
            Write-Error "Path parameter is required for CustomScan action"
            return
        }
        
        if (-not (Test-Path $Path)) {
            Write-Error "Path not found: $Path"
            return
        }
        
        Write-Host "Starting Windows Defender Custom Scan on: $Path" -ForegroundColor Cyan
        
        try {
            # Start custom scan on specified path
            Start-MpScan -ScanType CustomScan -ScanPath $Path
            Write-Host "`nCustom scan completed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to run custom scan: $_"
        }
    }
    
    'UpdateSignatures' {
        Write-Host "Updating Windows Defender signature definitions..." -ForegroundColor Cyan
        
        try {
            # Update antivirus signatures
            Update-MpSignature
            Write-Host "`nSignature definitions updated successfully" -ForegroundColor Green
            
            # Display updated signature info
            $status = Get-MpComputerStatus
            Write-Host "`nNew Signature Version: $($status.AntivirusSignatureVersion)" -ForegroundColor Cyan
            Write-Host "Last Updated: $($status.AntivirusSignatureLastUpdated)" -ForegroundColor Cyan
        }
        catch {
            Write-Error "Failed to update signatures: $_"
        }
    }
    
    'GetThreats' {
        $threats = Get-ThreatHistory
        
        if ($threats -and $OutputCsv) {
            $threats | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported threat history to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'AddExclusion' {
        if (-not $Path) {
            Write-Error "Path parameter is required for AddExclusion action"
            return
        }
        
        Write-Host "Adding exclusion to Windows Defender..." -ForegroundColor Cyan
        Write-Host "Type: $ExclusionType" -ForegroundColor Yellow
        Write-Host "Value: $Path" -ForegroundColor Yellow
        
        try {
            # Add exclusion based on type
            switch ($ExclusionType) {
                'Path' {
                    Add-MpPreference -ExclusionPath $Path
                }
                'Extension' {
                    Add-MpPreference -ExclusionExtension $Path
                }
                'Process' {
                    Add-MpPreference -ExclusionProcess $Path
                }
            }
            
            Write-Host "`nExclusion added successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to add exclusion: $_"
        }
    }
    
    'RemoveExclusion' {
        if (-not $Path) {
            Write-Error "Path parameter is required for RemoveExclusion action"
            return
        }
        
        Write-Host "Removing exclusion from Windows Defender..." -ForegroundColor Cyan
        Write-Host "Type: $ExclusionType" -ForegroundColor Yellow
        Write-Host "Value: $Path" -ForegroundColor Yellow
        
        try {
            # Remove exclusion based on type
            switch ($ExclusionType) {
                'Path' {
                    Remove-MpPreference -ExclusionPath $Path
                }
                'Extension' {
                    Remove-MpPreference -ExclusionExtension $Path
                }
                'Process' {
                    Remove-MpPreference -ExclusionProcess $Path
                }
            }
            
            Write-Host "`nExclusion removed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to remove exclusion: $_"
        }
    }
    
    'GetExclusions' {
        $exclusions = Get-DefenderExclusions
        
        if ($OutputCsv -and $exclusions) {
            # Export exclusions to CSV
            $exportData = @()
            
            if ($exclusions.PathExclusions) {
                $exclusions.PathExclusions | ForEach-Object {
                    $exportData += [PSCustomObject]@{ Type = 'Path'; Value = $_ }
                }
            }
            
            if ($exclusions.ExtensionExclusions) {
                $exclusions.ExtensionExclusions | ForEach-Object {
                    $exportData += [PSCustomObject]@{ Type = 'Extension'; Value = $_ }
                }
            }
            
            if ($exclusions.ProcessExclusions) {
                $exclusions.ProcessExclusions | ForEach-Object {
                    $exportData += [PSCustomObject]@{ Type = 'Process'; Value = $_ }
                }
            }
            
            if ($exportData) {
                $exportData | Export-Csv -Path $OutputCsv -NoTypeInformation
                Write-Host "`nExported exclusions to $OutputCsv" -ForegroundColor Green
            }
        }
    }
}
