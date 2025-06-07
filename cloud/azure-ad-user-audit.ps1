<#
.SYNOPSIS
    Audit Azure AD users for MFA and last login.
.DESCRIPTION
    Uses AzureAD module to list users, checks MFA status and last login, exports to CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'AzureAdUserAudit.csv'
)

Connect-AzureAD | Out-Null
$users = Get-AzureADUser -All $true
$results = @()
foreach ($user in $users) {
    $mfa = (Get-AzureADUserAuthenticationMethods -ObjectId $user.ObjectId | Where-Object { $_.Type -eq 'MicrosoftAuthenticator' })
    $lastLogin = $user.LastLogonDateTime
    $results += [PSCustomObject]@{
        UserPrincipalName = $user.UserPrincipalName
        MFAEnabled        = [bool]$mfa
        LastLogin         = $lastLogin
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
