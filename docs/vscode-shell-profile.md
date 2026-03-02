## VS Code Shell Profile Runbook

This runbook defines a lightweight, responsive VS Code profile for PowerShell script development and dual-host shell workflows (Windows + WSL2/Kali).

**Scope**
- Repository: `superpower-shell`
- Primary language: PowerShell
- Secondary host: WSL2 (`kali-linux`)
- Goal: keep high signal tooling and remove extension bloat safely

**Baseline Files**
- `.vscode/extensions.json`
- `.vscode/settings.json`
- `.github/agents/SuperSheller.agent.md`

**Principles**
- Keep only extensions that materially improve PowerShell/shell workflows.
- Prefer built-in terminal and CLI tools over heavyweight extension stacks.
- Use disable-first before uninstall for all removals.
- Verify workflow after each cleanup batch.

**Extension Classification Model**
- Keep: essential for daily PowerShell + shell operations
- Optional: useful for specific tasks but not required daily
- Remove Candidate: unused or outside this repo's workflow

**Recommended Keep Set**
- `ms-vscode.powershell`
- `ms-vscode-remote.remote-wsl`
- `eamodio.gitlens`
- `mhutchie.git-graph`
- `usernamehw.errorlens`

**Common Remove Candidates (This Repo Context)**
- `ms-toolsai.jupyter`
- `ms-python.python`
- `ms-dotnettools.csharp`
- `redhat.java`
- `golang.go`
- `ms-vscode.cpptools`

**Audit Procedure**
1. Capture current extension inventory.
2. Compare inventory against Keep/Optional/Remove Candidate lists.
3. Disable remove candidates in one small batch.
4. Validate PowerShell and WSL workflows.
5. Uninstall only after successful validation.

**Commands**
```powershell
code --list-extensions > .\docs\extensions-before.txt
```

```powershell
# Example: disable first
code --disable-extension ms-toolsai.jupyter
code --disable-extension ms-python.python
```

```powershell
# Example: uninstall after validation
code --uninstall-extension ms-toolsai.jupyter
code --uninstall-extension ms-python.python
```

```powershell
code --list-extensions > .\docs\extensions-after.txt
```

**Validation Checks**
- Open and run at least one script from `network/` and one from `system/`.
- Run at least one test script from `tests/`.
- Start a terminal using both `PowerShell` and `WSL-Kali` profiles.
- Confirm IntelliSense, formatting, and diagnostics still work for `.ps1` files.

**Rollback**
- Re-enable extension if workflow regresses:
```powershell
code --enable-extension <extension-id>
```
- Reinstall extension if needed:
```powershell
code --install-extension <extension-id>
```

**Cadence**
- Perform quick extension audit monthly.
- Perform full audit after adding new toolchains (cloud SDKs, pentest stacks, language packs).

**Notes**
- If your distro name is not `kali-linux`, update `.vscode/settings.json` terminal profile args accordingly.
- Keep this runbook aligned with `.github/agents/SuperSheller.agent.md` and profile files.
