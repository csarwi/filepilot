#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Deploy FilePilot configuration to a new machine
.DESCRIPTION
    Creates a symbolic link from FilePilot location pointing to the repo config
.NOTES
    Must be run as Administrator for symbolic link creation
#>

param(
    [string]$RepoPath = $PSScriptRoot,
    [string]$FilePilotPath = "$env:APPDATA\Voidstar\FilePilot"
)

Write-Host "FilePilot Configuration Deployment Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Verify source config exists
$configFile = Join-Path $RepoPath "FPilot-Config.json"
if (-not (Test-Path $configFile)) {
    Write-Error "Config file not found at: $configFile"
    exit 1
}

Write-Host "Source: $configFile" -ForegroundColor Green
Write-Host "Target: $FilePilotPath" -ForegroundColor Green

# Create FilePilot directory if needed
if (-not (Test-Path $FilePilotPath)) {
    New-Item -ItemType Directory -Path $FilePilotPath -Force | Out-Null
    Write-Host "[OK] Created FilePilot directory" -ForegroundColor Green
}

# Handle existing config file
$targetConfigFile = Join-Path $FilePilotPath "FPilot-Config.json"
if (Test-Path $targetConfigFile) {
    # Check if it's already the correct symlink
    $targetItem = Get-Item $targetConfigFile
    if (($targetItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -and ($targetItem.Target -eq $configFile)) {
        Write-Host "[OK] Symlink already exists and is correct" -ForegroundColor Green
        exit 0
    }
    
    # Backup existing file
    $backupFile = "$targetConfigFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $targetConfigFile $backupFile -Force
    Write-Host "[OK] Backed up existing config to: $backupFile" -ForegroundColor Green
    
    # Remove existing file/symlink
    Remove-Item $targetConfigFile -Force
    Write-Host "[OK] Removed existing config" -ForegroundColor Green
}

# Create symlink
try {
    New-Item -ItemType SymbolicLink -Path $targetConfigFile -Target $configFile -Force | Out-Null
    Write-Host "[OK] Created symlink: $targetConfigFile -> $configFile" -ForegroundColor Green
} catch {
    Write-Error "Failed to create symlink: $($_.Exception.Message)"
    exit 1
}

# Verify
if ((Test-Path $targetConfigFile) -and ((Get-Item $targetConfigFile).Target -eq $configFile)) {
    Write-Host "`n[SUCCESS] Deployment completed!" -ForegroundColor Cyan
    Write-Host "Config file changes in repo will now sync to FilePilot automatically." -ForegroundColor White
} else {
    Write-Error "Verification failed"
    exit 1
}
