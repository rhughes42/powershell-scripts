<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Simple logging utility for scripts.
.DESCRIPTION
    Writes timestamped log entries to the console and optionally to a file.
.PARAMETER Message
    The message to log.
.PARAMETER LogFile
    Optional log file path.
#>

<#
.SYNOPSIS
    Write a timestamped log entry to the console and optionally to a file.
.DESCRIPTION
    The Write-Log function formats a message with a timestamp and writes it to the console. If a log file path is provided, it also appends the entry to the file.
.PARAMETER Message
    The message to log (required).
.PARAMETER LogFile
    Optional file path to append the log entry.
.EXAMPLE
    Write-Log -Message "Script started."
    Logs the message to the console with a timestamp.
.EXAMPLE
    Write-Log -Message "Error occurred." -LogFile "C:\Logs\script.log"
    Logs the message to the console and appends it to the specified log file.
#>
function Write-Log {
    param(
        [Parameter(Mandatory)] [string]$Message,
        [string]$LogFile
    )
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Host $entry
    if ($LogFile) { $entry | Out-File -FilePath $LogFile -Append -Encoding utf8 }
}
