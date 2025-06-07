<#
.SYNOPSIS
    Audit GCP storage buckets for public access and encryption.
.DESCRIPTION
    Uses gcloud CLI to list buckets, checks for public access and encryption, exports to CSV.
.PARAMETER Project
    GCP project ID.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$Project,
    [string]$OutputCsv = 'GcpStorageBucketAudit.csv'
)

$buckets = gcloud storage buckets list --project $Project --format=json | ConvertFrom-Json
$results = @()
foreach ($bucket in $buckets) {
    $acl = gcloud storage buckets get-iam-policy $bucket.name --project $Project --format=json | ConvertFrom-Json
    $public = $acl.bindings | Where-Object { $_.members -contains 'allUsers' }
    $encrypted = $bucket.encryption -ne $null
    $results += [PSCustomObject]@{
        Bucket = $bucket.name
        Public = [bool]$public
        Encrypted = $encrypted
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
