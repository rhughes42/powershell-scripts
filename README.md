# Graph PowerShell Scripts

This repository is organized for the development, organization, and testing of PowerShell 7+ scripts by Graph Technologies.

## Structure

- `network/` — Scripts for network diagnostics, connectivity, and related utilities.
- `system/` — Scripts for system information, monitoring, and automation.
- `utils/` — General utility scripts and helpers.
- `tests/` — Test scripts and sample data for validation.
- `docs/` — Documentation, guides, and references.
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

```powershell
pwsh ./network/test-vpn-connectivity.ps1 -Hosts @('8.8.8.8','1.1.1.1')
```

---

Graph Technologies · https://graphtechnologies.xyz/
