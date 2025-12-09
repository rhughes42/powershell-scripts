# Contributing to Graph PowerShell Scripts

Thank you for your interest in contributing to this repository! This guide will help you understand how to run tests, ensure code quality, and contribute effectively.

## Running Tests Locally

### Prerequisites

- PowerShell 7+ installed
- Windows environment (for system-level tests)

### Running All Tests

To run the complete test suite:

```powershell
# From the repository root
cd tests

# Run individual test files
pwsh -File sample-test.ps1
pwsh -File test-http-endpoints.ps1
pwsh -File test-bandwidth-monitor.ps1
pwsh -File test-system-audit.ps1
pwsh -File test-network-suite.ps1
```

### Running Linters

#### Reserved Variable Scanner

The repository includes a custom scanner to detect shadowing of PowerShell reserved variables:

```powershell
# Scan for issues
.github/scripts/scan-reserved-vars.ps1 -Path . -ExitOnError

# Scan and automatically fix issues (creates .bak backups)
.github/scripts/scan-reserved-vars.ps1 -Path . -Fix
```

Common reserved variables to avoid:
- `$Host` - Use `$targetHost`, `$computerName`, etc. instead
- `$Error` - Use `$err`, `$errorInfo`, etc. instead
- `$Input` - Use `$inputItem`, `$inputData`, etc. instead

#### PSScriptAnalyzer

Install and run PSScriptAnalyzer for comprehensive PowerShell linting:

```powershell
# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser

# Run on all scripts
Get-ChildItem -Path . -Filter "*.ps1" -Recurse | ForEach-Object {
    Invoke-ScriptAnalyzer -Path $_.FullName
}
```

## Test Requirements

All test scripts must follow these guidelines:

### 1. Explicit Exit Codes

Tests **must** exit with explicit exit codes:
- `exit 0` for success
- `exit 1` for failure

Example:
```powershell
if ($result -eq $expected) {
    Write-Host "✓ Test passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Test failed" -ForegroundColor Red
    exit 1
}
```

### 2. Clear Messages

Tests should provide clear, human-friendly messages:
- Use colored output (`-ForegroundColor Green/Red/Yellow`)
- Include context in error messages
- Use consistent symbols: ✓ for success, ❌ for failure

### 3. Reserved Variable Avoidance

Never shadow PowerShell automatic variables in loops or parameters:

❌ **Bad:**
```powershell
foreach ($Host in $Hosts) { ... }
param($Host, $Port)
```

✅ **Good:**
```powershell
foreach ($targetHost in $Hosts) { ... }
param($TargetHost, $Port)
```

## Integration Tests vs Unit Tests

### Unit Tests
Regular tests that can run on GitHub-hosted runners. These should:
- Not require elevated privileges
- Not modify system configuration (firewall, services, registry)
- Be safe to run in CI environments

### Integration Tests
Tests that require system-level access or make destructive changes. These:
- Should be marked clearly in the test name or comments
- Are typically gated to self-hosted runners or require manual execution
- Examples: Windows Defender configuration, firewall rules, service management

## Continuous Integration

The repository has two main CI workflows:

### 1. Run Test Suite (`run-test-suite.yml`)
Focused on the `tests/` directory:
- **Lint job**: Runs reserved variable scanner and PSScriptAnalyzer
- **Run-tests job**: Executes all test scripts with proper exit code handling

### 2. Test PowerShell Scripts (`test-powershell-scripts.yml`)
Comprehensive testing across all script categories:
- Syntax validation for all `.ps1` files
- Individual test jobs for each category (network, system, utils, etc.)
- System-level tests that may require Windows-specific features

### CI Best Practices

When adding new tests:
1. Ensure they have explicit exit codes
2. Run the lint checks locally first
3. Verify tests pass on Windows
4. Consider whether the test needs a self-hosted runner
5. Update documentation if adding new test patterns

## Code Style

- Follow existing naming conventions
- Use clear, descriptive variable names
- Add synopsis and description to all functions and scripts
- Use Write-Host with color coding for important messages
- Include error handling where appropriate

## Pull Request Process

1. Create a feature branch from `develop`
2. Make your changes with clear, focused commits
3. Run all linters and tests locally
4. Ensure CI passes on your PR
5. Update documentation if needed
6. Request review from maintainers

## Getting Help

If you have questions or need clarification:
- Open an issue with the `question` label
- Review existing scripts for examples
- Check the README.md for repository structure

## License

By contributing, you agree that your contributions will be licensed under the same license as the repository.
