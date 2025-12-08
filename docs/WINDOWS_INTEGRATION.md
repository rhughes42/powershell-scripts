# Windows Integration Features

Comprehensive PowerShell 7+ scripts for Windows system management, automation, and integration.

## Overview

This collection provides enterprise-grade tools for managing Windows systems through PowerShell. All scripts are designed for PowerShell 7+ and include comprehensive error handling, logging, and documentation.

## Categories

### 🔧 Windows Services (`windows-services/`)
Manage and monitor Windows services with automated restart capabilities.

- **`manage-windows-services.ps1`** - Comprehensive service management (start/stop/restart/enable/disable)
- **`monitor-critical-services.ps1`** - Real-time service monitoring with auto-restart

### ⏰ Scheduled Tasks (`windows-tasks/`)
Create and manage Windows Scheduled Tasks for PowerShell script automation.

- **`manage-scheduled-tasks.ps1`** - Complete task scheduler interface for PowerShell scripts

### 🔥 Windows Firewall (`windows-firewall/`)
Manage Windows Firewall rules for enhanced security control.

- **`manage-windows-firewall.ps1`** - Create, modify, audit firewall rules and port management

### 🔄 Windows Updates (`windows-updates/`)
Automate Windows Update management and monitoring.

- **`manage-windows-updates.ps1`** - Check, download, install Windows updates with control

### 🛡️ Windows Defender (`windows-defender/`)
Control Windows Defender antivirus and security features.

- **`manage-windows-defender.ps1`** - Scans, exclusions, signature updates, threat history

### 📝 Windows Registry (`windows-registry/`)
Monitor, backup, restore, and manage Windows Registry.

- **`manage-windows-registry.ps1`** - Registry monitoring, backup/restore, search, permissions

### 📊 Windows Event Logs (`windows-events/`)
Advanced event log monitoring with real-time alerts and pattern detection.

- **`monitor-event-logs.ps1`** - Real-time monitoring, search, analyze, export event logs

### 💾 Windows Backup (`windows-backup/`)
Automated backup and restore operations.

- **`manage-windows-backup.ps1`** - File backup, verification, retention management

## Quick Start

### Prerequisites

- **PowerShell 7+** (tested on PowerShell 7.3+)
- **Administrator privileges** (most scripts require elevation)
- Windows 10/11 or Windows Server 2016+

### Installation

1. Clone or download this repository:
```powershell
git clone https://github.com/yourusername/powershell-scripts.git
cd powershell-scripts
```

2. Set execution policy (if needed):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Usage Examples

### Windows Services Management

#### List all services with details
```powershell
.\windows-services\manage-windows-services.ps1 -Action List -OutputCsv "services.csv"
```

#### Start a service
```powershell
.\windows-services\manage-windows-services.ps1 -Action Start -ServiceName "Spooler"
```

#### Monitor critical services with auto-restart
```powershell
.\windows-services\monitor-critical-services.ps1 -ServiceNames "W32Time","Spooler","Dhcp" -CheckIntervalSeconds 60
```

### Scheduled Tasks

#### Create a daily backup task
```powershell
.\windows-tasks\manage-scheduled-tasks.ps1 `
    -Action Create `
    -TaskName "DailyBackup" `
    -ScriptPath "C:\Scripts\backup.ps1" `
    -Trigger Daily `
    -Time "02:00"
```

#### Create a weekly report task
```powershell
.\windows-tasks\manage-scheduled-tasks.ps1 `
    -Action Create `
    -TaskName "WeeklyReport" `
    -ScriptPath "C:\Scripts\report.ps1" `
    -Trigger Weekly `
    -DaysOfWeek "Monday,Friday" `
    -Time "08:00"
```

#### View task execution history
```powershell
.\windows-tasks\manage-scheduled-tasks.ps1 -Action GetHistory -TaskName "DailyBackup"
```

### Windows Firewall

#### Allow a port (e.g., SSH)
```powershell
.\windows-firewall\manage-windows-firewall.ps1 `
    -Action AllowPort `
    -RuleName "Allow SSH" `
    -Port 22 `
    -Protocol TCP `
    -Direction Inbound
```

#### Block a port
```powershell
.\windows-firewall\manage-windows-firewall.ps1 `
    -Action BlockPort `
    -RuleName "Block Telnet" `
    -Port 23 `
    -Protocol TCP
```

#### Audit all firewall rules
```powershell
.\windows-firewall\manage-windows-firewall.ps1 -Action Audit -OutputCsv "firewall-audit.csv"
```

### Windows Updates

#### Check for available updates
```powershell
.\windows-updates\manage-windows-updates.ps1 -Action Check
```

#### Install security updates without reboot
```powershell
.\windows-updates\manage-windows-updates.ps1 `
    -Action Install `
    -UpdateType Security `
    -AutoReboot $false
```

#### View update history
```powershell
.\windows-updates\manage-windows-updates.ps1 -Action GetHistory -OutputCsv "update-history.csv"
```

### Windows Defender

#### Check Defender status
```powershell
.\windows-defender\manage-windows-defender.ps1 -Action Status
```

#### Run a quick scan
```powershell
.\windows-defender\manage-windows-defender.ps1 -Action QuickScan
```

#### Add an exclusion
```powershell
.\windows-defender\manage-windows-defender.ps1 `
    -Action AddExclusion `
    -Path "C:\MyApp" `
    -ExclusionType Path
```

#### Update signatures
```powershell
.\windows-defender\manage-windows-defender.ps1 -Action UpdateSignatures
```

### Windows Registry

#### Backup a registry key
```powershell
.\windows-registry\manage-windows-registry.ps1 `
    -Action Backup `
    -KeyPath "HKLM:\SOFTWARE\MyApp" `
    -BackupPath "myapp_backup.reg"
```

#### Monitor registry for changes
```powershell
.\windows-registry\manage-windows-registry.ps1 `
    -Action Monitor `
    -KeyPath "HKCU:\Software\Microsoft" `
    -MonitorDuration 300
```

#### Search registry
```powershell
.\windows-registry\manage-windows-registry.ps1 -Action Search -SearchTerm "MyApp"
```

### Windows Event Logs

#### Monitor Security log for failed logons
```powershell
.\windows-events\monitor-event-logs.ps1 `
    -Action Monitor `
    -LogName Security `
    -EventIds 4625 `
    -Duration 600
```

#### Search System log for errors
```powershell
.\windows-events\monitor-event-logs.ps1 `
    -Action Search `
    -LogName System `
    -Level Error `
    -Keywords "disk"
```

#### Analyze Application log
```powershell
.\windows-events\monitor-event-logs.ps1 `
    -Action Analyze `
    -LogName Application `
    -OutputCsv "app-analysis.csv"
```

### Windows Backup

#### Create file backup
```powershell
.\windows-backup\manage-windows-backup.ps1 `
    -Action CreateBackup `
    -BackupPath "E:\Backups" `
    -SourcePaths "C:\Users","C:\Important"
```

#### List backups
```powershell
.\windows-backup\manage-windows-backup.ps1 `
    -Action ListBackups `
    -BackupPath "E:\Backups"
```

#### Delete old backups (older than 30 days)
```powershell
.\windows-backup\manage-windows-backup.ps1 `
    -Action DeleteOldBackups `
    -BackupPath "E:\Backups" `
    -RetentionDays 30
```

## Integration with Windows Tools

### Windows Command Palette / PowerToys Run

PowerToys Run allows you to execute PowerShell scripts directly from the command palette. See [POWERTOYS_INTEGRATION.md](./POWERTOYS_INTEGRATION.md) for detailed setup.

### Task Scheduler Integration

All scripts can be scheduled using Windows Task Scheduler. Use the `manage-scheduled-tasks.ps1` script to automate this process:

```powershell
# Example: Schedule daily system health check
.\windows-tasks\manage-scheduled-tasks.ps1 `
    -Action Create `
    -TaskName "DailyHealthCheck" `
    -ScriptPath "C:\Scripts\system\get-system-info.ps1" `
    -Trigger Daily `
    -Time "06:00" `
    -RunElevated $true
```

### Windows Terminal Integration

Add scripts as Windows Terminal profiles for quick access. Edit your `settings.json`:

```json
{
    "profiles": {
        "list": [
            {
                "name": "Service Monitor",
                "commandline": "pwsh.exe -NoExit -File C:\\Scripts\\windows-services\\monitor-critical-services.ps1",
                "icon": "🔧"
            }
        ]
    }
}
```

## Automation Scenarios

### 1. Automated System Maintenance

Create a scheduled task that runs nightly to perform system maintenance:

```powershell
# maintenance-script.ps1
param([string]$LogPath = "C:\Logs\maintenance.log")

# Update Windows Defender
.\windows-defender\manage-windows-defender.ps1 -Action UpdateSignatures

# Check for Windows Updates
.\windows-updates\manage-windows-updates.ps1 -Action Check

# Backup critical registry keys
.\windows-registry\manage-windows-registry.ps1 `
    -Action Backup `
    -KeyPath "HKLM:\SOFTWARE\MyApp" `
    -BackupPath "C:\Backups\registry_$(Get-Date -Format 'yyyyMMdd').reg"

# Clean old backups
.\windows-backup\manage-windows-backup.ps1 `
    -Action DeleteOldBackups `
    -BackupPath "C:\Backups" `
    -RetentionDays 30

Write-Host "Maintenance completed at $(Get-Date)" | Out-File $LogPath -Append
```

Schedule it:
```powershell
.\windows-tasks\manage-scheduled-tasks.ps1 `
    -Action Create `
    -TaskName "NightlyMaintenance" `
    -ScriptPath "C:\Scripts\maintenance-script.ps1" `
    -Trigger Daily `
    -Time "02:00"
```

### 2. Security Monitoring

Monitor security-critical events and services:

```powershell
# Start service monitoring in background
Start-Process pwsh -ArgumentList "-File .\windows-services\monitor-critical-services.ps1 -ServiceNames 'W32Time','EventLog','WinDefend'" -WindowStyle Hidden

# Monitor security event log
.\windows-events\monitor-event-logs.ps1 `
    -Action Monitor `
    -LogName Security `
    -EventIds 4625,4624,4672 `
    -Duration 86400
```

### 3. Automated Backups

```powershell
# daily-backup.ps1
$backupPath = "E:\Backups"
$sources = @("C:\Users", "C:\ImportantData", "D:\Projects")

# Create backup
.\windows-backup\manage-windows-backup.ps1 `
    -Action CreateBackup `
    -BackupPath $backupPath `
    -SourcePaths $sources

# Verify backup
.\windows-backup\manage-windows-backup.ps1 `
    -Action VerifyBackup `
    -BackupPath (Get-ChildItem $backupPath -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName

# Clean old backups
.\windows-backup\manage-windows-backup.ps1 `
    -Action DeleteOldBackups `
    -BackupPath $backupPath `
    -RetentionDays 30
```

## Best Practices

1. **Always run with Administrator privileges** - Most Windows management tasks require elevation
2. **Test in non-production first** - Validate scripts in test environments before production use
3. **Review logs regularly** - All scripts generate logs; monitor them for issues
4. **Use scheduled tasks for automation** - Leverage Task Scheduler for recurring operations
5. **Backup before making changes** - Always backup registry, services, and configurations before modifications
6. **Monitor script execution** - Use event logs and monitoring to track script performance
7. **Keep PowerShell updated** - Use PowerShell 7+ for best compatibility and features

## Security Considerations

- **Credential Management**: Never hardcode credentials; use Windows Credential Manager or secure vaults
- **Execution Policy**: Set appropriate execution policies for your environment
- **Code Signing**: Consider signing scripts in production environments
- **Audit Trail**: Enable logging for all administrative actions
- **Least Privilege**: Run scripts with minimum required privileges when possible
- **Review Before Execution**: Always review scripts before running them with elevated privileges

## Troubleshooting

### Common Issues

1. **"Access Denied" errors**
   - Ensure you're running PowerShell as Administrator
   - Check that your account has necessary permissions

2. **"Execution Policy" errors**
   - Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

3. **Module not found**
   - Some scripts may require additional modules (PSWindowsUpdate for updates)
   - Install missing modules: `Install-Module -Name ModuleName -Force`

4. **WMI/CIM errors**
   - Ensure WMI service is running: `Get-Service Winmgmt`
   - Restart WMI if needed: `Restart-Service Winmgmt -Force`

## Contributing

Contributions are welcome! Please:
1. Follow the existing code style and structure
2. Include comprehensive help documentation in comment blocks
3. Test on multiple Windows versions (10, 11, Server)
4. Update this documentation for new features

## License

See LICENSE file in the repository root.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Visit: https://graphtechnologies.xyz/

---

**Graph Technologies** · Computational Analysis & Geometry · Applied AI · Robotics
