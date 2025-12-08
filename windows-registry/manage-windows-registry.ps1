<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Windows Registry monitoring and management utility.
.DESCRIPTION
    Monitor registry keys for changes, backup/restore registry keys, search registry, and audit registry permissions.
    Provides comprehensive registry management with safety features.
.PARAMETER Action
    Action to perform: Monitor, Backup, Restore, Search, GetValue, SetValue, Export, Compare, GetPermissions
.PARAMETER KeyPath
    Registry key path (e.g., "HKLM:\SOFTWARE\MyApp")
.PARAMETER ValueName
    Registry value name
.PARAMETER ValueData
    Data to set for registry value
.PARAMETER BackupPath
    Path to backup file
.PARAMETER SearchTerm
    Term to search for in registry
.PARAMETER MonitorDuration
    Duration to monitor in seconds (default: 60)
.EXAMPLE
    .\manage-windows-registry.ps1 -Action Backup -KeyPath "HKLM:\SOFTWARE\MyApp" -BackupPath "myapp_backup.reg"
    Backs up registry key to file
.EXAMPLE
    .\manage-windows-registry.ps1 -Action Monitor -KeyPath "HKCU:\Software\Microsoft" -MonitorDuration 300
    Monitors registry key for changes for 5 minutes
.EXAMPLE
    .\manage-windows-registry.ps1 -Action Search -SearchTerm "MyApp"
    Searches registry for keys/values containing "MyApp"
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Monitor', 'Backup', 'Restore', 'Search', 'GetValue', 'SetValue', 'Export', 'Compare', 'GetPermissions')]
    [string]$Action,
    
    [string]$KeyPath,
    [string]$ValueName,
    [object]$ValueData,
    [string]$BackupPath,
    [string]$SearchTerm,
    [int]$MonitorDuration = 60,
    [string]$OutputCsv = 'RegistryResults.csv'
)

#Requires -RunAsAdministrator

# Function to monitor registry key for changes
function Watch-RegistryKey {
    param(
        [string]$Path,
        [int]$Duration
    )
    
    Write-Host "Monitoring registry key: $Path" -ForegroundColor Cyan
    Write-Host "Duration: $Duration seconds" -ForegroundColor Yellow
    Write-Host "Monitoring for changes...`n" -ForegroundColor Yellow
    
    try {
        # Convert PowerShell path to .NET path format
        $regPath = $Path -replace '^HKLM:', 'HKEY_LOCAL_MACHINE' `
                           -replace '^HKCU:', 'HKEY_CURRENT_USER' `
                           -replace '^HKCR:', 'HKEY_CLASSES_ROOT' `
                           -replace '^HKU:', 'HKEY_USERS' `
                           -replace '^HKCC:', 'HKEY_CURRENT_CONFIG'
        
        # Take initial snapshot of the registry key
        if (Test-Path $Path) {
            $initialSnapshot = Get-ItemProperty -Path $Path
            $initialSubKeys = (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue).Name
        }
        else {
            Write-Error "Registry key not found: $Path"
            return
        }
        
        $endTime = (Get-Date).AddSeconds($Duration)
        $changes = @()
        
        # Monitor loop
        while ((Get-Date) -lt $endTime) {
            Start-Sleep -Seconds 5
            
            # Get current state
            $currentSnapshot = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
            $currentSubKeys = (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue).Name
            
            # Check for value changes
            foreach ($prop in $initialSnapshot.PSObject.Properties) {
                if ($prop.Name -notmatch '^PS') {  # Skip PowerShell properties
                    $currentValue = $currentSnapshot.$($prop.Name)
                    if ($currentValue -ne $prop.Value) {
                        $change = [PSCustomObject]@{
                            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                            Type      = 'ValueModified'
                            Key       = $Path
                            Name      = $prop.Name
                            OldValue  = $prop.Value
                            NewValue  = $currentValue
                        }
                        $changes += $change
                        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Value Modified: $($prop.Name)" -ForegroundColor Yellow
                        Write-Host "  Old: $($prop.Value)" -ForegroundColor Gray
                        Write-Host "  New: $currentValue" -ForegroundColor Green
                    }
                }
            }
            
            # Check for new values
            foreach ($prop in $currentSnapshot.PSObject.Properties) {
                if ($prop.Name -notmatch '^PS' -and -not $initialSnapshot.$($prop.Name)) {
                    $change = [PSCustomObject]@{
                        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                        Type      = 'ValueAdded'
                        Key       = $Path
                        Name      = $prop.Name
                        OldValue  = $null
                        NewValue  = $prop.Value
                    }
                    $changes += $change
                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Value Added: $($prop.Name) = $($prop.Value)" -ForegroundColor Green
                }
            }
            
            # Update snapshot for next iteration
            $initialSnapshot = $currentSnapshot
        }
        
        Write-Host "`nMonitoring completed. Total changes detected: $($changes.Count)" -ForegroundColor Cyan
        return $changes
    }
    catch {
        Write-Error "Error monitoring registry: $_"
    }
}

# Function to search registry
function Search-Registry {
    param([string]$Term)
    
    Write-Host "Searching registry for: $Term" -ForegroundColor Cyan
    Write-Host "This may take several minutes..." -ForegroundColor Yellow
    
    $results = @()
    
    # Search in common registry hives
    $hives = @('HKLM:\SOFTWARE', 'HKCU:\Software')
    
    foreach ($hive in $hives) {
        Write-Host "  Searching in $hive..." -ForegroundColor Gray
        
        try {
            # Search keys
            $keys = Get-ChildItem -Path $hive -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -like "*$Term*" }
            
            foreach ($key in $keys) {
                $results += [PSCustomObject]@{
                    Type     = 'Key'
                    Path     = $key.PSPath
                    Name     = $key.PSChildName
                    Match    = 'Key Name'
                }
            }
            
            # Search values
            $items = Get-ChildItem -Path $hive -Recurse -ErrorAction SilentlyContinue
            foreach ($item in $items) {
                $props = Get-ItemProperty -Path $item.PSPath -ErrorAction SilentlyContinue
                if ($props) {
                    foreach ($prop in $props.PSObject.Properties) {
                        if ($prop.Name -notmatch '^PS' -and 
                            ($prop.Name -like "*$Term*" -or $prop.Value -like "*$Term*")) {
                            $results += [PSCustomObject]@{
                                Type     = 'Value'
                                Path     = $item.PSPath
                                Name     = $prop.Name
                                Match    = if ($prop.Name -like "*$Term*") { 'Value Name' } else { 'Value Data' }
                                Data     = $prop.Value
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Error searching $hive : $_"
        }
    }
    
    Write-Host "`nFound $($results.Count) matches" -ForegroundColor Green
    return $results
}

# Function to get registry key permissions
function Get-RegistryPermissions {
    param([string]$Path)
    
    Write-Host "Retrieving permissions for: $Path" -ForegroundColor Cyan
    
    try {
        # Get ACL for registry key
        $acl = Get-Acl -Path $Path
        
        Write-Host "`nOwner: $($acl.Owner)" -ForegroundColor Yellow
        Write-Host "`nAccess Rules:" -ForegroundColor Yellow
        
        $permissions = foreach ($access in $acl.Access) {
            [PSCustomObject]@{
                IdentityReference = $access.IdentityReference
                AccessControlType = $access.AccessControlType
                RegistryRights    = $access.RegistryRights
                IsInherited       = $access.IsInherited
                InheritanceFlags  = $access.InheritanceFlags
            }
        }
        
        $permissions | Format-Table -AutoSize
        return $permissions
    }
    catch {
        Write-Error "Failed to retrieve permissions: $_"
    }
}

# Main execution logic
switch ($Action) {
    'Monitor' {
        if (-not $KeyPath) {
            Write-Error "KeyPath parameter is required for Monitor action"
            return
        }
        
        $changes = Watch-RegistryKey -Path $KeyPath -Duration $MonitorDuration
        
        if ($changes -and $OutputCsv) {
            $changes | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "Exported changes to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'Backup' {
        if (-not $KeyPath -or -not $BackupPath) {
            Write-Error "KeyPath and BackupPath parameters are required for Backup action"
            return
        }
        
        Write-Host "Backing up registry key: $KeyPath" -ForegroundColor Cyan
        Write-Host "Backup file: $BackupPath" -ForegroundColor Yellow
        
        try {
            # Use reg.exe for reliable registry export
            $regPath = $KeyPath -replace '^HKLM:', 'HKEY_LOCAL_MACHINE' `
                                 -replace '^HKCU:', 'HKEY_CURRENT_USER' `
                                 -replace '^HKCR:', 'HKEY_CLASSES_ROOT'
            
            $regPath = $regPath -replace '\\', '\'
            
            # Export using reg.exe
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "export `"$regPath`" `"$BackupPath`" /y" -Wait -NoNewWindow -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "Backup completed successfully" -ForegroundColor Green
                Write-Host "Backup saved to: $BackupPath" -ForegroundColor Cyan
            }
            else {
                Write-Error "Backup failed with exit code: $($process.ExitCode)"
            }
        }
        catch {
            Write-Error "Failed to backup registry key: $_"
        }
    }
    
    'Restore' {
        if (-not $BackupPath) {
            Write-Error "BackupPath parameter is required for Restore action"
            return
        }
        
        if (-not (Test-Path $BackupPath)) {
            Write-Error "Backup file not found: $BackupPath"
            return
        }
        
        Write-Host "Restoring registry from: $BackupPath" -ForegroundColor Cyan
        Write-Host "WARNING: This will overwrite existing registry values" -ForegroundColor Red
        
        # Confirm action
        $confirm = Read-Host "Type YES to confirm restore"
        if ($confirm -ne 'YES') {
            Write-Host "Restore cancelled" -ForegroundColor Yellow
            return
        }
        
        try {
            # Import using reg.exe
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "import `"$BackupPath`"" -Wait -NoNewWindow -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "Restore completed successfully" -ForegroundColor Green
            }
            else {
                Write-Error "Restore failed with exit code: $($process.ExitCode)"
            }
        }
        catch {
            Write-Error "Failed to restore registry: $_"
        }
    }
    
    'Search' {
        if (-not $SearchTerm) {
            Write-Error "SearchTerm parameter is required for Search action"
            return
        }
        
        $results = Search-Registry -Term $SearchTerm
        
        if ($results) {
            $results | Format-Table -AutoSize Type, Path, Name, Match
            
            if ($OutputCsv) {
                $results | Export-Csv -Path $OutputCsv -NoTypeInformation
                Write-Host "`nExported results to $OutputCsv" -ForegroundColor Green
            }
        }
    }
    
    'GetValue' {
        if (-not $KeyPath -or -not $ValueName) {
            Write-Error "KeyPath and ValueName parameters are required for GetValue action"
            return
        }
        
        Write-Host "Reading registry value..." -ForegroundColor Cyan
        Write-Host "Key: $KeyPath" -ForegroundColor Yellow
        Write-Host "Value: $ValueName" -ForegroundColor Yellow
        
        try {
            $value = Get-ItemProperty -Path $KeyPath -Name $ValueName -ErrorAction Stop
            Write-Host "`nValue Data: $($value.$ValueName)" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to read registry value: $_"
        }
    }
    
    'SetValue' {
        if (-not $KeyPath -or -not $ValueName -or $null -eq $ValueData) {
            Write-Error "KeyPath, ValueName, and ValueData parameters are required for SetValue action"
            return
        }
        
        Write-Host "Setting registry value..." -ForegroundColor Cyan
        Write-Host "Key: $KeyPath" -ForegroundColor Yellow
        Write-Host "Value: $ValueName" -ForegroundColor Yellow
        Write-Host "Data: $ValueData" -ForegroundColor Yellow
        
        try {
            # Create key if it doesn't exist
            if (-not (Test-Path $KeyPath)) {
                New-Item -Path $KeyPath -Force | Out-Null
                Write-Host "Created registry key: $KeyPath" -ForegroundColor Cyan
            }
            
            # Set the value
            Set-ItemProperty -Path $KeyPath -Name $ValueName -Value $ValueData -ErrorAction Stop
            Write-Host "`nRegistry value set successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to set registry value: $_"
        }
    }
    
    'Export' {
        if (-not $KeyPath -or -not $BackupPath) {
            Write-Error "KeyPath and BackupPath parameters are required for Export action"
            return
        }
        
        # Export is same as Backup
        & $MyInvocation.MyCommand.Path -Action Backup -KeyPath $KeyPath -BackupPath $BackupPath
    }
    
    'GetPermissions' {
        if (-not $KeyPath) {
            Write-Error "KeyPath parameter is required for GetPermissions action"
            return
        }
        
        $permissions = Get-RegistryPermissions -Path $KeyPath
        
        if ($permissions -and $OutputCsv) {
            $permissions | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported permissions to $OutputCsv" -ForegroundColor Green
        }
    }
}
