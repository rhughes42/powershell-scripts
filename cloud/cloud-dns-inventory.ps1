<#
.SYNOPSIS
    Inventory DNS zones and records across Azure, AWS, and GCP.
.DESCRIPTION
    Uses CLI tools to enumerate DNS zones and records, exports to CSV.
.PARAMETER Provider
    Cloud provider: Azure, AWS, or GCP.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [ValidateSet('Azure','AWS','GCP')][string]$Provider,
    [string]$OutputCsv = 'CloudDnsInventory.csv'
)

switch ($Provider) {
    'Azure' {
        $zones = az network dns zone list | ConvertFrom-Json
        $results = $zones | Select-Object name, resourceGroup, numberOfRecordSets
    }
    'AWS' {
        $zones = aws route53 list-hosted-zones | ConvertFrom-Json
        $results = $zones.HostedZones | Select-Object Name, Id, ResourceRecordSetCount
    }
    'GCP' {
        $zones = gcloud dns managed-zones list --format=json | ConvertFrom-Json
        $results = $zones | Select-Object name, dnsName, description
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
