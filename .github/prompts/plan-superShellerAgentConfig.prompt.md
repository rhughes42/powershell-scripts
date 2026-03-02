## Plan: PowerShell + WSL Agent Configuration

This plan repurposes your existing custom agent to serve dual purposes: planning + execution for shell scripting and pentesting workflows. Based on your choices, it uses a single unified agent with dual-mode execution (Windows PowerShell + WSL/Kali) and a balanced extension-cleanup policy. The approach is to rename and repurpose `SuperSheller` in place as your integrated planning/execution agent, expanding its mission beyond planning to include implementation/debug/runbook behavior. This consolidates your agent structure, gives you one authoritative place to encode PowerShell script guidance, WSL2 execution logic, and profile hygiene rules, and includes a lightweight baseline profile strategy for VS Code with a repeatable process to classify and remove unnecessary extensions.

**Steps**
1. Rename and normalize the agent identity to `SuperSheller` everywhere: file path `.github/agents/SuperSheller.agent.md`, frontmatter `name`, and all internal references/handoff labels.
2. Refactor the existing agent prompt in place to include mission and hard boundaries:
Use cases: PowerShell script authoring, debugging, test guidance, Windows shell ops, WSL2/Kali command workflows, and extension/profile hygiene.
Non-goals: broad app scaffolding unrelated to shell tooling.
3. Encode dual-mode host routing rules in the same agent instructions:
Detect whether task should run in Windows PowerShell or WSL (`pwsh` vs `wsl.exe -d <distro> ...`), with explicit fallback order and guardrails for Windows-only cmdlets (for example, scripts using `Get-NetAdapter`, `Win32_*`, `Get-WmiObject`).
4. Add PowerShell development standards to the repurposed agent prompt, aligned to repo conventions in `README.md` and `docs/CONTRIBUTING.md`:
Script header/comment expectations, parameter usage patterns, output patterns (CSV/logging), and when to reuse utilities like `utils/write-log.ps1`.
5. Add debugging and validation policy for this repo:
Primary verification via existing script-based tests in `tests/test-network-suite.ps1`, `tests/test-system-audit.ps1`, `tests/test-http-endpoints.ps1`, and `tests/test-bandwidth-monitor.ps1`; add “preflight checks” in the agent instructions for cloud CLIs (`az`, `aws`, `gcloud`) and WSL availability.
6. Define extension hygiene framework in the same agent:
Classify extensions into `Keep`, `Optional`, `Remove Candidate` for a balanced profile; require evidence-based removal suggestions (disable first, observe workflow impact, then uninstall); maintain a minimal “core shell stack” and optional cloud helpers.
7. Add workspace-level profile artifacts for repeatability:
Create/curate `.vscode/extensions.json` recommendations/unwanted lists and `.vscode/settings.json` performance-oriented settings for PowerShell/shell workflows; keep this repo as a lightweight reference profile.
8. Add a profile audit runbook doc (for example, `docs/vscode-shell-profile.md`):
Baseline capture (`code --list-extensions`), classification matrix, disable/uninstall sequence, rollback method, and cadence for re-audits.
9. Update agent handoffs inside `SuperSheller` to support both planning and implementation transitions while keeping one unified agent identity.
10. Pilot and tighten:
Run 3-5 real scenarios (PowerShell edit+debug, WSL Kali command flow, extension cleanup recommendation) and refine prompt wording where agent behavior is too broad or too strict.

**Verification**
- Agent behavior checks:
Validate planning and execution both work through `.github/agents/SuperSheller.agent.md` after repurposing.
- Repo workflow checks:
Run representative scripts and existing test scripts in `tests/` from PowerShell 7+.
- Cross-host checks:
Validate at least one Windows-native and one WSL/Kali task path with explicit host selection.
- Profile checks:
Compare extension inventory before/after cleanup (`code --list-extensions`) and confirm no regression in PowerShell editing/debugging tasks.
- Performance checks:
Measure startup/responsiveness before and after profile cleanup (cold start and command latency notes in runbook).

**Decisions**
- Chosen: single unified `SuperSheller` agent for planning + execution.
- Chosen: dual-mode Windows+WSL routing with fallback rules.
- Chosen: balanced extension cleanup policy.
- Naming decision: remove spaces and standardize on `SuperSheller` for both display name and file name.
