$ErrorActionPreference = "Stop"
$script = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts/Inspect-AdGuard.ps1"
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
$function = $ast.Find({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq "Protect-DiagnosticValue"}, $true)
if (-not $function -or $errors.Count) { throw "Redactor function missing or invalid" }
. ([scriptblock]::Create($function.Extent.Text))
$source = [ordered]@{dns_info=[pscustomobject]@{upstream_dns=@("https://FAKE_USER:FAKE_PASSWORD@dns.example.invalid/FAKE_PATH?key=FAKE_TOKEN#FAKE_FRAGMENT", "sdns://FAKE_STAMP")}}
$safe = Protect-DiagnosticValue $source
$json = $safe | ConvertTo-Json -Depth 10
$console = @($safe.dns_info.upstream_dns) -join " "
foreach ($secret in @("FAKE_USER", "FAKE_PASSWORD", "FAKE_PATH", "FAKE_TOKEN", "FAKE_FRAGMENT", "FAKE_STAMP")) {
    if ($json.Contains($secret) -or $console.Contains($secret)) { throw "Credential leaked: $secret" }
}
Write-Output "PASS: saved JSON and printed upstreams share redacted data"
