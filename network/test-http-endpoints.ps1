<#
.SYNOPSIS
    Test HTTP/HTTPS endpoints for status, latency, and SSL details.
.DESCRIPTION
    Sends requests to a list of URLs, measures response time, checks status code, and extracts SSL certificate info if HTTPS.
.PARAMETER Urls
    List of URLs to test.
.PARAMETER OutputCsv
    Path to export results.
#>
param(
    [string[]]$Urls = @('https://www.microsoft.com','https://expired.badssl.com'),
    [string]$OutputCsv = 'HttpEndpointResults.csv'
)

$results = @()
foreach ($url in $Urls) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $sw.Stop()
        $ssl = $null
        if ($url -like 'https://*') {
            $uri = [System.Uri]$url
            $tcp = New-Object System.Net.Sockets.TcpClient($uri.Host, $uri.Port)
            $sslStream = New-Object System.Net.Security.SslStream($tcp.GetStream(), $false, ({$true}))
            $sslStream.AuthenticateAsClient($uri.Host)
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $sslStream.RemoteCertificate
            $ssl = [PSCustomObject]@{
                Issuer = $cert.Issuer
                Subject = $cert.Subject
                Expiration = $cert.NotAfter
            }
            $sslStream.Dispose(); $tcp.Close()
        }
        $results += [PSCustomObject]@{
            Url = $url
            StatusCode = $resp.StatusCode
            LatencyMs = [math]::Round($sw.Elapsed.TotalMilliseconds,2)
            SslIssuer = $ssl?.Issuer
            SslExpiration = $ssl?.Expiration
        }
    } catch {
        $sw.Stop()
        $results += [PSCustomObject]@{
            Url = $url
            StatusCode = 'Error'
            LatencyMs = [math]::Round($sw.Elapsed.TotalMilliseconds,2)
            SslIssuer = ''
            SslExpiration = ''
        }
    }
}
$results | Format-Table -AutoSize
$results | Export-Csv -Path $OutputCsv -NoTypeInformation
