[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DnsServer,
    [string]$DomesticDomain = "www.baidu.com",
    [string]$ForeignDomain = "www.google.com",
    [string]$BlockedDomain = "doubleclick.net"
)

$ErrorActionPreference = "Stop"

function Get-Answer([string]$Domain) {
    try {
        $answers = Resolve-DnsName $Domain `
            -Server $DnsServer `
            -Type A `
            -DnsOnly `
            -ErrorAction Stop
        $addresses = @(
            $answers |
                Where-Object {
                    $_.PSObject.Properties.Name -contains "IPAddress"
                } |
                Select-Object -ExpandProperty IPAddress
        )
        [pscustomobject]@{
            Domain = $Domain
            Success = $true
            Addresses = ($addresses -join ",")
            FakeIP = [bool]($addresses | Where-Object { $_ -like "198.18.*" })
            Blocked = [bool]($addresses -contains "0.0.0.0")
        }
    }
    catch {
        [pscustomobject]@{
            Domain = $Domain
            Success = $false
            Addresses = ""
            FakeIP = $false
            Blocked = $false
            Error = $_.Exception.Message
        }
    }
}

@(
    Get-Answer $DomesticDomain
    Get-Answer $ForeignDomain
    Get-Answer $BlockedDomain
) | Format-Table Domain, Success, Addresses, FakeIP, Blocked -AutoSize

try {
    $domesticText = (curl.exe -sS --max-time 12 https://myip.ipip.net 2>&1) -join " "
    $foreignText = (curl.exe -sS --max-time 12 https://api.ipify.org 2>&1) -join " "
    $domesticIp = [regex]::Match(
        $domesticText,
        "(\d{1,3}(?:\.\d{1,3}){3})"
    ).Groups[1].Value
    $foreignIp = $foreignText.Trim()

    [pscustomobject]@{
        DomesticEndpointOK = $domesticText -match "中国|China"
        ForeignEndpointOK = $foreignIp -match "^\d{1,3}(?:\.\d{1,3}){3}$"
        DifferentEgress = [bool](
            $domesticIp -and
            $foreignIp -and
            $domesticIp -ne $foreignIp
        )
    } | Format-List
}
catch {
    Write-Warning "Public-egress comparison failed: $($_.Exception.Message)"
}
