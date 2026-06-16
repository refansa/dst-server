#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "Created .env from .env.example. Edit .env with your cluster token, then re-run setup.ps1."
    exit 1
}

$envVars = Get-Content .env | Where-Object { $_ -match '^\s*[^#]' -and $_ -match '=' }
foreach ($line in $envVars) {
    $kv = $line -split '=', 2
    Set-Item -Path "env:$($kv[0].Trim())" -Value $kv[1].Trim()
}

$token = $env:CLUSTER_TOKEN
$placeholder = 'pds-g^XXXXXXXXX-YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY='

if (-not $token -or $token -eq $placeholder) {
    Write-Host "ERROR: CLUSTER_TOKEN is not set or still has the placeholder value."
    Write-Host "Edit .env with your real token from https://accounts.klei.com/account/game/servers?game=DontStarveTogether"
    exit 1
}

# Write cluster_token.txt (no trailing newline)
[System.IO.File]::WriteAllText("$PWD\data\save\Cluster_1\cluster_token.txt", $token)
Write-Host "✓ cluster_token.txt written"

# Inject cluster_name
$clusterIni = "$PWD\data\save\Cluster_1\cluster.ini"
$name = $env:CLUSTER_NAME
if ($name) {
    (Get-Content $clusterIni) -replace '^cluster_name =.*', "cluster_name = $name" | Set-Content $clusterIni
    Write-Host "✓ cluster_name set to: $name"
}

# Inject cluster_password
$pass = $env:CLUSTER_PASSWORD
if ($pass) {
    (Get-Content $clusterIni) -replace '^cluster_password =.*', "cluster_password = $pass" | Set-Content $clusterIni
    Write-Host "✓ cluster_password set"
}

Write-Host ""
Write-Host "All done! Start the server with:"
Write-Host "  docker compose up -d"
Write-Host ""
Write-Host "To update mods, edit data/mods/dedicated_server_mods_setup.lua then:"
Write-Host "  docker compose --profile mod-update run --rm dst-mod-updater"
