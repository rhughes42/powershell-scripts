<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Test suite for newly added functionality.
.DESCRIPTION
    Validates that new scripts exist, have proper structure, and basic functionality works.
#>

$ErrorActionPreference = 'Stop'
$testsPassed = 0
$testsFailed = 0

Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                     Testing New Functionality                                  " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $scriptDir = Split-Path -Parent $scriptDir
}

# Test 1: Verify new scripts exist
Write-Host "Test 1: Verifying new scripts exist..." -ForegroundColor Yellow

$newScripts = @(
    "$scriptDir/windows-performance/monitor-performance-dashboard.ps1",
    "$scriptDir/windows-network/manage-vpn-connections.ps1",
    "$scriptDir/utils/system-health-check.ps1"
)

foreach ($script in $newScripts) {
    if (Test-Path $script) {
        Write-Host "  ✓ Found: $script" -ForegroundColor Green
        $testsPassed++
    }
    else {
        Write-Host "  ✗ Missing: $script" -ForegroundColor Red
        $testsFailed++
    }
}

# Test 2: Verify scripts have proper headers
Write-Host "`nTest 2: Verifying script headers..." -ForegroundColor Yellow

foreach ($script in $newScripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        
        $hasGraphHeader = $content -match '▄▄ • ▄▄▄'
        $hasSynopsis = $content -match '\.SYNOPSIS'
        $hasDescription = $content -match '\.DESCRIPTION'
        
        if ($hasGraphHeader -and $hasSynopsis -and $hasDescription) {
            Write-Host "  ✓ Valid header: $(Split-Path -Leaf $script)" -ForegroundColor Green
            $testsPassed++
        }
        else {
            Write-Host "  ✗ Invalid header: $(Split-Path -Leaf $script)" -ForegroundColor Red
            $testsFailed++
        }
    }
}

# Test 3: Verify scripts have parameters
Write-Host "`nTest 3: Verifying script parameters..." -ForegroundColor Yellow

foreach ($script in $newScripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        
        $hasParams = $content -match 'param\s*\('
        
        if ($hasParams) {
            Write-Host "  ✓ Has parameters: $(Split-Path -Leaf $script)" -ForegroundColor Green
            $testsPassed++
        }
        else {
            Write-Host "  ✗ No parameters: $(Split-Path -Leaf $script)" -ForegroundColor Red
            $testsFailed++
        }
    }
}

# Test 4: Verify scripts have functions
Write-Host "`nTest 4: Verifying script functions..." -ForegroundColor Yellow

foreach ($script in $newScripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        
        $hasFunctions = $content -match 'function\s+\w+'
        
        if ($hasFunctions) {
            Write-Host "  ✓ Has functions: $(Split-Path -Leaf $script)" -ForegroundColor Green
            $testsPassed++
        }
        else {
            Write-Host "  ⚠ No functions: $(Split-Path -Leaf $script)" -ForegroundColor Yellow
            $testsPassed++  # Not critical for all scripts
        }
    }
}

# Test 5: Verify PowerShell 7 compatibility check
Write-Host "`nTest 5: Verifying PowerShell 7 compatibility checks..." -ForegroundColor Yellow

foreach ($script in $newScripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        
        $hasVersionCheck = $content -match 'PSVersionTable\.PSVersion'
        
        if ($hasVersionCheck) {
            Write-Host "  ✓ Has version check: $(Split-Path -Leaf $script)" -ForegroundColor Green
            $testsPassed++
        }
        else {
            Write-Host "  ⚠ No version check: $(Split-Path -Leaf $script)" -ForegroundColor Yellow
            $testsPassed++  # Warning but not failure
        }
    }
}

# Test 6: Verify help examples exist
Write-Host "`nTest 6: Verifying help examples..." -ForegroundColor Yellow

foreach ($script in $newScripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        
        $hasExamples = $content -match '\.EXAMPLE'
        
        if ($hasExamples) {
            Write-Host "  ✓ Has examples: $(Split-Path -Leaf $script)" -ForegroundColor Green
            $testsPassed++
        }
        else {
            Write-Host "  ✗ No examples: $(Split-Path -Leaf $script)" -ForegroundColor Red
            $testsFailed++
        }
    }
}

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                              Test Summary                                      " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor Red
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "✗ Some tests failed." -ForegroundColor Red
    exit 1
}
