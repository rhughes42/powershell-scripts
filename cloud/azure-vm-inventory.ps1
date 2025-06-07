<#
.SYNOPSIS
    Inventory Azure VMs and their properties.
.DESCRIPTION
    Uses Azure CLI to list VMs, exports details to CSV.
.PARAMETER SubscriptionId
    Azure subscription ID.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$SubscriptionId,
    [string]$OutputCsv = 'AzureVmInventory.csv'
)

$vms = az vm list --subscription $SubscriptionId --show-details | ConvertFrom-Json
$results = $vms | Select-Object name, resourceGroup, location, powerState, osType, publicIps, privateIps
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
