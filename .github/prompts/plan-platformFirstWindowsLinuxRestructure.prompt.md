## Plan: Platform-First Windows/Linux Restructure

This organizes scripts under `/windows`, `/linux`, and `/shared`, with shims to avoid breakage. Goal: preserve current functionality/docs/tests while making room for a Kali/Linux side. Chosen taxonomy: platform-first with legacy shims.

**Steps**
1. Baseline map
   - Inventory existing top-level Windows groups (windows-*, network, system, sysclean, utils) and tag each script as Windows-only vs potentially shared.
   - Identify path consumers: README sections for Windows usage, docs/WINDOWS_INTEGRATION.md, docs/FUTURE_DEVELOPMENT.md, tests under `tests/` (test-new-functionality.ps1, test-system-audit.ps1) that reference current paths.

2. Target tree design
   - Create roots: `/windows`, `/linux`, `/shared`.
   - Windows destinations (examples): `/windows/network/manage-vpn-connections.ps1` (from windows-network), `/windows/tasks/manage-scheduled-tasks.ps1`, `/windows/firewall/manage-windows-firewall.ps1`, `/windows/performance/monitor-performance-dashboard.ps1`, `/windows/services/manage-windows-services.ps1`, `/windows/updates/manage-windows-updates.ps1`, `/windows/backup/manage-windows-backup.ps1`.
   - Shared destinations: `/shared/cloud/*` (if CLIs are cross-platform), `/shared/utils/*` (only those not Windows-specific), `/shared/docs/*` (general).
   - Linux/Kali placeholder structure: `/linux/network/`, `/linux/tasks/`, `/linux/utils/`, ready for incoming scripts.

3. Classification rules
   - Windows-only: uses WMI/CIM/Win32_*, EventLog, registry, Windows services/tasks/firewall, Windows-specific modules.
   - Shared: pure PowerShell + API/CLI that works on both (e.g., Azure/AWS/GCP CLI if not using Windows-only cmdlets).
   - Linux: bash/Kali tools or PowerShell targeting Linux subsystems.

4. Move plan + shims
   - Physically relocate Windows scripts into `/windows/...`.
   - Add stub forwarders (PowerShell wrapper files or symlinks if allowed) at old paths (e.g., `windows-network/manage-vpn-connections.ps1` calls `../windows/network/manage-vpn-connections.ps1`) to prevent breakage during transition.
   - Keep shared files (cloud, utils) either in `/shared/...` with shims from old locations or leave in place if heavily referenced, noting a deprecation timeline.

5. Docs/test updates
   - Rewrite paths in README sections for Windows usage.
   - Update docs/WINDOWS_INTEGRATION.md references to new `/windows/...` paths.
   - Update tests referencing old paths to point to new locations or to shims.
   - Add a migration note in README summarizing legacy shim availability and sunset plan.

6. Linux/Kali side bootstrap
   - Create `/linux` folders mirroring Windows categories with placeholder READMEs and a WSL/Kali smoke script (e.g., `/linux/network/smoke-wsl-network.sh`).
   - Document host selection in docs/vscode-shell-profile.md and docs/SuperSheller-agent-artefact.md.

7. Verification
   - Run existing tests after path updates.
   - Manually invoke a few key scripts via shims and new paths to confirm forwarding works.
   - Validate README/Windows Integration links resolve.

**Decisions**
- Taxonomy: platform-first with `/windows`, `/linux`, `/shared`, plus legacy shims.
- Shims: use wrapper scripts (portable) unless symlinks are acceptable in your environment.
- Shared vs Windows: classify CLI-based cloud scripts as shared only if they avoid Windows-only cmdlets; otherwise keep under `/windows`.
