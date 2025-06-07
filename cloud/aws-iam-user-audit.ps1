<#
.SYNOPSIS
    Audit AWS IAM users for MFA and last activity.
.DESCRIPTION
    Uses AWS CLI to list IAM users, checks MFA status and last activity, exports to CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'AwsIamUserAudit.csv'
)

$users = aws iam list-users | ConvertFrom-Json
$results = @()
foreach ($user in $users.Users) {
    $mfa = aws iam list-mfa-devices --user-name $user.UserName | ConvertFrom-Json
    $last = aws iam get-user --user-name $user.UserName | ConvertFrom-Json
    $results += [PSCustomObject]@{
        UserName = $user.UserName
        MFAEnabled = ($mfa.MFADevices.Count -gt 0)
        LastActivity = $last.User.PasswordLastUsed
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
