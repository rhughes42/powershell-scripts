<#
.SYNOPSIS
    Automated test suite for cloud inventory scripts.
.DESCRIPTION
    Runs a series of cloud inventory and audit scripts, checks for expected output files.
#>
& ./azure-resource-inventory.ps1 -SubscriptionId '00000000-0000-0000-0000-000000000000' -OutputCsv 'test_azres_out.csv'
& ./aws-s3-bucket-audit.ps1 -OutputCsv 'test_awss3_out.csv'
& ./gcp-list-vms.ps1 -Project 'my-gcp-project' -OutputCsv 'test_gcpvm_out.csv'
if (Test-Path 'test_azres_out.csv' -and Test-Path 'test_awss3_out.csv' -and Test-Path 'test_gcpvm_out.csv') {
    Write-Host 'Cloud inventory suite passed.'
}
else {
    Write-Host 'Cloud inventory suite failed.'
}
