<#
.SYNOPSIS
    Audit security groups/firewall rules across Azure, AWS, and GCP.
.DESCRIPTION
    Uses CLI tools to enumerate security groups/firewall rules, exports to CSV.
.PARAMETER Provider
    Cloud provider: Azure, AWS, or GCP.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [ValidateSet('Azure', 'AWS', 'GCP')][string]$Provider,
    [string]$OutputCsv = 'CloudSecurityGroupAudit.csv'
)

switch ($Provider) {
    'Azure' {
        $nsgs = az network nsg list | ConvertFrom-Json
        $results = $nsgs | Select-Object name, resourceGroup, location, securityRules
    }
    'AWS' {
        $sgs = aws ec2 describe-security-groups | ConvertFrom-Json
        $results = $sgs.SecurityGroups | Select-Object GroupName, GroupId, Description, IpPermissions
    }
    'GCP' {
        $fw = gcloud compute firewall-rules list --format=json | ConvertFrom-Json
        $results = $fw | Select-Object name, network, direction, allowed, sourceRanges
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
