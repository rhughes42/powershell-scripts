<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Create and manage Windows Scheduled Tasks for PowerShell scripts.
.DESCRIPTION
    Provides comprehensive interface to create, modify, delete, and monitor Windows Scheduled Tasks.
    Designed specifically for automating PowerShell script execution on schedules.
.PARAMETER Action
    Action to perform: Create, Delete, List, Run, Enable, Disable, Export, GetHistory
.PARAMETER TaskName
    Name of the scheduled task
.PARAMETER ScriptPath
    Full path to PowerShell script to execute
.PARAMETER Trigger
    When to run: Daily, Weekly, AtLogon, AtStartup, Once
.PARAMETER Time
    Time to run (format: HH:mm, e.g., "09:30")
.PARAMETER DaysOfWeek
    For Weekly trigger: Days to run (e.g., "Monday,Wednesday,Friday")
.PARAMETER RunAsUser
    User account to run task as (default: SYSTEM)
.PARAMETER RunElevated
    Run with highest privileges (default: true)
.PARAMETER OutputCsv
    Path to export task list
.EXAMPLE
    .\manage-scheduled-tasks.ps1 -Action Create -TaskName "DailyBackup" -ScriptPath "C:\Scripts\backup.ps1" -Trigger Daily -Time "02:00"
    Creates a daily task that runs backup.ps1 at 2 AM
.EXAMPLE
    .\manage-scheduled-tasks.ps1 -Action Create -TaskName "WeeklyReport" -ScriptPath "C:\Scripts\report.ps1" -Trigger Weekly -DaysOfWeek "Monday,Friday" -Time "08:00"
    Creates a weekly task that runs on Monday and Friday at 8 AM
.EXAMPLE
    .\manage-scheduled-tasks.ps1 -Action List -OutputCsv "tasks.csv"
    Lists all scheduled tasks and exports to CSV
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Create', 'Delete', 'List', 'Run', 'Enable', 'Disable', 'Export', 'GetHistory')]
    [string]$Action,
    
    [string]$TaskName,
    [string]$ScriptPath,
    [ValidateSet('Daily', 'Weekly', 'AtLogon', 'AtStartup', 'Once')]
    [string]$Trigger,
    [string]$Time,
    [string]$DaysOfWeek,
    [string]$RunAsUser = 'SYSTEM',
    [bool]$RunElevated = $true,
    [string]$OutputCsv = 'ScheduledTasks.csv'
)

#Requires -RunAsAdministrator

# Function to create a scheduled task
function New-PowerShellScheduledTask {
    param(
        [string]$Name,
        [string]$Script,
        [string]$TriggerType,
        [string]$RunTime,
        [string]$Days,
        [string]$User,
        [bool]$Elevated
    )
    
    Write-Host "Creating scheduled task: $Name" -ForegroundColor Cyan
    
    # Validate script path exists
    if (-not (Test-Path $Script)) {
        Write-Error "Script not found: $Script"
        return
    }
    
    # Build PowerShell action to execute the script
    $actionArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$Script`""
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument $actionArgs
    
    # Create trigger based on type
    $triggerObj = switch ($TriggerType) {
        'Daily' {
            if (-not $RunTime) {
                Write-Error "Time parameter required for Daily trigger"
                return
            }
            New-ScheduledTaskTrigger -Daily -At $RunTime
        }
        'Weekly' {
            if (-not $RunTime -or -not $Days) {
                Write-Error "Time and DaysOfWeek parameters required for Weekly trigger"
                return
            }
            # Parse days of week
            $daysArray = $Days -split ',' | ForEach-Object { $_.Trim() }
            New-ScheduledTaskTrigger -Weekly -DaysOfWeek $daysArray -At $RunTime
        }
        'AtLogon' {
            New-ScheduledTaskTrigger -AtLogon
        }
        'AtStartup' {
            New-ScheduledTaskTrigger -AtStartup
        }
        'Once' {
            if (-not $RunTime) {
                Write-Error "Time parameter required for Once trigger"
                return
            }
            New-ScheduledTaskTrigger -Once -At $RunTime
        }
    }
    
    # Configure task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Configure principal (user and privilege level)
    if ($Elevated) {
        $principal = New-ScheduledTaskPrincipal -UserId $User -RunLevel Highest
    }
    else {
        $principal = New-ScheduledTaskPrincipal -UserId $User -RunLevel Limited
    }
    
    # Register the task
    try {
        Register-ScheduledTask -TaskName $Name -Action $action -Trigger $triggerObj -Settings $settings -Principal $principal -Force | Out-Null
        Write-Host "Successfully created task: $Name" -ForegroundColor Green
        
        # Display task details
        $task = Get-ScheduledTask -TaskName $Name
        Write-Host "`nTask Details:" -ForegroundColor Cyan
        Write-Host "  Name: $($task.TaskName)"
        Write-Host "  State: $($task.State)"
        Write-Host "  Script: $Script"
        Write-Host "  Trigger: $TriggerType"
        Write-Host "  User: $User"
        Write-Host "  Elevated: $Elevated"
    }
    catch {
        Write-Error "Failed to create task: $_"
    }
}

# Function to get task execution history
function Get-TaskHistory {
    param([string]$Name)
    
    Write-Host "Retrieving history for task: $Name" -ForegroundColor Cyan
    
    try {
        # Query task scheduler event log for this task
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Microsoft-Windows-TaskScheduler/Operational'
            ID        = 100, 102, 103, 110, 111, 200, 201  # Task started, completed, failed, etc.
        } -MaxEvents 50 -ErrorAction Stop | 
        Where-Object { $_.Message -like "*$Name*" }
        
        if ($events) {
            $results = $events | Select-Object TimeCreated, Id, LevelDisplayName, Message | 
                Sort-Object TimeCreated -Descending
            
            $results | Format-Table -AutoSize
            Write-Host "`nEvent ID Reference:" -ForegroundColor Yellow
            Write-Host "  100 = Task Started"
            Write-Host "  102 = Task Completed"
            Write-Host "  103 = Task Failed"
            Write-Host "  110 = Task Triggered by User"
            Write-Host "  111 = Task Terminated"
            Write-Host "  200 = Task Scheduled"
            Write-Host "  201 = Task Registered"
        }
        else {
            Write-Host "No history found for task: $Name" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "Unable to retrieve task history: $_"
    }
}

# Main execution logic
switch ($Action) {
    'Create' {
        if (-not $TaskName -or -not $ScriptPath -or -not $Trigger) {
            Write-Error "TaskName, ScriptPath, and Trigger parameters are required for Create action"
            return
        }
        New-PowerShellScheduledTask -Name $TaskName -Script $ScriptPath -TriggerType $Trigger `
            -RunTime $Time -Days $DaysOfWeek -User $RunAsUser -Elevated $RunElevated
    }
    
    'Delete' {
        if (-not $TaskName) {
            Write-Error "TaskName parameter is required for Delete action"
            return
        }
        Write-Host "Deleting task: $TaskName" -ForegroundColor Cyan
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
            Write-Host "Successfully deleted task: $TaskName" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to delete task: $_"
        }
    }
    
    'List' {
        Write-Host "Retrieving all scheduled tasks..." -ForegroundColor Cyan
        $tasks = Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' -or $true } | 
            Select-Object TaskName, State, @{N='NextRunTime';E={($_ | Get-ScheduledTaskInfo).NextRunTime}}, 
                         @{N='LastRunTime';E={($_ | Get-ScheduledTaskInfo).LastRunTime}},
                         @{N='LastResult';E={($_ | Get-ScheduledTaskInfo).LastTaskResult}}
        
        $tasks | Format-Table -AutoSize
        
        if ($OutputCsv) {
            $tasks | Export-Csv -Path $OutputCsv -NoTypeInformation
            Write-Host "`nExported $($tasks.Count) tasks to $OutputCsv" -ForegroundColor Green
        }
    }
    
    'Run' {
        if (-not $TaskName) {
            Write-Error "TaskName parameter is required for Run action"
            return
        }
        Write-Host "Running task: $TaskName" -ForegroundColor Cyan
        try {
            Start-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            Write-Host "Task started successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to run task: $_"
        }
    }
    
    'Enable' {
        if (-not $TaskName) {
            Write-Error "TaskName parameter is required for Enable action"
            return
        }
        Write-Host "Enabling task: $TaskName" -ForegroundColor Cyan
        try {
            Enable-ScheduledTask -TaskName $TaskName -ErrorAction Stop | Out-Null
            Write-Host "Task enabled successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to enable task: $_"
        }
    }
    
    'Disable' {
        if (-not $TaskName) {
            Write-Error "TaskName parameter is required for Disable action"
            return
        }
        Write-Host "Disabling task: $TaskName" -ForegroundColor Cyan
        try {
            Disable-ScheduledTask -TaskName $TaskName -ErrorAction Stop | Out-Null
            Write-Host "Task disabled successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to disable task: $_"
        }
    }
    
    'Export' {
        if (-not $TaskName) {
            Write-Error "TaskName parameter is required for Export action"
            return
        }
        $exportPath = "$TaskName.xml"
        Write-Host "Exporting task definition to $exportPath" -ForegroundColor Cyan
        try {
            Export-ScheduledTask -TaskName $TaskName | Out-File -FilePath $exportPath -Encoding utf8
            Write-Host "Task exported successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to export task: $_"
        }
    }
    
    'GetHistory' {
        if (-not $TaskName) {
            Write-Error "TaskName parameter is required for GetHistory action"
            return
        }
        Get-TaskHistory -Name $TaskName
    }
}
