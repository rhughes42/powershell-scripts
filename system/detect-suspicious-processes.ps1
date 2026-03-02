<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics
#>
<#
.SYNOPSIS
    Detect suspicious or potentially malicious processes.
.DESCRIPTION
    Scans running processes for common indicators of compromise (IoCs), such as unsigned binaries, odd parentage, or known bad hashes.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'SuspiciousProcesses.csv'
)

$results = @()
# Iterate through all running processes on the system
foreach ($proc in Get-Process) {
    $suspicious = $false
    $reason = @()
    try {
        # Get the executable path for the process
        $path = $proc.Path
        # Skip processes without a file path (system processes)
        if (-not $path) { continue }
        
        # Check if the executable has a valid digital signature
        $sig = Get-AuthenticodeSignature $path
        if ($sig.Status -ne 'Valid') {
            $suspicious = $true
            $reason += 'Unsigned or invalid signature'
        }
        
        # Retrieve the parent process ID to detect orphaned processes
        $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)").ParentProcessId
        if ($parent -eq 0) {
            $suspicious = $true
            $reason += 'No parent process'
        }
        
        # Compare file hash against known malicious hashes (IoC detection)
        # TODO: Replace with actual threat intelligence feed or known bad hash list
        $hash = (Get-FileHash $path -Algorithm SHA256).Hash
        $badHashes = @('DEADBEEF...')
        if ($badHashes -contains $hash) {
            $suspicious = $true
            $reason += 'Known bad hash'
        }
    }
    catch { $reason += 'Error inspecting process' }
    
    # Add suspicious processes to results array
    if ($suspicious) {
        $results += [PSCustomObject]@{
            Name    = $proc.Name
            Id      = $proc.Id
            Path    = $path
            Reasons = $reason -join '; '
        }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
