<#
.SYNOPSIS
    Audit GCP IAM users and their roles.
.DESCRIPTION
    Uses gcloud CLI to list IAM users and their roles, exports to CSV.
.PARAMETER Project
    GCP project ID.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$Project,
    [string]$OutputCsv = 'GcpIamUserAudit.csv'
)

$members = gcloud projects get-iam-policy $Project --format=json | ConvertFrom-Json
$results = @()
foreach ($binding in $members.bindings) {
    foreach ($member in $binding.members) {
        $results += [PSCustomObject]@{
            Member = $member
            Role   = $binding.role
        }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
