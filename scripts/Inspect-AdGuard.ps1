[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
    [string]$UserName = "admin",
    [string]$OutputDirectory = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$BaseUrl = $BaseUrl.TrimEnd("/")
$securePassword = Read-Host "AdGuard Home password for $UserName" -AsSecureString
$passwordPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

$snapshot = [ordered]@{
    collected_at = (Get-Date).ToString("o")
    base_url = $BaseUrl
}

try {
    $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPtr)
    $loginBody = @{
        name = $UserName
        password = $password
    } | ConvertTo-Json -Compress

    Invoke-WebRequest -Uri "$BaseUrl/control/login" -Method Post `
        -ContentType "application/json" -Body $loginBody `
        -SessionVariable session -UseBasicParsing -TimeoutSec 15 | Out-Null

    $targets = [ordered]@{
        version = "/control/version.json"
        status = "/control/status"
        dns_info = "/control/dns_info"
        filtering = "/control/filtering/status"
        safesearch = "/control/safesearch/status"
    }
    foreach ($entry in $targets.GetEnumerator()) {
        try {
            $snapshot[$entry.Key] = Invoke-RestMethod `
                -Uri ($BaseUrl + $entry.Value) `
                -WebSession $session `
                -TimeoutSec 15
        }
        catch {
            $snapshot[$entry.Key] = @{ error = $_.Exception.Message }
        }
    }
}
finally {
    if ($passwordPtr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPtr)
    }
    $password = $null
    $loginBody = $null
}

function Protect-DiagnosticValue($Value) {
    if ($null -eq $Value) { return $null }
    if ($Value -is [string]) {
        return [regex]::Replace($Value, '(?i)\b(?:https?|tls|quic|h3|tcp|udp|sdns)://[^\s"<>]+', {
            param($Match)
            try {
                $uri = [uri]$Match.Value
                if ($uri.Scheme -eq 'sdns') { return 'sdns://***' }
                $safe = $uri.GetComponents([UriComponents]::SchemeAndServer, [UriFormat]::UriEscaped)
                if ($uri.AbsolutePath -notin @('', '/')) { $safe += '/***' }
                elseif ($uri.AbsolutePath -eq '/') { $safe += '/' }
                if ($uri.Query) { $safe += '?***' }
                if ($uri.Fragment) { $safe += '#***' }
                return $safe
            } catch { return '<redacted-url>' }
        })
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $safe = [ordered]@{}
        foreach ($key in $Value.Keys) { $safe[$key] = Protect-DiagnosticValue $Value[$key] }
        return $safe
    }
    if ($Value -is [array]) { return ,@($Value | ForEach-Object { Protect-DiagnosticValue $_ }) }
    if ($Value -is [pscustomobject]) {
        $safe = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) { $safe[$property.Name] = Protect-DiagnosticValue $property.Value }
        return $safe
    }
    return $Value
}

$snapshot = Protect-DiagnosticValue $snapshot
$json = $snapshot | ConvertTo-Json -Depth 20
$json = [regex]::Replace($json, '(?i)(https?://)[^/"\s]+@', '$1***@')
$json = [regex]::Replace(
    $json,
    '(?i)([?&](?:token|key|secret|password)=)[^&"\s]+',
    '$1***'
)

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputPath = Join-Path $OutputDirectory "adguard_snapshot_$timestamp.json"
[IO.File]::WriteAllText(
    $outputPath,
    $json,
    [Text.UTF8Encoding]::new($false)
)

Write-Host "Read-only AdGuard snapshot saved to:"
Write-Host $outputPath
Write-Host ""
Write-Host "Upstream DNS:"
$upstreams = $snapshot.dns_info.upstream_dns
if ($null -eq $upstreams) {
    Write-Host "Unavailable"
}
else {
    $upstreams | ForEach-Object { Write-Host "- $_" }
}
