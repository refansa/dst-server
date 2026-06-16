#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a compressed backup of the DST world save and prunes old backups.

.DESCRIPTION
    Connects to the running dst-master container, triggers c_save() to flush
    the world state to disk, then snapshots the entire Cluster_1 directory
    into a versioned ZIP archive. Old backups are automatically pruned based
    on retention policy.

.PARAMETER BackupDir
    Directory to store backup archives. Default: ./data/backups

.PARAMETER RetentionDays
    Delete backups older than this many days. Default: 14
    Ignored when -RetentionCount is also provided.

.PARAMETER RetentionCount
    Keep at most this many most-recent backups. Default: 30
    Takes precedence over -RetentionDays when both are set.

.PARAMETER SkipSave
    Skip the c_save() command. Useful when the server is stopped or
    unresponsive and you need a backup of whatever is on disk.

.PARAMETER WhatIf
    Show what would be done without actually creating a backup archive.

.EXAMPLE
    # Create a backup with defaults (14-day retention, 30-backup cap)
    .\scripts\backup-world.ps1

.EXAMPLE
    # Keep backups for 7 days, cap at 10
    .\scripts\backup-world.ps1 -RetentionDays 7 -RetentionCount 10

.EXAMPLE
    # Dry run — preview what would happen
    .\scripts\backup-world.ps1 -WhatIf

.EXAMPLE
    # Emergency backup without triggering c_save()
    .\scripts\backup-world.ps1 -SkipSave

.NOTES
    Author: refansa
    Requires: Docker, PowerShell 7+
#>

param(
    [string]$BackupDir,
    [int]$RetentionDays = 14,
    [int]$RetentionCount = 30,
    [switch]$SkipSave,
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# ── Resolve paths ─────────────────────────────────────
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $BackupDir) {
    $BackupDir = Join-Path $ProjectRoot 'data\backups'
}
$ClusterDir = Join-Path $ProjectRoot 'data\save\Cluster_1'
$MasterContainer = 'dst-master'
$CavesContainer = 'dst-caves'

Write-Host "Project root : $ProjectRoot"
Write-Host "Backup dir   : $BackupDir"
Write-Host "Cluster dir  : $ClusterDir"
Write-Host ""

# ── Pre-flight checks ─────────────────────────────────
if (-not (Test-Path $ClusterDir)) {
    Write-Error "Cluster directory not found: $ClusterDir"
    exit 1
}

if (-not $WhatIf) {
    $null = New-Item -ItemType Directory -Path $BackupDir -Force
}

# Check Docker
$dockerOk = $true
try {
    $null = docker info --format '{{.ServerVersion}}' 2>&1 | Out-Null
} catch {
    $dockerOk = $false
}

if (-not $dockerOk) {
    Write-Warning "Docker is not running. Proceeding with disk-only backup."
}

# Check containers are up (non-fatal)
$masterRunning = $false
if ($dockerOk) {
    try {
        $state = docker inspect -f '{{.State.Status}}' $MasterContainer 2>&1
        if ($state -eq 'running') { $masterRunning = $true }
    } catch { }
}

# ── Step 1: Trigger c_save() ──────────────────────────
if (-not $SkipSave -and $masterRunning) {
    Write-Host "[1/4] Triggering c_save() on $MasterContainer ..."
    $saveResult = docker exec -i $MasterContainer sh -c 'echo "c_save()" > /proc/1/fd/0' 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  c_save() sent. Waiting 5 seconds for disk flush ..."
        Start-Sleep -Seconds 5
    } else {
        Write-Warning "  c_save() command may have failed. Proceeding anyway."
    }
} elseif ($SkipSave) {
    Write-Host "[1/4] Skipping c_save() ( -SkipSave )"
} else {
    Write-Warning "[1/4] Container $MasterContainer is not running. Skipping c_save()."
}

# ── Step 2: Create backup archive ─────────────────────
$Timestamp = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$ArchiveName = "Cluster_1-$Timestamp.zip"
$ArchivePath = Join-Path $BackupDir $ArchiveName

if ($WhatIf) {
    Write-Host "[2/4] Would create: $ArchivePath"
    Write-Host "       (excluding backup\, server_temp\, and session temp files)"
} else {
    Write-Host "[2/4] Creating archive: $ArchiveName ..."

    $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "dst-backup-$PID"
    $TempCluster = Join-Path $TempDir 'Cluster_1'

    try {
        # Stage a clean copy (exclude server-rotated backups and temp data)
        $excludePatterns = @(
            'backup\*', 'backup\**\*',
            'server_temp\*', 'server_temp\**\*',
            '*.old'
        )

        $stagingParams = @{
            Path        = $ClusterDir
            Destination = $TempDir
            Container   = $true
            Force       = $true
        }

        Robocopy $ClusterDir $TempCluster /MIR /NDL /NJH /NJS /NFL /NP `
            /XD backup server_temp session 2>&1 | Out-Null

        # Manually copy session/ but exclude server_temp/
        if (Test-Path "$ClusterDir\Master\save\session") {
            Robocopy "$ClusterDir\Master\save\session" "$TempCluster\Master\save\session" /MIR /NDL /NJH /NJS /NFL /NP 2>&1 | Out-Null
        }
        if (Test-Path "$ClusterDir\Caves\save\session") {
            Robocopy "$ClusterDir\Caves\save\session" "$TempCluster\Caves\save\session" /MIR /NDL /NJH /NJS /NFL /NP 2>&1 | Out-Null
        }

        # Create the ZIP
        $compressParams = @{
            Path             = $TempCluster
            DestinationPath  = $ArchivePath
            CompressionLevel = 'Optimal'
        }
        Compress-Archive @compressParams

        # Validate ZIP integrity
        Write-Host "  Validating archive integrity ..."
        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
            $entryCount = $zip.Entries.Count
            $zip.Dispose()
            Write-Host "  OK — $entryCount entries"
        } catch {
            Write-Error "  Archive validation FAILED: $_"
            Remove-Item -LiteralPath $ArchivePath -Force -ErrorAction SilentlyContinue
            exit 1
        }

        $size = (Get-Item $ArchivePath).Length / 1MB
        Write-Host "  Archive size: $([math]::Round($size, 2)) MB"
    } finally {
        # Clean up temp directory
        if (Test-Path $TempDir) {
            Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
        }
    }
}

# ── Step 3: Prune old backups ─────────────────────────
Write-Host "[3/4] Pruning old backups (keep: $RetentionCount, max age: $RetentionDays days) ..."
$existingBackups = @(Get-ChildItem -LiteralPath $BackupDir -Filter 'Cluster_1-*.zip' | Sort-Object LastWriteTime -Descending)

if ($existingBackups.Count -eq 0) {
    Write-Host "  No existing backups to prune."
} else {
    $toDelete = @()
    $countKeep = 0

    foreach ($backup in $existingBackups) {
        $ageDays = ((Get-Date) - $backup.LastWriteTime).TotalDays
        $countKeep++

        if ($countKeep -gt $RetentionCount -or $ageDays -gt $RetentionDays) {
            $toDelete += $backup
        }
    }

    if ($toDelete.Count -eq 0) {
        Write-Host "  Nothing to prune (all within retention policy)."
    } else {
        foreach ($f in $toDelete) {
            if ($WhatIf) {
                Write-Host "  Would delete: $($f.Name)"
            } else {
                Remove-Item -LiteralPath $f.FullName -Force
                Write-Host "  Deleted: $($f.Name)"
            }
        }
    }
}

# ── Step 4: Summary ──────────────────────────────────
Write-Host ""
Write-Host "[4/4] Summary"
Write-Host "  Backup  : $(if ($WhatIf) { 'DRY RUN — no file created' } else { $ArchivePath })"
Write-Host "  Retention: $RetentionCount most recent"
if (-not $RetentionDays -or $RetentionDays -le 0) {
    Write-Host "  Max age : no limit"
} else {
    Write-Host "  Max age : $RetentionDays days"
}
Write-Host ""

if (-not $WhatIf) {
    $remaining = @(Get-ChildItem -LiteralPath $BackupDir -Filter 'Cluster_1-*.zip')
    Write-Host "  Total backups on disk: $($remaining.Count)"
}

Write-Host ""

if ($WhatIf) {
    Write-Host "Dry run complete. Pass data to create the backup."
} else {
    Write-Host "Backup complete."
}
