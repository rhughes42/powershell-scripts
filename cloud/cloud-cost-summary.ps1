<#
.SYNOPSIS
    Summarize cloud costs for Azure, AWS, and GCP.
.DESCRIPTION
    Uses CLI tools to fetch and summarize cost data, exports to CSV.
.PARAMETER Provider
    Cloud provider: Azure, AWS, or GCP.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [ValidateSet('Azure', 'AWS', 'GCP')][string]$Provider,
    [string]$OutputCsv = 'CloudCostSummary.csv'
)

switch ($Provider) {
    'Azure' {
        $costs = az consumption usage list | ConvertFrom-Json
        $results = $costs | Select-Object usageStart, usageEnd, instanceName, pretaxCost
    }
    'AWS' {
        $costs = aws ce get-cost-and-usage --time-period Start=$(Get-Date -Format yyyy-MM-01), End=$(Get-Date -Format yyyy-MM-dd) --granularity MONTHLY --metrics "UnblendedCost" | ConvertFrom-Json
        $results = $costs.ResultsByTime | Select-Object TimePeriod, Total
    }
    'GCP' {
        $costs = gcloud billing accounts list | ConvertFrom-Json
        $results = $costs | Select-Object name, open, displayName
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
