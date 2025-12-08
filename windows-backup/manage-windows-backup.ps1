<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Windows Backup and System Image management utility.
.DESCRIPTION
    Create, manage, and restore Windows backups using Windows Server Backup and System Image tools.
    Supports full system backups, file backups, and backup verification.
.PARAMETER Action
    Action to perform: CreateBackup, RestoreBackup, ListBackups, GetStatus, VerifyBackup, DeleteOldBackups
.PARAMETER BackupPath
    Destination path for backups
.PARAMETER SourcePaths
    Array of paths to backup (for file backup)
.PARAMETER BackupType
    Type: SystemImage, Files, Both (default: Files)
.PARAMETER RetentionDays
    Days to retain backups before deletion (default: 30)
.PARAMETER IncludeSystemState
    Include system state in backup (default: false)
.EXAMPLE
    .\manage-windows-backup.ps1 -Action CreateBackup -BackupPath "E:\Backups" -SourcePaths "C:\Users","C:\Important"
    Creates file backup of specified paths
.EXAMPLE
    .\manage-windows-backup.ps1 -Action ListBackups -BackupPath "E:\Backups"
    Lists all backups in the specified location
.EXAMPLE
    .\manage-windows-backup.ps1 -Action DeleteOldBackups -BackupPath "E:\Backups" -RetentionDays 30
    Deletes backups older than 30 days
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('CreateBackup', 'RestoreBackup', 'ListBackups', 'GetStatus', 'VerifyBackup', 'DeleteOldBackups', 'ScheduleBackup')]
    [string]$Action,
    
    [string]$BackupPath,
    [string[]]$SourcePaths,
    [ValidateSet('SystemImage', 'Files', 'Both')]
    [string]$BackupType = 'Files',
    [int]$RetentionDays = 30,
    [bool]$IncludeSystemState = $false,
    [string]$OutputCsv = 'BackupResults.csv'
)

#Requires -RunAsAdministrator

# Function to create file backup using robocopy
function New-FileBackup {
    param(
        [string[]]$Sources,
        [string]$Destination
    )
    
    Write-Host "=== Creating File Backup ===" -ForegroundColor Cyan
    Write-Host "Destination: $Destination" -ForegroundColor Yellow
    Write-Host "Source Paths: $($Sources.Count)" -ForegroundColor Yellow
    
    # Create timestamped backup folder
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupFolder = Join-Path $Destination "Backup_$timestamp"
    
    if (-not (Test-Path $Destination)) {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        Write-Host "Created backup destination: $Destination" -ForegroundColor Cyan
    }
    
    New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
    
    $results = @()
    $totalSize = 0
    
    foreach ($source in $Sources) {
        if (-not (Test-Path $source)) {
            Write-Warning "Source path not found: $source"
            continue
        }
        
        Write-Host "`nBacking up: $source" -ForegroundColor Cyan
        
        # Get source folder name for destination subfolder
        $sourceName = Split-Path $source -Leaf
        $destFolder = Join-Path $backupFolder $sourceName
        
        # Use robocopy for efficient copying with progress
        $robocopyArgs = @(
            $source,
            $destFolder,
            '/MIR',           # Mirror mode (copies all, deletes extra)
            '/R:3',           # Retry 3 times on failed copies
            '/W:5',           # Wait 5 seconds between retries
            '/MT:8',          # Multi-threaded (8 threads)
            '/NP',            # No progress percentage
            '/NDL',           # No directory list
            '/NFL',           # No file list
            '/LOG+:backup.log'
        )
        
        $startTime = Get-Date
        $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow -PassThru
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        # Robocopy exit codes: 0-7 are success, 8+ are errors
        $success = $process.ExitCode -lt 8
        
        # Calculate backup size
        if (Test-Path $destFolder) {
            $size = (Get-ChildItem -Path $destFolder -Recurse -File -ErrorAction SilentlyContinue | 
                     Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($size / 1MB, 2)
            $totalSize += $sizeMB
        }
        else {
            $sizeMB = 0
        }
        
        $results += [PSCustomObject]@{
            Source       = $source
            Destination  = $destFolder
            Success      = $success
            SizeMB       = $sizeMB
            DurationSec  = [math]::Round($duration, 2)
            ExitCode     = $process.ExitCode
        }
        
        if ($success) {
            Write-Host "  Completed: $sizeMB MB in $([math]::Round($duration,2)) seconds" -ForegroundColor Green
        }
        else {
            Write-Host "  Failed with exit code: $($process.ExitCode)" -ForegroundColor Red
        }
    }
    
    # Create backup manifest
    $manifest = [PSCustomObject]@{
        BackupDate    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        BackupFolder  = $backupFolder
        SourceCount   = $Sources.Count
        TotalSizeMB   = $totalSize
        BackupType    = 'Files'
        ComputerName  = $env:COMPUTERNAME
        Results       = $results
    }
    
    $manifestPath = Join-Path $backupFolder "backup_manifest.json"
    $manifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $manifestPath -Encoding utf8
    
    Write-Host "`n=== Backup Summary ===" -ForegroundColor Cyan
    Write-Host "Backup Location: $backupFolder" -ForegroundColor Yellow
    Write-Host "Total Size: $totalSize MB" -ForegroundColor Yellow
    Write-Host "Sources Backed Up: $($results.Where({$_.Success}).Count) of $($results.Count)" -ForegroundColor Yellow
    
    return $manifest
}

# Function to list backups
function Get-BackupList {
    param([string]$Path)
    
    Write-Host "Listing backups in: $Path" -ForegroundColor Cyan
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Backup path not found: $Path"
        return
    }
    
    # Find all backup folders (match Backup_YYYYMMDD_HHMMSS pattern)
    $backupFolders = Get-ChildItem -Path $Path -Directory | 
        Where-Object { $_.Name -match '^Backup_\d{8}_\d{6}$' } |
        Sort-Object Name -Descending
    
    if (-not $backupFolders) {
        Write-Host "No backups found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nFound $($backupFolders.Count) backup(s)" -ForegroundColor Yellow
    
    $backupList = foreach ($folder in $backupFolders) {
        # Get backup size
        $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        
        # Try to read manifest
        $manifestPath = Join-Path $folder.FullName "backup_manifest.json"
        $manifest = $null
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
        }
        
        [PSCustomObject]@{
            BackupName   = $folder.Name
            Date         = $folder.CreationTime
            Age          = [math]::Round(((Get-Date) - $folder.CreationTime).TotalDays, 1)
            SizeMB       = $sizeMB
            Path         = $folder.FullName
            HasManifest  = $manifest -ne $null
            SourceCount  = if ($manifest) { $manifest.SourceCount } else { 'N/A' }
        }
    }
    
    $backupList | Format-Table -AutoSize BackupName, Date, Age, SizeMB, SourceCount
    
    return $backupList
}

# Function to delete old backups
function Remove-OldBackups {
    param(
        [string]$Path,
        [int]$RetentionDays
    )
    
    Write-Host "Removing backups older than $RetentionDays days from: $Path" -ForegroundColor Cyan
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Backup path not found: $Path"
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    
    # Find old backup folders
    $oldBackups = Get-ChildItem -Path $Path -Directory | 
        Where-Object { $_.Name -match '^Backup_\d{8}_\d{6}$' -and $_.CreationTime -lt $cutoffDate }
    
    if (-not $oldBackups) {
        Write-Host "No backups older than $RetentionDays days found" -ForegroundColor Green
        return
    }
    
    Write-Host "`nFound $($oldBackups.Count) backup(s) to delete" -ForegroundColor Yellow
    
    foreach ($backup in $oldBackups) {
        $age = [math]::Round(((Get-Date) - $backup.CreationTime).TotalDays, 1)
        Write-Host "  Deleting: $($backup.Name) (Age: $age days)" -ForegroundColor Yellow
        
        try {
            Remove-Item -Path $backup.FullName -Recurse -Force -ErrorAction Stop
            Write-Host "    Deleted successfully" -ForegroundColor Green
        }
        catch {
            Write-Warning "    Failed to delete: $_"
        }
    }
}

# Function to verify backup integrity
function Test-BackupIntegrity {
    param([string]$Path)
    
    Write-Host "Verifying backup integrity: $Path" -ForegroundColor Cyan
    
    if (-not (Test-Path $Path)) {
        Write-Error "Backup path not found: $Path"
        return $false
    }
    
    # Check for manifest
    $manifestPath = Join-Path $Path "backup_manifest.json"
    if (-not (Test-Path $manifestPath)) {
        Write-Warning "Backup manifest not found"
        return $false
    }
    
    try {
        $manifest = Get-Content $manifestPath | ConvertFrom-Json
        
        Write-Host "`n=== Backup Verification ===" -ForegroundColor Yellow
        Write-Host "Backup Date: $($manifest.BackupDate)" -ForegroundColor Cyan
        Write-Host "Computer: $($manifest.ComputerName)" -ForegroundColor Cyan
        Write-Host "Sources: $($manifest.SourceCount)" -ForegroundColor Cyan
        Write-Host "Total Size: $($manifest.TotalSizeMB) MB" -ForegroundColor Cyan
        
        # Verify each source backup exists
        $allValid = $true
        foreach ($result in $manifest.Results) {
            if (Test-Path $result.Destination) {
                Write-Host "  ✓ $($result.Source)" -ForegroundColor Green
            }
            else {
                Write-Host "  ✗ $($result.Source) - Backup folder missing" -ForegroundColor Red
                $allValid = $false
            }
        }
        
        if ($allValid) {
            Write-Host "`nBackup integrity: VALID" -ForegroundColor Green
        }
        else {
            Write-Host "`nBackup integrity: INVALID (some backups missing)" -ForegroundColor Red
        }
        
        return $allValid
    }
    catch {
        Write-Error "Error verifying backup: $_"
        return $false
    }
}

# Main execution logic
switch ($Action) {
    'CreateBackup' {
        if (-not $BackupPath) {
            Write-Error "BackupPath parameter is required for CreateBackup action"
            return
        }
        
        if ($BackupType -eq 'Files' -or $BackupType -eq 'Both') {
            if (-not $SourcePaths) {
                Write-Error "SourcePaths parameter is required for file backup"
                return
            }
            
            $result = New-FileBackup -Sources $SourcePaths -Destination $BackupPath
            
            if ($result -and $OutputCsv) {
                $result.Results | Export-Csv -Path $OutputCsv -NoTypeInformation
                Write-Host "`nExported backup results to $OutputCsv" -ForegroundColor Green
            }
        }
        
        if ($BackupType -eq 'SystemImage') {
            Write-Host "System Image backup requires Windows Server Backup feature" -ForegroundColor Yellow
            Write-Host "Use: wbadmin start backup -backupTarget:$BackupPath -include:C: -allCritical -quiet" -ForegroundColor Cyan
        }
    }
    
    'ListBackups' {
        if (-not $BackupPath) {
            Write-Error "BackupPath parameter is required for ListBackups action"
            return
        }
        
        $backups = Get-BackupList -Path $BackupPath
        
        if ($backups -and $OutputCsv) {
            $backups | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported backup list to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'DeleteOldBackups' {
        if (-not $BackupPath) {
            Write-Error "BackupPath parameter is required for DeleteOldBackups action"
            return
        }
        
        Remove-OldBackups -Path $BackupPath -RetentionDays $RetentionDays
    }
    
    'VerifyBackup' {
        if (-not $BackupPath) {
            Write-Error "BackupPath parameter is required for VerifyBackup action"
            return
        }
        
        Test-BackupIntegrity -Path $BackupPath
    }
    
    'GetStatus' {
        Write-Host "=== Windows Backup Status ===" -ForegroundColor Cyan
        
        # Check if Windows Server Backup is installed
        $wsbFeature = Get-WindowsFeature -Name Windows-Server-Backup -ErrorAction SilentlyContinue
        if ($wsbFeature) {
            Write-Host "`nWindows Server Backup: $($wsbFeature.InstallState)" -ForegroundColor Yellow
        }
        else {
            Write-Host "`nWindows Server Backup: Not Available (Client OS)" -ForegroundColor Yellow
        }
        
        # Check File History status
        try {
            $fhConfig = Get-WmiObject -Namespace root\Microsoft\Windows\FileHistory -Class MSFT_FileHistoryConfig -ErrorAction SilentlyContinue
            if ($fhConfig) {
                Write-Host "File History: Enabled" -ForegroundColor Yellow
                Write-Host "  Target: $($fhConfig.TargetUrl)" -ForegroundColor Cyan
            }
            else {
                Write-Host "File History: Not Configured" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "File History: Unable to query status" -ForegroundColor Gray
        }
    }
    
    'ScheduleBackup' {
        Write-Host "To schedule automatic backups, use the Windows Task Scheduler:" -ForegroundColor Cyan
        Write-Host "`nExample command to create scheduled backup task:" -ForegroundColor Yellow
        Write-Host 'schtasks /create /tn "Daily Backup" /tr "pwsh.exe -File C:\Scripts\manage-windows-backup.ps1 -Action CreateBackup -BackupPath E:\Backups -SourcePaths C:\Users,C:\Important" /sc daily /st 02:00 /ru SYSTEM' -ForegroundColor Gray
        Write-Host "`nOr use the manage-scheduled-tasks.ps1 script in the windows-tasks folder" -ForegroundColor Cyan
    }
}
