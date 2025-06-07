<#
.SYNOPSIS
    Audit resource tags/labels across Azure, AWS, and GCP.
.DESCRIPTION
    Uses CLI tools to enumerate resource tags/labels, exports to CSV.
.PARAMETER Provider
    Cloud provider: Azure, AWS, or GCP.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [ValidateSet('Azure','AWS','GCP')][string]$Provider,
    [string]$OutputCsv = 'CloudTagAudit.csv'
)

switch ($Provider) {
    'Azure' {
        $resources = az resource list | ConvertFrom-Json
        $results = $resources | Select-Object name, resourceGroup, tags
    }
    'AWS' {
        $resources = aws resourcegroupstaggingapi get-resources | ConvertFrom-Json
        $results = $resources.ResourceTagMappingList | Select-Object ResourceARN, Tags
    }
    'GCP' {
        $resources = gcloud resource-manager tags bindings list --format=json | ConvertFrom-Json
        $results = $resources | Select-Object tagValue, resource
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
