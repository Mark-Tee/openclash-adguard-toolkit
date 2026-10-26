[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Router,
    [string]$UserName = "root",
    [string]$KeyDirectory = (
        Join-Path ([IO.Path]::GetTempPath()) "openclash-adguard-optimizer"
    )
)

$ErrorActionPreference = "Stop"
$privateKey = Join-Path $KeyDirectory "id_ed25519"
$publicKey = "$privateKey.pub"
$knownHosts = Join-Path $KeyDirectory "known_hosts"

if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
    throw "OpenSSH client is not installed or ssh.exe is not in PATH."
}
if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
    throw "ssh-keygen is not installed or is not in PATH."
}

New-Item -ItemType Directory -Force -Path $KeyDirectory | Out-Null
if (-not (Test-Path -LiteralPath $privateKey)) {
    & ssh-keygen -q -t ed25519 -f $privateKey -N '""' `
        -C "codex-openclash-adguard-temporary"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create the temporary SSH key."
    }
}

$keyLine = (Get-Content -LiteralPath $publicKey -Raw).Trim()
if ($keyLine -notmatch '^ssh-ed25519\s+\S+') {
    throw "Unexpected public key format."
}

$remoteCommand = @"
umask 077
mkdir -p /root/.ssh /etc/dropbear
touch /root/.ssh/authorized_keys /etc/dropbear/authorized_keys
grep -qxF '$keyLine' /root/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '$keyLine' >> /root/.ssh/authorized_keys
grep -qxF '$keyLine' /etc/dropbear/authorized_keys 2>/dev/null || printf '%s\n' '$keyLine' >> /etc/dropbear/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys /etc/dropbear/authorized_keys
"@

Write-Host "Installing a temporary public key on $UserName@$Router."
Write-Host "Enter the router password once. The password is not stored."
& ssh -o StrictHostKeyChecking=accept-new `
    -o UserKnownHostsFile="$knownHosts" `
    "$UserName@$Router" $remoteCommand
if ($LASTEXITCODE -ne 0) {
    throw "Key installation failed."
}

$check = & ssh -i $privateKey `
    -o IdentitiesOnly=yes `
    -o BatchMode=yes `
    -o StrictHostKeyChecking=yes `
    -o UserKnownHostsFile="$knownHosts" `
    "$UserName@$Router" "uname -a"
if ($LASTEXITCODE -ne 0) {
    throw "Temporary key verification failed."
}

Write-Host "Temporary SSH access verified:"
Write-Host $check
Write-Host ""
Write-Host "Temporary material:"
Write-Host $KeyDirectory
Write-Host "Remove the local key and remote authorized-key entry after the task."
