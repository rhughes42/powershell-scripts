<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Perform a traceroute to multiple hosts and summarize hop statistics.
.DESCRIPTION
    Runs traceroute (Test-NetConnection -TraceRoute) for each host, collects hop counts, and outputs summary statistics.
.PARAMETER Hosts
    List of hosts to trace.
.PARAMETER OutputCsv
    Path to export hop statistics.
#>
param(
    [string[]]$Hosts = @('google.com','cloudflare.com'),
    [string]$OutputCsv = 'TraceMultiHopResults.csv'
)

$results = @()
foreach ($host in $Hosts) {
    Write-Host "Tracing $host ..."
    $trace = Test-NetConnection -ComputerName $host -TraceRoute
    $hops = $trace.TraceRoute | Where-Object { $_.ResponseTime -ne $null }
    $hopCount = $hops.Count
    $maxRtt = ($hops | Measure-Object -Property ResponseTime -Maximum).Maximum
    $minRtt = ($hops | Measure-Object -Property ResponseTime -Minimum).Minimum
    $avgRtt = ($hops | Measure-Object -Property ResponseTime -Average).Average
    $results += [PSCustomObject]@{
        Host = $host
        HopCount = $hopCount
        MinRttMs = [math]::Round($minRtt,2)
        MaxRttMs = [math]::Round($maxRtt,2)
        AvgRttMs = [math]::Round($avgRtt,2)
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
