# PowerToys Run & Windows Command Palette Integration

This guide shows how to integrate PowerShell scripts with PowerToys Run for quick access via the Windows command palette.

## What is PowerToys Run?

PowerToys Run is a quick launcher for Windows that can:
- Launch applications
- Search files
- Run commands
- Execute PowerShell scripts
- Perform calculations and more

**Activation**: `Alt + Space` (default)

## Installing PowerToys

### Via Microsoft Store
1. Open Microsoft Store
2. Search for "PowerToys"
3. Click Install

### Via GitHub
```powershell
# Using winget
winget install Microsoft.PowerToys

# Or download from: https://github.com/microsoft/PowerToys/releases
```

## Configuring PowerToys Run

### 1. Enable PowerShell Plugin

1. Open PowerToys Settings
2. Navigate to "PowerToys Run"
3. Ensure "PowerShell" plugin is enabled
4. Set activation keyword (default: `>`)

### 2. Configure Search Paths

PowerToys Run can search custom directories for scripts:

1. Open PowerToys Settings
2. Go to "PowerToys Run" → "Plugins" → "Program"
3. Add your scripts directory:
   - Click "+" to add path
   - Enter: `C:\Scripts` (or your scripts location)
   - Check "Enabled subdirectories"

## Quick Access Methods

### Method 1: Direct PowerShell Execution

**Syntax**: `> script-name.ps1 -Parameters`

**Examples**:
```
> manage-windows-services.ps1 -Action List
> monitor-critical-services.ps1 -ServiceNames "W32Time"
> manage-windows-firewall.ps1 -Action GetStatus
```

### Method 2: Create Command Aliases

Create short aliases for frequently used commands.

#### Using PowerShell Profile

Add to your PowerShell profile (`$PROFILE`):

```powershell
# Service management aliases
function svc-list { & "C:\Scripts\windows\services\manage-windows-services.ps1" -Action List }
function svc-start {
    param([string]$Name)
    & "C:\Scripts\windows\services\manage-windows-services.ps1" -Action Start -ServiceName $Name
}
function svc-monitor {
    param([string[]]$Names)
    & "C:\Scripts\windows\services\monitor-critical-services.ps1" -ServiceNames $Names
}

# Firewall aliases
function fw-status { & "C:\Scripts\windows\firewall\manage-windows-firewall.ps1" -Action GetStatus }
function fw-audit { & "C:\Scripts\windows\firewall\manage-windows-firewall.ps1" -Action Audit }

# Defender aliases
function def-scan { & "C:\Scripts\windows\defender\manage-windows-defender.ps1" -Action QuickScan }
function def-status { & "C:\Scripts\windows\defender\manage-windows-defender.ps1" -Action Status }
function def-update { & "C:\Scripts\windows\defender\manage-windows-defender.ps1" -Action UpdateSignatures }

# Update aliases
function upd-check { & "C:\Scripts\windows\updates\manage-windows-updates.ps1" -Action Check }
function upd-install { & "C:\Scripts\windows\updates\manage-windows-updates.ps1" -Action Install }

# Event log aliases
function evt-monitor {
    param([string]$LogName = "System")
    & "C:\Scripts\windows\events\monitor-event-logs.ps1" -Action Monitor -LogName $LogName
}
function evt-search {
    param([string]$LogName, [string]$Keywords)
    & "C:\Scripts\windows\events\monitor-event-logs.ps1" -Action Search -LogName $LogName -Keywords $Keywords
}

# Backup aliases
function backup-create {
    param([string]$Path, [string[]]$Sources)
    & "C:\Scripts\windows\backup\manage-windows-backup.ps1" -Action CreateBackup -BackupPath $Path -SourcePaths $Sources
}
function backup-list {
    param([string]$Path)
    & "C:\Scripts\windows\\backup\\manage-windows-backup.ps1" -Action ListBackups -BackupPath $Path
}

# Registry aliases
    & "C:\Scripts\windows\backup\manage-windows-backup.ps1" -Action ListBackups -BackupPath $Path
    param([string]$KeyPath, [string]$BackupPath)
    & "C:\Scripts\windows\\registry\\manage-windows-registry.ps1" -Action Backup -KeyPath $KeyPath -BackupPath $BackupPath
}
    & "C:\Scripts\windows\registry\manage-windows-registry.ps1" -Action Backup -KeyPath $KeyPath -BackupPath $BackupPath
    param([string]$Term)
    & "C:\Scripts\windows\\registry\\manage-windows-registry.ps1" -Action Search -SearchTerm $Term
}
    & "C:\Scripts\windows\registry\manage-windows-registry.ps1" -Action Search -SearchTerm $Term

Then use in PowerToys Run:
```
> svc-list
> def-scan
> upd-check
> evt-monitor
```

### Method 3: Create Wrapper Batch Files

Create `.cmd` or `.bat` files in a PATH directory:

**Example**: `C:\Scripts\bin\svc-list.cmd`
```batch
@echo off
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\windows\services\manage-windows-services.ps1" -Action List
```

**Example**: `C:\Scripts\bin\def-scan.cmd`
```batch
@echo off
pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\windows\defender\manage-windows-defender.ps1" -Action QuickScan
pause
```

Then in PowerToys Run, just type:
```
svc-list
def-scan
```

### Method 4: Windows Terminal Integration

Create custom Windows Terminal profiles for quick access:

Edit `settings.json` in Windows Terminal:

```json
{
    "profiles": {
        "list": [
            {
                "name": "Service Monitor",
                "commandline": "pwsh.exe -NoExit -Command \"& 'C:\\Scripts\\windows/services/monitor-critical-services.ps1' -ServiceNames 'W32Time','Spooler'\"",
                "icon": "🔧",
                "startingDirectory": "C:\\Scripts"
            },
            {
                "name": "Defender Status",
                "commandline": "pwsh.exe -NoExit -Command \"& 'C:\\Scripts\\windows/defender/manage-windows-defender.ps1' -Action Status\"",
                "icon": "🛡️",
                "startingDirectory": "C:\\Scripts"
            },
            {
                "name": "Event Log Monitor",
                "commandline": "pwsh.exe -NoExit -Command \"& 'C:\\Scripts\\windows/events/monitor-event-logs.ps1' -Action Monitor -LogName System\"",
                "icon": "📊",
                "startingDirectory": "C:\\Scripts"
            },
            {
                "name": "Firewall Audit",
                "commandline": "pwsh.exe -NoExit -Command \"& 'C:\\Scripts\\windows/firewall/manage-windows-firewall.ps1' -Action Audit\"",
                "icon": "🔥",
                "startingDirectory": "C:\\Scripts"
            },
            {
                "name": "System Backup",
                "commandline": "pwsh.exe -NoExit -Command \"& 'C:\\Scripts\\windows/backup/manage-windows-backup.ps1' -Action CreateBackup -BackupPath 'E:\\Backups' -SourcePaths 'C:\\Users','C:\\Important'\"",
                "icon": "💾",
                "startingDirectory": "C:\\Scripts"
            }
        ]
    }
}
```

Access via Windows Terminal dropdown or PowerToys Run:
```
wt -p "Service Monitor"
wt -p "Defender Status"
```

## Recommended Quick Commands

Here are the most useful quick commands to set up:

### System Management
```
> svc-list                    # List all services
> svc-monitor                 # Monitor critical services
> def-status                  # Defender status
> def-scan                    # Quick antivirus scan
> upd-check                   # Check for Windows updates
> fw-status                   # Firewall status
```

### Monitoring
```
> evt-monitor System          # Monitor System event log
> evt-monitor Security        # Monitor Security log
> evt-search System disk      # Search for disk errors
```

### Maintenance
```
> def-update                  # Update Defender signatures
> backup-create E:\Backups    # Create backup
> reg-backup HKLM:\SOFTWARE   # Backup registry key
```

## Advanced: Context Menu Integration

Add scripts to Windows Explorer context menu for right-click access.

### Registry Method

Create `.reg` file to add context menu items:

**Example**: `add-defender-scan-context.reg`
```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\shell\DefenderScan]
@="Scan with Windows Defender"
"Icon"="C:\\Program Files\\Windows Defender\\EppManifest.dll"

[HKEY_CLASSES_ROOT\Directory\shell\DefenderScan\command]
@="pwsh.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\windows/defender/manage-windows-defender.ps1\" -Action CustomScan -Path \"%1\""

[HKEY_CLASSES_ROOT\Directory\Background\shell\DefenderScan]
@="Scan this folder with Defender"
"Icon"="C:\\Program Files\\Windows Defender\\EppManifest.dll"

[HKEY_CLASSES_ROOT\Directory\Background\shell\DefenderScan\command]
@="pwsh.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\windows/defender/manage-windows-defender.ps1\" -Action CustomScan -Path \"%V\""
```

**Example**: `add-backup-context.reg`
```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Directory\shell\BackupFolder]
@="Backup this folder"
"Icon"="imageres.dll,-1002"

[HKEY_CLASSES_ROOT\Directory\shell\BackupFolder\command]
@="pwsh.exe -NoProfile -ExecutionPolicy Bypass -File \"C:\\Scripts\\windows/backup/manage-windows-backup.ps1\" -Action CreateBackup -BackupPath \"E:\\Backups\" -SourcePaths \"%1\""
```

Import with: `reg import add-defender-scan-context.reg`

## Keyboard Shortcuts

### PowerToys Run Shortcuts

While PowerToys Run is open:
- `Tab` - Autocomplete
- `Ctrl + Shift + Enter` - Run as Administrator
- `Ctrl + C` - Copy result
- `Ctrl + H` - Show command history
- `Esc` - Close

### Custom Keyboard Shortcuts

Use PowerToys Keyboard Manager to create custom shortcuts:

1. Open PowerToys Settings
2. Go to "Keyboard Manager"
3. Click "Remap a shortcut"
4. Map keys to run scripts, e.g.:
    - `Ctrl + Alt + S` → `pwsh.exe -File C:\Scripts\windows\services\monitor-critical-services.ps1`
    - `Ctrl + Alt + D` → `pwsh.exe -File C:\Scripts\windows\defender\manage-windows-defender.ps1 -Action QuickScan`

## Tips and Tricks

### 1. Create a Central Scripts Menu

Create a main menu script: `C:\Scripts\menu.ps1`

```powershell
function Show-Menu {
    Clear-Host
    Write-Host "=== Windows Management Scripts ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Services:"
    Write-Host "  1. List Services"
    Write-Host "  2. Monitor Critical Services"
    Write-Host ""
    Write-Host "Security:"
    Write-Host "  3. Defender Status"
    Write-Host "  4. Quick Scan"
    Write-Host "  5. Firewall Audit"
    Write-Host ""
    Write-Host "Maintenance:"
    Write-Host "  6. Check Updates"
    Write-Host "  7. Event Log Monitor"
    Write-Host "  8. Create Backup"
    Write-Host ""
    Write-Host "  Q. Quit"
    Write-Host ""
}

do {
    Show-Menu
    $choice = Read-Host "Select option"

    switch ($choice) {
        '1' { & ".\windows/services/manage-windows-services.ps1" -Action List }
        '2' { & ".\windows/services/monitor-critical-services.ps1" -ServiceNames "W32Time","Spooler" }
        '3' { & ".\windows/defender/manage-windows-defender.ps1" -Action Status }
        '4' { & ".\windows/defender/manage-windows-defender.ps1" -Action QuickScan }
        '5' { & ".\windows/firewall/manage-windows-firewall.ps1" -Action Audit }
        '6' { & ".\windows/updates/manage-windows-updates.ps1" -Action Check }
        '7' { & ".\windows/events/monitor-event-logs.ps1" -Action Monitor -LogName System -Duration 60 }
        '8' { & ".\windows/backup/manage-windows-backup.ps1" -Action CreateBackup -BackupPath "E:\Backups" -SourcePaths "C:\Users" }
        'Q' { return }
    }

    Read-Host "`nPress Enter to continue"
} while ($true)
```

Launch with: `> menu`

### 2. Use PowerToys Quick Accent

For scripts with special characters, use Quick Accent (`Win + .`) to quickly insert them.

### 3. Pin to Taskbar

Create shortcuts to frequently used scripts and pin them to the taskbar:

1. Create shortcut to: `pwsh.exe -File "C:\Scripts\script.ps1"`
2. Right-click → "Pin to taskbar"
3. Customize icon if desired

### 4. Use Windows Search

Make scripts searchable via Windows Search:
1. Add `C:\Scripts` to Windows Search indexing locations
2. Search directly from Start menu
3. Scripts will appear in search results

## Troubleshooting

### PowerToys Run Not Finding Scripts

1. Verify PowerToys Run is enabled
2. Check that scripts directory is in search paths
3. Rebuild PowerToys Run index: Settings → PowerToys Run → "Rebuild Index"

### Scripts Not Executing

1. Check execution policy: `Get-ExecutionPolicy`
2. Ensure PowerShell 7 is installed: `pwsh --version`
3. Verify script paths are correct
4. Run PowerToys as Administrator if scripts require elevation

### Performance Issues

1. Limit number of indexed directories
2. Exclude large directories from indexing
3. Disable unused PowerToys Run plugins

## Resources

- [PowerToys Documentation](https://docs.microsoft.com/en-us/windows/powertoys/)
- [PowerToys Run GitHub](https://github.com/microsoft/PowerToys/tree/main/src/modules/launcher)
- [Windows Terminal Documentation](https://docs.microsoft.com/en-us/windows/terminal/)

---

**Graph Technologies** · https://graphtechnologies.xyz/
