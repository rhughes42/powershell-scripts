<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Test DNS resolution for a list of hostnames.
.DESCRIPTION
    Resolves each hostname and outputs the result to the console and CSV.
.PARAMETER Hosts
    List of hostnames to resolve.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string[]]$Hosts = @('google.com','microsoft.com'),
    [string]$OutputCsv = 'DnsTestResults.csv'
)

$results = $Hosts | ForEach-Object {
    try {
        $res = Resolve-DnsName -Name $_ -ErrorAction Stop
        [PSCustomObject]@{ Host=$_; Status='Resolved'; Addresses=($res | Where-Object IPAddress | Select-Object -ExpandProperty IPAddress -Unique) -join ',' }
    } catch {
        [PSCustomObject]@{ Host=$_; Status='Failed'; Addresses='' }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
