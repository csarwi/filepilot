# FilePilot Configuration

This repository contains FilePilot configuration files that are symbolically linked to the actual configuration directory.

## Files

- `FPilot-Config.json` - Main configuration file (symlinked to `%APPDATA%\Roaming\Voidstar\FilePilot\FPilot-Config.json`)

## Backup

A backup of the original config file has been created at:
`%APPDATA%\Roaming\Voidstar\FilePilot\FPilot-Config.json.backup`

## Deployment

To deploy this configuration to a new machine:

1. Clone this repository:
   ```powershell
   git clone https://github.com/csarwi/filepilot.git
   cd filepilot
   ```

2. Run the deployment script as Administrator:
   ```powershell
   # Right-click PowerShell and "Run as Administrator"
   .\deploy.ps1
   ```

The deployment script will:
- Create the FilePilot directory structure if it doesn't exist
- Backup any existing configuration
- Copy the config file to the proper FilePilot location
- Create a symbolic link to keep the repository synchronized

## Usage

Any changes made to the files in this repository will be immediately reflected in the FilePilot application, and vice versa, due to the symbolic links.
