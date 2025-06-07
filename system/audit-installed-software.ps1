<#
.SYNOPSIS
    Audit installed software and versions on Windows.
.DESCRIPTION
    Enumerates installed programs from registry and WMI, outputs to console and CSV.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string]$OutputCsv = 'InstalledSoftware.csv'
)

$regPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$results = @()
foreach ($path in $regPaths) {
    $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
    foreach ($item in $items) {
        if ($item.DisplayName) {
            $results += [PSCustomObject]@{
                Name = $item.DisplayName
                Version = $item.DisplayVersion
                Publisher = $item.Publisher
                InstallDate = $item.InstallDate
                Source = 'Registry'
            }
        }
    }
}
# Add WMI results
$wmi = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue
foreach ($app in $wmi) {
    $results += [PSCustomObject]@{
        Name = $app.Name
        Version = $app.Version
        Publisher = $app.Vendor
        InstallDate = $app.InstallDate
        Source = 'WMI'
    }
}
$results | Sort-Object Name | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
