<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Advanced Windows Event Log monitoring with real-time alerts and pattern detection.
.DESCRIPTION
    Monitor Windows Event Logs in real-time, detect patterns, trigger alerts on specific events.
    Supports custom event filters, email notifications, and automated responses.
.PARAMETER Action
    Action to perform: Monitor, Search, Analyze, Export, GetStats, ListLogs
.PARAMETER LogName
    Event log name (e.g., System, Security, Application)
.PARAMETER EventIds
    Array of event IDs to monitor/search
.PARAMETER Level
    Event level: Critical, Error, Warning, Information (default: Error)
.PARAMETER Duration
    Monitoring duration in seconds (default: 300)
.PARAMETER Keywords
    Keywords to search for in event messages
.PARAMETER AlertOnMatch
    Show alert when matching events are found (default: true)
.PARAMETER OutputCsv
    Path to export results
.EXAMPLE
    .\monitor-event-logs.ps1 -Action Monitor -LogName Security -EventIds 4625,4624 -Duration 600
    Monitors Security log for logon events for 10 minutes
.EXAMPLE
    .\monitor-event-logs.ps1 -Action Search -LogName System -Level Error -Keywords "disk"
    Searches System log for disk-related errors
.EXAMPLE
    .\monitor-event-logs.ps1 -Action Analyze -LogName Application -OutputCsv "app-errors.csv"
    Analyzes Application log and exports error statistics
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Monitor', 'Search', 'Analyze', 'Export', 'GetStats', 'ListLogs')]
    [string]$Action,
    
    [string]$LogName = 'System',
    [int[]]$EventIds,
    [ValidateSet('Critical', 'Error', 'Warning', 'Information', 'Verbose')]
    [string]$Level = 'Error',
    [int]$Duration = 300,
    [string]$Keywords,
    [bool]$AlertOnMatch = $true,
    [string]$OutputCsv = 'EventLogResults.csv'
)

#Requires -RunAsAdministrator

# Function to monitor event log in real-time
function Watch-EventLog {
    param(
        [string]$Log,
        [int[]]$EventIDs,
        [string]$EventLevel,
        [int]$DurationSeconds,
        [bool]$ShowAlerts
    )
    
    Write-Host "=== Real-Time Event Log Monitoring ===" -ForegroundColor Cyan
    Write-Host "Log: $Log" -ForegroundColor Yellow
    Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor Yellow
    Write-Host "Monitoring started at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Yellow
    
    $endTime = (Get-Date).AddSeconds($DurationSeconds)
    $lastEventTime = Get-Date
    $events = @()
    
    # Build filter hashtable
    $filterHash = @{
        LogName = $Log
    }
    
    if ($EventIDs) {
        $filterHash['ID'] = $EventIDs
    }
    
    # Map level to numeric value for filtering
    $levelMap = @{
        'Critical'    = 1
        'Error'       = 2
        'Warning'     = 3
        'Information' = 4
        'Verbose'     = 5
    }
    
    if ($EventLevel -and $levelMap.ContainsKey($EventLevel)) {
        $filterHash['Level'] = $levelMap[$EventLevel]
    }
    
    Write-Host "Monitoring for events..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Gray
    
    try {
        while ((Get-Date) -lt $endTime) {
            # Query events that occurred since last check
            $newEvents = Get-WinEvent -FilterHashtable $filterHash -ErrorAction SilentlyContinue |
                Where-Object { $_.TimeCreated -gt $lastEventTime } |
                Sort-Object TimeCreated
            
            if ($newEvents) {
                foreach ($event in $newEvents) {
                    $eventInfo = [PSCustomObject]@{
                        TimeCreated  = $event.TimeCreated
                        Level        = $event.LevelDisplayName
                        EventID      = $event.Id
                        Source       = $event.ProviderName
                        Message      = $event.Message
                        Computer     = $event.MachineName
                    }
                    
                    $events += $eventInfo
                    
                    # Display alert
                    if ($ShowAlerts) {
                        $color = switch ($event.LevelDisplayName) {
                            'Critical' { 'Red' }
                            'Error' { 'Red' }
                            'Warning' { 'Yellow' }
                            default { 'White' }
                        }
                        
                        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline
                        Write-Host "[$($event.LevelDisplayName)] " -ForegroundColor $color -NoNewline
                        Write-Host "Event ID $($event.Id) - $($event.ProviderName)"
                        
                        # Show truncated message
                        if ($event.Message) {
                            $truncatedMsg = if ($event.Message.Length -gt 100) {
                                $event.Message.Substring(0, 100) + "..."
                            } else {
                                $event.Message
                            }
                        } else {
                            $truncatedMsg = "(No message)"
                        }
                        Write-Host "  $truncatedMsg" -ForegroundColor Gray
                    }
                    
                    $lastEventTime = $event.TimeCreated
                }
            }
            
            Start-Sleep -Seconds 2
        }
        
        Write-Host "`n=== Monitoring Summary ===" -ForegroundColor Cyan
        Write-Host "Total events captured: $($events.Count)" -ForegroundColor Yellow
        Write-Host "Monitoring ended at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
        
        return $events
    }
    catch {
        Write-Error "Error monitoring event log: $_"
    }
}

# Function to search event logs
function Search-EventLog {
    param(
        [string]$Log,
        [int[]]$EventIDs,
        [string]$EventLevel,
        [string]$SearchKeywords,
        [int]$MaxEvents = 1000
    )
    
    Write-Host "Searching event log: $Log" -ForegroundColor Cyan
    
    # Build filter hashtable
    $filterHash = @{
        LogName = $Log
    }
    
    if ($EventIDs) {
        $filterHash['ID'] = $EventIDs
    }
    
    $levelMap = @{
        'Critical'    = 1
        'Error'       = 2
        'Warning'     = 3
        'Information' = 4
        'Verbose'     = 5
    }
    
    if ($EventLevel -and $levelMap.ContainsKey($EventLevel)) {
        $filterHash['Level'] = $levelMap[$EventLevel]
    }
    
    try {
        # Get events
        $events = Get-WinEvent -FilterHashtable $filterHash -MaxEvents $MaxEvents -ErrorAction Stop
        
        # Filter by keywords if specified
        if ($SearchKeywords) {
            $events = $events | Where-Object { $_.Message -like "*$SearchKeywords*" }
        }
        
        Write-Host "Found $($events.Count) matching events" -ForegroundColor Yellow
        
        # Convert to custom objects
        $results = $events | Select-Object TimeCreated, LevelDisplayName, Id, ProviderName, 
                                          @{N='Message';E={
                                              if ($_.Message -and $_.Message.Length -gt 200) {
                                                  $_.Message.Substring(0, 200) + '...'
                                              } else {
                                                  $_.Message
                                              }
                                          }}
        
        return $results
    }
    catch {
        Write-Error "Error searching event log: $_"
    }
}

# Function to analyze event log statistics
function Get-EventLogStatistics {
    param([string]$Log)
    
    Write-Host "Analyzing event log: $Log" -ForegroundColor Cyan
    Write-Host "This may take a few minutes...`n" -ForegroundColor Yellow
    
    try {
        # Get all events from last 24 hours
        $startTime = (Get-Date).AddHours(-24)
        $events = Get-WinEvent -FilterHashtable @{LogName=$Log; StartTime=$startTime} -ErrorAction Stop
        
        Write-Host "=== Event Log Statistics (Last 24 Hours) ===" -ForegroundColor Yellow
        Write-Host "Log Name: $Log" -ForegroundColor Cyan
        Write-Host "Total Events: $($events.Count)" -ForegroundColor Cyan
        
        # Group by level
        Write-Host "`nEvents by Level:" -ForegroundColor Yellow
        $byLevel = $events | Group-Object -Property LevelDisplayName | Sort-Object Count -Descending
        $byLevel | Format-Table -AutoSize Name, Count
        
        # Group by source
        Write-Host "Top 10 Event Sources:" -ForegroundColor Yellow
        $bySource = $events | Group-Object -Property ProviderName | Sort-Object Count -Descending | Select-Object -First 10
        $bySource | Format-Table -AutoSize Name, Count
        
        # Group by event ID
        Write-Host "Top 10 Event IDs:" -ForegroundColor Yellow
        $byId = $events | Group-Object -Property Id | Sort-Object Count -Descending | Select-Object -First 10
        $byId | Format-Table -AutoSize Name, Count
        
        # Timeline analysis (events per hour)
        Write-Host "Events per Hour (Last 24 Hours):" -ForegroundColor Yellow
        $byHour = $events | Group-Object -Property {$_.TimeCreated.ToString('yyyy-MM-dd HH:00')} | Sort-Object Name
        $byHour | Format-Table -AutoSize Name, Count
        
        # Return structured data
        return [PSCustomObject]@{
            LogName      = $Log
            TotalEvents  = $events.Count
            ByLevel      = $byLevel
            BySource     = $bySource
            ById         = $byId
            ByHour       = $byHour
        }
    }
    catch {
        Write-Error "Error analyzing event log: $_"
    }
}

# Function to get available event logs
function Get-AvailableEventLogs {
    Write-Host "Retrieving available event logs..." -ForegroundColor Cyan
    
    try {
        $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | 
            Where-Object { $_.RecordCount -gt 0 } |
            Select-Object LogName, RecordCount, LogMode, MaximumSizeInBytes, 
                         @{N='SizeMB';E={[math]::Round($_.FileSize / 1MB, 2)}},
                         IsEnabled, LogType |
            Sort-Object RecordCount -Descending
        
        Write-Host "`nFound $($logs.Count) event logs with events" -ForegroundColor Yellow
        
        # Show top logs
        Write-Host "`nTop 20 Event Logs by Record Count:" -ForegroundColor Cyan
        $logs | Select-Object -First 20 | Format-Table -AutoSize LogName, RecordCount, SizeMB, IsEnabled
        
        return $logs
    }
    catch {
        Write-Error "Error retrieving event logs: $_"
    }
}

# Main execution logic
switch ($Action) {
    'Monitor' {
        $events = Watch-EventLog -Log $LogName -EventIDs $EventIds -EventLevel $Level `
                                 -DurationSeconds $Duration -ShowAlerts $AlertOnMatch
        
        if ($events -and $OutputCsv) {
            $events | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported $($events.Count) events to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'Search' {
        $results = Search-EventLog -Log $LogName -EventIDs $EventIds -EventLevel $Level -SearchKeywords $Keywords
        
        if ($results) {
            $results | Format-Table -AutoSize TimeCreated, LevelDisplayName, Id, ProviderName
            
            if ($OutputCsv) {
                $results | Export-Csv -Path $OutputCsv -NoTypeInformation
                Write-Host "`nExported results to $OutputCsv" -ForegroundColor Green
            }
        }
    }
    
    'Analyze' {
        $stats = Get-EventLogStatistics -Log $LogName
        
        if ($stats -and $OutputCsv) {
            # Export statistics to CSV
            $exportData = @()
            
            # Add level statistics
            foreach ($item in $stats.ByLevel) {
                $exportData += [PSCustomObject]@{
                    Category = 'Level'
                    Name = $item.Name
                    Count = $item.Count
                }
            }
            
            # Add source statistics
            foreach ($item in $stats.BySource) {
                $exportData += [PSCustomObject]@{
                    Category = 'Source'
                    Name = $item.Name
                    Count = $item.Count
                }
            }
            
            $exportData | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported statistics to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'Export' {
        Write-Host "Exporting event log: $LogName" -ForegroundColor Cyan
        
        try {
            # Export last 10000 events
            $events = Get-WinEvent -LogName $LogName -MaxEvents 10000 -ErrorAction Stop
            
            $exportData = $events | Select-Object TimeCreated, LevelDisplayName, Id, ProviderName, Message, MachineName
            
            $exportData | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "Exported $($exportData.Count) events to $OutputCsv" -ForegroundColor Green
        }
        catch {
            Write-Error "Error exporting event log: $_"
        }
    }
    
    'GetStats' {
        Get-EventLogStatistics -Log $LogName | Out-Null
    }
    
    'ListLogs' {
        $logs = Get-AvailableEventLogs
        
        if ($logs -and $OutputCsv) {
            $logs | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported log list to $OutputCsv" -ForegroundColor Green
        }
    }
}
