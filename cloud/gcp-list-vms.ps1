<#
.SYNOPSIS
    List Google Cloud VMs in a project.
.DESCRIPTION
    Uses gcloud CLI to enumerate Compute Engine VMs, exports details to CSV.
.PARAMETER Project
    GCP project ID.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$Project,
    [string]$OutputCsv = 'GcpVmList.csv'
)

$vms = gcloud compute instances list --project $Project --format=json | ConvertFrom-Json
$results = $vms | Select-Object name, zone, status, machineType, networkInterfaces
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
