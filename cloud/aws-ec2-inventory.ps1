<#
.SYNOPSIS
    Inventory AWS EC2 instances and their properties.
.DESCRIPTION
    Uses AWS CLI to list EC2 instances, exports details to CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'AwsEc2Inventory.csv'
)

$instances = aws ec2 describe-instances | ConvertFrom-Json
$results = @()
foreach ($r in $instances.Reservations) {
    foreach ($i in $r.Instances) {
        $results += [PSCustomObject]@{
            InstanceId = $i.InstanceId
            State = $i.State.Name
            Type = $i.InstanceType
            PublicIp = $i.PublicIpAddress
            PrivateIp = $i.PrivateIpAddress
            LaunchTime = $i.LaunchTime
        }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
