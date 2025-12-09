<#
.SYNOPSIS
    Scans PowerShell files for reserved variable shadowing and common anti-patterns.
.DESCRIPTION
    Recursively scans *.ps1 files for problematic usage patterns such as:
    - foreach ($Host in ...) - shadows the automatic $Host variable
    - foreach ($Error in ...) - shadows the automatic $Error variable
    - foreach ($Input in ...) - shadows the automatic $Input variable
    - param($Host, ...) - parameter shadowing automatic variable
    Reports findings and optionally exits with non-zero code.
.PARAMETER Path
    Root path to scan. Defaults to current directory.
.PARAMETER Fix
    If specified, creates .bak backups and attempts to fix issues automatically.
.PARAMETER ExitOnError
    If specified, exits with code 1 when issues are found.
.EXAMPLE
    .github/scripts/scan-reserved-vars.ps1 -Path . -ExitOnError
#>
param(
    [string]$Path = '.',
    [switch]$Fix,
    [switch]$ExitOnError
)

# List of reserved/automatic PowerShell variables that should not be shadowed
$reservedVars = @(
    'Host',
    'Error',
    'Input',
    'Matches',
    'PSCmdlet',
    'PSBoundParameters',
    'MyInvocation',
    'ExecutionContext'
)

# Patterns to detect
$patterns = @(
    @{
        Regex = 'foreach\s*\(\s*\$(' + ($reservedVars -join '|') + ')\s+in'
        Description = 'foreach loop variable shadowing'
        Replacement = { param($match) $match -replace '\$Host', '$targetHost' -replace '\$host', '$targetHost' -replace '\$Error', '$err' -replace '\$error', '$err' -replace '\$Input', '$inputItem' -replace '\$input', '$inputItem' }
    },
    @{
        Regex = 'param\s*\([^)]*\$(' + ($reservedVars -join '|') + ')[\s,\)]'
        Description = 'function parameter shadowing'
        Replacement = { param($match) $match -replace '\$Host', '$TargetHost' -replace '\$host', '$TargetHost' -replace '\$Error', '$ErrorInfo' -replace '\$error', '$ErrorInfo' -replace '\$Input', '$InputData' -replace '\$input', '$InputData' }
    }
)

Write-Host "Scanning PowerShell files for reserved variable shadowing..." -ForegroundColor Cyan
Write-Host "Root path: $Path" -ForegroundColor Cyan
Write-Host ""

$issuesFound = 0
$filesScanned = 0

# Get all PowerShell files, excluding .git directory
$files = Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

foreach ($file in $files) {
    $filesScanned++
    $content = Get-Content -Path $file.FullName -Raw
    $fileHasIssues = $false
    $updatedContent = $content
    
    foreach ($pattern in $patterns) {
        if ($content -match $pattern.Regex) {
            $matches = [regex]::Matches($content, $pattern.Regex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            foreach ($match in $matches) {
                if (-not $fileHasIssues) {
                    Write-Host "Issues found in: $($file.FullName)" -ForegroundColor Yellow
                    $fileHasIssues = $true
                }
                
                $issuesFound++
                $lineNumber = ($content.Substring(0, $match.Index) -split "`n").Count
                Write-Host "  Line $lineNumber`: $($pattern.Description)" -ForegroundColor Red
                Write-Host "    $($match.Value)" -ForegroundColor Gray
                
                if ($Fix) {
                    # Apply replacement
                    $updatedContent = $updatedContent -replace [regex]::Escape($match.Value), (& $pattern.Replacement $match.Value)
                }
            }
        }
    }
    
    # If fixes were applied, save the file
    if ($Fix -and $fileHasIssues) {
        $backupPath = $file.FullName + '.bak'
        Copy-Item -Path $file.FullName -Destination $backupPath -Force
        Set-Content -Path $file.FullName -Value $updatedContent -NoNewline
        Write-Host "  ✓ Fixed and backed up to: $backupPath" -ForegroundColor Green
    }
    
    if ($fileHasIssues) {
        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scan complete!" -ForegroundColor Cyan
Write-Host "Files scanned: $filesScanned" -ForegroundColor Cyan
Write-Host "Issues found: $issuesFound" -ForegroundColor $(if ($issuesFound -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================" -ForegroundColor Cyan

if ($issuesFound -gt 0) {
    Write-Host ""
    Write-Host "Common reserved variables to avoid:" -ForegroundColor Yellow
    Write-Host "  - `$Host (use `$targetHost, `$computerName, etc.)" -ForegroundColor Gray
    Write-Host "  - `$Error (use `$err, `$errorInfo, etc.)" -ForegroundColor Gray
    Write-Host "  - `$Input (use `$inputItem, `$inputData, etc.)" -ForegroundColor Gray
    Write-Host ""
    
    if ($Fix) {
        Write-Host "Fixes have been applied. Review changes and remove .bak files when satisfied." -ForegroundColor Green
    } else {
        Write-Host "Run with -Fix to automatically fix issues (creates .bak backups)." -ForegroundColor Yellow
    }
}

if ($ExitOnError -and $issuesFound -gt 0) {
    exit 1
}

exit 0
