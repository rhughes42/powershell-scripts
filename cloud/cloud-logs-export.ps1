<#
.SYNOPSIS
    Export logs from Azure, AWS, and GCP to CSV.
.DESCRIPTION
    Uses CLI tools to fetch recent logs/events for resources, exports to CSV.
.PARAMETER Provider
    Cloud provider: Azure, AWS, or GCP.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [ValidateSet('Azure', 'AWS', 'GCP')][string]$Provider,
    [string]$OutputCsv = 'CloudLogsExport.csv'
)

switch ($Provider) {
    'Azure' {
        $logs = az monitor activity-log list --max-events 100 | ConvertFrom-Json
        $results = $logs | Select-Object eventName, resourceGroupName, resourceId, level, eventTimestamp
    }
    'AWS' {
        $logs = aws logs describe-log-streams --log-group-name "/aws/lambda/" | ConvertFrom-Json
        $results = $logs.logStreams | Select-Object logStreamName, creationTime, lastEventTimestamp
    }
    'GCP' {
        $logs = gcloud logging read "timestamp>='$(Get-Date -Format yyyy-MM-dd)'" --limit 100 --format=json | ConvertFrom-Json
        $results = $logs | Select-Object logName, resource, severity, timestamp
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
