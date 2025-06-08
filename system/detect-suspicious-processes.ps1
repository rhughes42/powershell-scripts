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
foreach ($proc in Get-Process) {
    $suspicious = $false
    $reason = @()
    try {
        $path = $proc.Path
        if (-not $path) { continue }
        $sig = Get-AuthenticodeSignature $path
        if ($sig.Status -ne 'Valid') {
            $suspicious = $true
            $reason += 'Unsigned or invalid signature'
        }
        $parent = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)").ParentProcessId
        if ($parent -eq 0) {
            $suspicious = $true
            $reason += 'No parent process'
        }
        # Example: check for known bad hashes (add your own list)
        $hash = (Get-FileHash $path -Algorithm SHA256).Hash
        $badHashes = @('DEADBEEF...')
        if ($badHashes -contains $hash) {
            $suspicious = $true
            $reason += 'Known bad hash'
        }
    }
    catch { $reason += 'Error inspecting process' }
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
