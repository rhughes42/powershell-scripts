<#
.SYNOPSIS
    Inventory Azure resources in a subscription or resource group.
.DESCRIPTION
    Uses Azure CLI to enumerate resources, exports details to CSV.
.PARAMETER SubscriptionId
    Azure subscription ID.
.PARAMETER ResourceGroup
    Optional resource group name.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$SubscriptionId,
    [string]$ResourceGroup,
    [string]$OutputCsv = 'AzureResourceInventory.csv'
)

$azCmd = "az resource list --subscription $SubscriptionId"
if ($ResourceGroup) { $azCmd += " --resource-group $ResourceGroup" }
$azCmd += " | ConvertFrom-Json"
$resources = Invoke-Expression $azCmd
$results = $resources | Select-Object name, type, location, resourceGroup, id
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
