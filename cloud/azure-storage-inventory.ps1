<#
.SYNOPSIS
    Inventory Azure Storage accounts and containers.
.DESCRIPTION
    Uses Azure CLI to list storage accounts and containers, exports details to CSV.
.PARAMETER SubscriptionId
    Azure subscription ID.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$SubscriptionId,
    [string]$OutputCsv = 'AzureStorageInventory.csv'
)

$accounts = az storage account list --subscription $SubscriptionId | ConvertFrom-Json
$results = @()
foreach ($acct in $accounts) {
    $containers = az storage container list --account-name $acct.name --auth-mode login | ConvertFrom-Json
    foreach ($c in $containers) {
        $results += [PSCustomObject]@{
            Account       = $acct.name
            Container     = $c.name
            Location      = $acct.location
            ResourceGroup = $acct.resourceGroup
        }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
