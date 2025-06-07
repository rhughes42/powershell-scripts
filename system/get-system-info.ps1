<#
 ▄▄ • ▄▄▄   ▄▄▄·  ▄▄▄· ▄ .▄
▐█ ▀ ▪▀▄ █·▐█ ▀█ ▐█ ▄███▪▐█
▄█ ▀█▄▐▀▀▄ ▄█▀▀█  ██▀·██▀▐█
▐█▄▪▐█▐█•█▌▐█ ▪▐▌▐█▪·•██▌▐▀
·▀▀▀▀ .▀  ▀ ▀  ▀ .▀   ▀▀▀ ·

Graph Technologies · https://graphtechnologies.xyz/
Computational Analysis & Geometry · Applied AI · Robotics

.SYNOPSIS
    Gather basic system information.
.DESCRIPTION
    Outputs OS, CPU, memory, and disk info to the console and CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'SystemInfo.csv'
)

$info = [PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    OS           = (Get-CimInstance Win32_OperatingSystem).Caption
    CPU          = (Get-CimInstance Win32_Processor).Name
    MemoryGB     = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    DiskGB       = [math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").Size / 1GB, 2)
}
$info | Format-List
$info | Export-Csv -Path $OutputCsv -NoTypeInformation
