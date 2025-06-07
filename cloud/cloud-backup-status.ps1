<#
.SYNOPSIS
    Check backup status for resources across Azure, AWS, and GCP.
.DESCRIPTION
    Uses CLI tools to check backup/restore points for VMs, storage, and databases, exports to CSV.
.PARAMETER Provider
    Cloud provider: Azure, AWS, or GCP.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [ValidateSet('Azure', 'AWS', 'GCP')][string]$Provider,
    [string]$OutputCsv = 'CloudBackupStatus.csv'
)

switch ($Provider) {
    'Azure' {
        $backups = az backup item list | ConvertFrom-Json
        $results = $backups | Select-Object name, resourceGroup, workloadType, lastBackupStatus, lastBackupTime
    }
    'AWS' {
        $backups = aws backup list-backup-jobs | ConvertFrom-Json
        $results = $backups.BackupJobs | Select-Object ResourceType, ResourceArn, State, CompletionDate
    }
    'GCP' {
        $backups = gcloud compute snapshots list --format=json | ConvertFrom-Json
        $results = $backups | Select-Object name, sourceDisk, status, creationTimestamp
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
