<#
.SYNOPSIS
    Audit AWS S3 buckets for public access and encryption.
.DESCRIPTION
    Uses AWS CLI to list S3 buckets, checks for public access and encryption, exports to CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'AwsS3BucketAudit.csv'
)

$buckets = aws s3api list-buckets | ConvertFrom-Json
$results = @()
foreach ($bucket in $buckets.Buckets) {
    $name = $bucket.Name
    $acl = aws s3api get-bucket-acl --bucket $name | ConvertFrom-Json
    $enc = aws s3api get-bucket-encryption --bucket $name 2>$null | ConvertFrom-Json
    $public = $acl.Grants | Where-Object { $_.Grantee.URI -like '*AllUsers*' }
    $encrypted = $enc.ServerSideEncryptionConfiguration.Rules.Count -gt 0
    $results += [PSCustomObject]@{
        Bucket = $name
        Public = [bool]$public
        Encrypted = $encrypted
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
