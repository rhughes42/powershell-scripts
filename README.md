# Graph PowerShell Scripts

[![Test PowerShell Scripts](https://github.com/rhughes42/powershell-scripts/actions/workflows/test-powershell-scripts.yml/badge.svg)](https://github.com/rhughes42/powershell-scripts/actions/workflows/test-powershell-scripts.yml)
[![Run Test Suite](https://github.com/rhughes42/powershell-scripts/actions/workflows/run-test-suite.yml/badge.svg)](https://github.com/rhughes42/powershell-scripts/actions/workflows/run-test-suite.yml)

This repository is organized for the development, organization, and testing of PowerShell 7+ scripts by Graph Technologies.

## Repository Structure

```
powershell-scripts/
├── cloud/                    # Cloud platform management (AWS, Azure, GCP)
├── network/                  # Network diagnostics and connectivity
├── system/                   # System information and monitoring
├── sysclean/                 # System cleanup utilities
├── utils/                    # General utility scripts
├── windows-backup/           # Automated backup management
├── windows-defender/         # Antivirus control and scanning
├── windows-events/           # Event log monitoring and alerts
├── windows-firewall/         # Firewall rule management
├── windows-registry/         # Registry operations and monitoring
├── windows-services/         # Service management and monitoring
├── windows-tasks/            # Scheduled task automation
├── windows-updates/          # Windows Update management
├── tests/                    # Test scripts and validation
└── docs/                     # Documentation and guides
```

## Structure

### Core Scripts
- `network/` — Scripts for network diagnostics, connectivity, and related utilities.
- `system/` — Scripts for system information, monitoring, and automation.
- `sysclean/` — System cleanup utilities for finding duplicates, large files, and disk space management.
- `utils/` — General utility scripts and helpers.
- `cloud/` — Cloud platform management scripts (AWS, Azure, GCP).

### Windows Integration Features 🆕
- `windows-services/` — Windows Services management and monitoring with auto-restart capabilities.
- `windows-tasks/` — Windows Scheduled Tasks automation for PowerShell scripts.
- `windows-firewall/` — Windows Firewall rule management, port control, and security auditing.
- `windows-updates/` — Windows Update management, installation, and monitoring.
- `windows-defender/` — Windows Defender antivirus control, scanning, and exclusion management.
- `windows-registry/` — Windows Registry monitoring, backup, restore, and search capabilities.
- `windows-events/` — Advanced Windows Event Log monitoring with real-time alerts.
- `windows-backup/` — Automated Windows backup creation, verification, and retention management.

### Supporting Directories
- `tests/` — Test scripts and sample data for validation.
- `docs/` — Documentation, guides, and integration references.
- Root: High-value or multi-purpose scripts (e.g., `test-vpn-connectivity.ps1`).

## Conventions

- All scripts target **PowerShell 7+**.
- Use clear headers and comment blocks for synopsis, description, parameters, and examples (see `test-vpn-connectivity.ps1`).
- Prefer `Write-Host` for user-facing output and `Write-Log` for log entries.
- Export results to CSV or other formats where useful.

## Getting Started

1. Clone the repository.
2. Open in VS Code or your preferred editor.
3. Run scripts with PowerShell 7+ (`pwsh`).

## Example Usage

### Network & System Scripts
```powershell
# Test VPN connectivity
pwsh ./network/test-vpn-connectivity.ps1 -Hosts @('8.8.8.8','1.1.1.1')

# Monitor system resources
pwsh ./system/monitor-cpu-memory.ps1 -IntervalSeconds 5 -DurationSeconds 60

# Find duplicate files
pwsh ./sysclean/find-duplicate-files.ps1 -RootPath "C:\Users"
```

### Windows Integration Scripts
```powershell
# Manage Windows Services
pwsh ./windows-services/manage-windows-services.ps1 -Action List -OutputCsv "services.csv"
pwsh ./windows-services/monitor-critical-services.ps1 -ServiceNames "W32Time","Spooler"

# Schedule PowerShell tasks
pwsh ./windows-tasks/manage-scheduled-tasks.ps1 -Action Create -TaskName "DailyBackup" -ScriptPath "C:\Scripts\backup.ps1" -Trigger Daily -Time "02:00"

# Manage Windows Firewall
pwsh ./windows-firewall/manage-windows-firewall.ps1 -Action AllowPort -RuleName "Allow SSH" -Port 22 -Protocol TCP

# Windows Defender operations
pwsh ./windows-defender/manage-windows-defender.ps1 -Action QuickScan
pwsh ./windows-defender/manage-windows-defender.ps1 -Action Status

# Monitor Event Logs
pwsh ./windows-events/monitor-event-logs.ps1 -Action Monitor -LogName Security -EventIds 4625,4624 -Duration 600

# Windows Updates
pwsh ./windows-updates/manage-windows-updates.ps1 -Action Check
pwsh ./windows-updates/manage-windows-updates.ps1 -Action Install -UpdateType Security

# Registry Management
pwsh ./windows-registry/manage-windows-registry.ps1 -Action Backup -KeyPath "HKLM:\SOFTWARE\MyApp" -BackupPath "backup.reg"

# Automated Backups
pwsh ./windows-backup/manage-windows-backup.ps1 -Action CreateBackup -BackupPath "E:\Backups" -SourcePaths "C:\Users","C:\Important"
```

## Windows Integration Features

For comprehensive Windows system management, this repository includes enterprise-grade tools for:

- **Service Management**: Start, stop, restart, and monitor Windows services with automated recovery
- **Task Scheduling**: Create and manage scheduled tasks for PowerShell script automation
- **Firewall Control**: Manage firewall rules, ports, and security policies
- **Windows Updates**: Automate update checking, installation, and monitoring
- **Defender Integration**: Control antivirus scans, exclusions, and signature updates
- **Registry Operations**: Monitor, backup, restore, and search the Windows Registry
- **Event Log Monitoring**: Real-time event log monitoring with pattern detection and alerts
- **Backup Automation**: File and system backups with verification and retention policies

**See detailed documentation**: [Windows Integration Guide](./docs/WINDOWS_INTEGRATION.md)

**PowerToys Run Integration**: [PowerToys Setup Guide](./docs/POWERTOYS_INTEGRATION.md)

---

Graph Technologies · <https://graphtechnologies.xyz/>
