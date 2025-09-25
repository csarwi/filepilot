#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Deploy FilePilot configuration to a new machine
.DESCRIPTION
    This script sets up FilePilot configuration by:
    1. Creating the FilePilot directory structure
    2. Copying the config file from the repo to the FilePilot location
    3. Creating a symbolic link from the repo back to the FilePilot location
.NOTES
    Must be run as Administrator for symbolic link creation
#>

param(
    [string]$RepoPath = $PSScriptRoot,
    [string]$FilePilotPath = "$env:APPDATA\Roaming\Voidstar\FilePilot"
)

Write-Host "FilePilot Configuration Deployment Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator to create symbolic links!"
    Write-Host "Please restart PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

# Verify source files exist
$configFile = Join-Path $RepoPath "FPilot-Config.json"
if (-not (Test-Path $configFile)) {
    Write-Error "Config file not found at: $configFile"
    Write-Host "Make sure you're running this script from the filepilot repository directory." -ForegroundColor Yellow
    exit 1
}

Write-Host "Source repository: $RepoPath" -ForegroundColor Green
Write-Host "Target FilePilot directory: $FilePilotPath" -ForegroundColor Green

# Create FilePilot directory if it doesn't exist
Write-Host "`nCreating FilePilot directory..." -ForegroundColor Yellow
if (-not (Test-Path $FilePilotPath)) {
    try {
        New-Item -ItemType Directory -Path $FilePilotPath -Force | Out-Null
        Write-Host "✓ Created directory: $FilePilotPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create directory: $FilePilotPath"
        Write-Error $_.Exception.Message
        exit 1
    }
} else {
    Write-Host "✓ Directory already exists: $FilePilotPath" -ForegroundColor Green
}

# Target config file path
$targetConfigFile = Join-Path $FilePilotPath "FPilot-Config.json"

# Check if target config already exists and create backup
if (Test-Path $targetConfigFile) {
    $backupFile = "$targetConfigFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "`nBacking up existing config..." -ForegroundColor Yellow
    try {
        Copy-Item $targetConfigFile $backupFile -Force
        Write-Host "✓ Backup created: $backupFile" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create backup of existing config file"
        Write-Error $_.Exception.Message
        exit 1
    }
    
    # Remove existing file (it might be a symlink)
    try {
        Remove-Item $targetConfigFile -Force
        Write-Host "✓ Removed existing config file" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to remove existing config file"
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Check if repo config is a symlink (running on original machine)
$repoConfigItem = Get-Item $configFile
if ($repoConfigItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    Write-Host "`nRepo config is a symbolic link, copying target file..." -ForegroundColor Yellow
    # Read the actual content through the symlink
    try {
        Copy-Item $configFile $targetConfigFile -Force
        Write-Host "✓ Copied config through symbolic link" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to copy config file through symbolic link"
        Write-Error $_.Exception.Message
        exit 1
    }
} else {
    # Copy the config file from repo to FilePilot location
    Write-Host "`nCopying config file to FilePilot location..." -ForegroundColor Yellow
    try {
        Copy-Item $configFile $targetConfigFile -Force
        Write-Host "✓ Copied: $configFile → $targetConfigFile" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to copy config file"
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Remove the repo config file if it's not already a symlink
if (-not ($repoConfigItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
    Write-Host "`nRemoving repo config file to prepare for symbolic link..." -ForegroundColor Yellow
    try {
        Remove-Item $configFile -Force
        Write-Host "✓ Removed repo config file" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to remove repo config file"
        Write-Error $_.Exception.Message
        exit 1
    }
}

# Create symbolic link from repo to FilePilot location
Write-Host "`nCreating symbolic link..." -ForegroundColor Yellow
try {
    $result = cmd /c "mklink `"$configFile`" `"$targetConfigFile`"" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Created symbolic link: $configFile → $targetConfigFile" -ForegroundColor Green
    } else {
        throw "mklink failed with exit code $LASTEXITCODE`: $result"
    }
}
catch {
    Write-Error "Failed to create symbolic link"
    Write-Error $_.Exception.Message
    exit 1
}

# Verify the setup
Write-Host "`nVerifying setup..." -ForegroundColor Yellow
if ((Test-Path $configFile) -and (Test-Path $targetConfigFile)) {
    $repoItem = Get-Item $configFile
    if ($repoItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Write-Host "✓ Symbolic link verified" -ForegroundColor Green
        Write-Host "✓ Target file exists" -ForegroundColor Green
        Write-Host "`n🎉 Deployment completed successfully!" -ForegroundColor Cyan
        Write-Host "`nFilePilot configuration is now synchronized between:" -ForegroundColor White
        Write-Host "  • Repository: $configFile" -ForegroundColor Gray
        Write-Host "  • FilePilot:  $targetConfigFile" -ForegroundColor Gray
        Write-Host "`nAny changes to either file will be reflected in both locations." -ForegroundColor White
    } else {
        Write-Error "Symbolic link was not created properly"
        exit 1
    }
} else {
    Write-Error "Setup verification failed - files not found"
    exit 1
}