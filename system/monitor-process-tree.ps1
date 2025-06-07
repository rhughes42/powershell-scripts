<#
.SYNOPSIS
    Monitor a process and its child processes for resource usage and events.
.DESCRIPTION
    Tracks CPU/memory usage, start/stop events, and optionally logs to file. Useful for debugging or auditing long-running jobs.
.PARAMETER ProcessName
    Name of the root process to monitor.
.PARAMETER IntervalSeconds
    Sampling interval in seconds.
.PARAMETER OutputCsv
    Path to export monitoring data.
#>
param(
    [string]$ProcessName = 'pwsh',
    [int]$IntervalSeconds = 5,
    [string]$OutputCsv = 'ProcessTreeMonitor.csv'
)

function Get-ProcessTree($rootName) {
    $root = Get-Process -Name $rootName -ErrorAction SilentlyContinue
    if (-not $root) { return @() }
    $all = Get-Process | Select-Object Id, Name, Parent
    $tree = @($root)
    $children = $all | Where-Object { $_.Parent -eq $root.Id }
    foreach ($child in $children) {
        $tree += Get-ProcessTree $child.Name
    }
    return $tree
}

$results = @()
while ($true) {
    $procs = Get-ProcessTree $ProcessName
    if (-not $procs) {
        Write-Host "Process $ProcessName not found. Exiting."
        break
    }
    foreach ($p in $procs) {
        $results += [PSCustomObject]@{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Name      = $p.Name
            Id        = $p.Id
            CPU       = $p.CPU
            WS_MB     = [math]::Round($p.WorkingSet / 1MB, 2)
        }
    }
    $results | Export-Csv -Path $OutputCsv -NoTypeInformation
    Start-Sleep -Seconds $IntervalSeconds
}
