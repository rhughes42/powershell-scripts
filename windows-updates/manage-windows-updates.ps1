<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Windows Update management and monitoring utility.
.DESCRIPTION
    Check for, download, install, and manage Windows Updates using PowerShell.
    Provides detailed reporting and control over the Windows Update process.
.PARAMETER Action
    Action to perform: Check, List, Install, Download, GetHistory, GetSettings
.PARAMETER AutoReboot
    Automatically reboot if required after installing updates (default: false)
.PARAMETER UpdateType
    Type of updates to install: All, Security, Critical, Optional (default: All)
.PARAMETER OutputCsv
    Path to export update list
.EXAMPLE
    .\manage-windows-updates.ps1 -Action Check
    Checks for available Windows Updates
.EXAMPLE
    .\manage-windows-updates.ps1 -Action Install -UpdateType Security -AutoReboot $false
    Installs security updates without automatic reboot
.EXAMPLE
    .\manage-windows-updates.ps1 -Action GetHistory -OutputCsv "update-history.csv"
    Exports Windows Update history to CSV
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Check', 'List', 'Install', 'Download', 'GetHistory', 'GetSettings')]
    [string]$Action,
    
    [bool]$AutoReboot = $false,
    [ValidateSet('All', 'Security', 'Critical', 'Optional')]
    [string]$UpdateType = 'All',
    [string]$OutputCsv = 'WindowsUpdates.csv'
)

#Requires -RunAsAdministrator

# Function to check if PSWindowsUpdate module is installed
function Test-WindowsUpdateModule {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "PSWindowsUpdate module not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
            Write-Host "PSWindowsUpdate module installed successfully" -ForegroundColor Green
            Import-Module PSWindowsUpdate
            return $true
        }
        catch {
            Write-Error "Failed to install PSWindowsUpdate module: $_"
            Write-Host "Please install manually: Install-Module -Name PSWindowsUpdate" -ForegroundColor Yellow
            return $false
        }
    }
    else {
        Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
        return $true
    }
}

# Function to get Windows Update settings
function Get-WindowsUpdateSettings {
    Write-Host "`n=== Windows Update Settings ===" -ForegroundColor Cyan
    
    try {
        # Get Windows Update service status
        $wuService = Get-Service -Name wuauserv
        Write-Host "`nWindows Update Service:" -ForegroundColor Yellow
        Write-Host "  Status: $($wuService.Status)"
        Write-Host "  Start Type: $($wuService.StartType)"
        
        # Get automatic update settings from registry
        $auSettings = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue
        if ($auSettings) {
            Write-Host "`nAutomatic Update Configuration:" -ForegroundColor Yellow
            Write-Host "  Auto Update Option: $($auSettings.AUOptions)"
            Write-Host "  Scheduled Install Day: $($auSettings.ScheduledInstallDay)"
            Write-Host "  Scheduled Install Time: $($auSettings.ScheduledInstallTime)"
        }
        
        # Get last update check time
        $updateSearcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
        Write-Host "`nLast Update Check:" -ForegroundColor Yellow
        Write-Host "  Last Search Success Date: $($updateSearcher.GetTotalHistoryCount())"
        
    }
    catch {
        Write-Warning "Unable to retrieve all Windows Update settings: $_"
    }
}

# Function to get detailed update information
function Get-UpdateDetails {
    param($Updates)
    
    $details = foreach ($update in $Updates) {
        [PSCustomObject]@{
            Title            = $update.Title
            KB               = if ($update.KBArticleIDs) { "KB$($update.KBArticleIDs)" } else { 'N/A' }
            Size             = [math]::Round($update.MaxDownloadSize / 1MB, 2)
            IsDownloaded     = $update.IsDownloaded
            IsMandatory      = $update.IsMandatory
            IsInstalled      = $update.IsInstalled
            RebootRequired   = $update.RebootRequired
            Categories       = ($update.Categories | Select-Object -ExpandProperty Name) -join ', '
            Description      = $update.Description
            SupportUrl       = $update.SupportUrl
        }
    }
    return $details
}

# Main execution logic
switch ($Action) {
    'Check' {
        Write-Host "Checking for available Windows Updates..." -ForegroundColor Cyan
        
        try {
            # Create Windows Update session and searcher
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            
            Write-Host "Searching for updates (this may take a few minutes)..." -ForegroundColor Yellow
            
            # Search for updates
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            
            if ($searchResult.Updates.Count -eq 0) {
                Write-Host "`nNo updates available. System is up to date." -ForegroundColor Green
            }
            else {
                Write-Host "`nFound $($searchResult.Updates.Count) available update(s)" -ForegroundColor Yellow
                
                # Categorize updates
                $critical = $searchResult.Updates | Where-Object { $_.MsrcSeverity -eq 'Critical' }
                $important = $searchResult.Updates | Where-Object { $_.MsrcSeverity -eq 'Important' }
                $optional = $searchResult.Updates | Where-Object { -not $_.IsMandatory }
                
                Write-Host "`nUpdate Summary:" -ForegroundColor Cyan
                Write-Host "  Critical: $($critical.Count)"
                Write-Host "  Important: $($important.Count)"
                Write-Host "  Optional: $($optional.Count)"
                
                # Display update details
                $details = Get-UpdateDetails -Updates $searchResult.Updates
                $details | Format-Table -AutoSize Title, KB, Size, Categories
            }
        }
        catch {
            Write-Error "Failed to check for updates: $_"
        }
    }
    
    'List' {
        if (-not (Test-WindowsUpdateModule)) { return }
        
        Write-Host "Retrieving list of available updates..." -ForegroundColor Cyan
        
        try {
            # Get list of available updates using PSWindowsUpdate module
            $updates = Get-WindowsUpdate -MicrosoftUpdate
            
            if ($updates) {
                Write-Host "`nFound $($updates.Count) available update(s)" -ForegroundColor Yellow
                $updates | Format-Table -AutoSize KB, Title, Size
                
                if ($OutputCsv) {
                    $updates | Export-Csv -Path $OutputCsv -NoTypeInformation
                    Write-Host "`nExported to $OutputCsv" -ForegroundColor Green
                }
            }
            else {
                Write-Host "`nNo updates available" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Failed to list updates: $_"
        }
    }
    
    'Download' {
        Write-Host "Downloading available Windows Updates..." -ForegroundColor Cyan
        
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            
            if ($searchResult.Updates.Count -eq 0) {
                Write-Host "No updates to download" -ForegroundColor Green
                return
            }
            
            # Create update collection
            $updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($update in $searchResult.Updates) {
                if (-not $update.IsDownloaded) {
                    $updatesToDownload.Add($update) | Out-Null
                }
            }
            
            if ($updatesToDownload.Count -eq 0) {
                Write-Host "All updates are already downloaded" -ForegroundColor Green
                return
            }
            
            Write-Host "Downloading $($updatesToDownload.Count) update(s)..." -ForegroundColor Yellow
            
            # Download updates
            $downloader = $updateSession.CreateUpdateDownloader()
            $downloader.Updates = $updatesToDownload
            $downloadResult = $downloader.Download()
            
            Write-Host "`nDownload completed. Result code: $($downloadResult.ResultCode)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to download updates: $_"
        }
    }
    
    'Install' {
        if (-not (Test-WindowsUpdateModule)) { return }
        
        Write-Host "Installing Windows Updates..." -ForegroundColor Cyan
        Write-Host "Update Type: $UpdateType" -ForegroundColor Yellow
        Write-Host "Auto Reboot: $AutoReboot" -ForegroundColor Yellow
        
        try {
            # Build parameters for Install-WindowsUpdate
            $params = @{
                MicrosoftUpdate = $true
                AcceptAll       = $true
                AutoReboot      = $AutoReboot
                Verbose         = $true
            }
            
            # Filter by update type if specified
            if ($UpdateType -ne 'All') {
                $params['Criteria'] = switch ($UpdateType) {
                    'Security' { "IsInstalled=0 and Type='Software' and (MsrcSeverity='Critical' or MsrcSeverity='Important')" }
                    'Critical' { "IsInstalled=0 and Type='Software' and MsrcSeverity='Critical'" }
                    'Optional' { "IsInstalled=0 and Type='Software' and IsMandatory=0" }
                }
            }
            
            # Install updates
            Write-Host "`nStarting installation..." -ForegroundColor Yellow
            $installResult = Install-WindowsUpdate @params
            
            Write-Host "`n=== Installation Summary ===" -ForegroundColor Green
            $installResult | Format-Table -AutoSize KB, Title, Result
            
            # Check if reboot is required
            if ((Get-WURebootStatus -Silent)) {
                Write-Host "`n[WARNING] System reboot is required to complete installation" -ForegroundColor Red
                if (-not $AutoReboot) {
                    Write-Host "Please reboot your system at your earliest convenience" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Error "Failed to install updates: $_"
        }
    }
    
    'GetHistory' {
        Write-Host "Retrieving Windows Update history..." -ForegroundColor Cyan
        
        try {
            # Query Windows Update history
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $historyCount = $updateSearcher.GetTotalHistoryCount()
            
            if ($historyCount -eq 0) {
                Write-Host "No update history found" -ForegroundColor Yellow
                return
            }
            
            Write-Host "Found $historyCount update history entries" -ForegroundColor Yellow
            
            # Get recent update history (last 100)
            $history = $updateSearcher.QueryHistory(0, [Math]::Min($historyCount, 100))
            
            $historyDetails = foreach ($entry in $history) {
                [PSCustomObject]@{
                    Date        = $entry.Date
                    Title       = $entry.Title
                    Operation   = switch ($entry.Operation) {
                        1 { 'Installation' }
                        2 { 'Uninstallation' }
                        default { 'Unknown' }
                    }
                    ResultCode  = switch ($entry.ResultCode) {
                        0 { 'Not Started' }
                        1 { 'In Progress' }
                        2 { 'Succeeded' }
                        3 { 'Succeeded With Errors' }
                        4 { 'Failed' }
                        5 { 'Aborted' }
                        default { 'Unknown' }
                    }
                }
            }
            
            $historyDetails | Sort-Object Date -Descending | Format-Table -AutoSize
            
            if ($OutputCsv) {
                $historyDetails | Export-Csv -Path $OutputCsv -NoTypeInformation
                Write-Host "`nExported history to $OutputCsv" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "Failed to retrieve update history: $_"
        }
    }
    
    'GetSettings' {
        Get-WindowsUpdateSettings
    }
}
