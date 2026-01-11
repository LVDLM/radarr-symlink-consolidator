# Script to create folder symlinks for movies scattered across multiple drives
# This version creates symlinks to entire folders (better for Radarr)
# RUN AS ADMINISTRATOR

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "ERROR: This script needs to be run as ADMINISTRATOR" -ForegroundColor Red
    Write-Host ""
    Write-Host "How to run:" -ForegroundColor Yellow
    Write-Host "1. Right-click on PowerShell" -ForegroundColor White
    Write-Host "2. Select 'Run as administrator'" -ForegroundColor White
    Write-Host "3. Navigate to the script folder: cd 'path\to\script'" -ForegroundColor White
    Write-Host "4. Execute: .\create-folder-symlinks.ps1" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit
}

# Configuration
$destination = "F:\Movies"

# List of source paths (add all your movie folders)
$sources = @(
    "I:\",
    "N:\",
    "Q:\",
    "O:\",
    "P:\",
    "R:\#Sagas",
    "S:\Filmographies",
    "T:\",
    "U:\"
)

# Valid video extensions (to identify movie folders)
$extensions = @("*.mkv", "*.mp4", "*.avi", "*.m4v", "*.mov")

# Folder names to ignore (you can add more)
$ignoredFolders = @(
    "extra",
    "extras",
    "featurettes",
    "featurette",
    "bonus",
    "behind the scenes",
    "deleted scenes",
    "interviews",
    "trailers",
    "sample",
    "samples"
)

# Debug mode (change to $true to see more details)
$debugMode = $false

# Function to check if a folder should be ignored
function ShouldIgnoreFolder {
    param (
        [string]$folderPath,
        [string]$folderName
    )
    
    try {
        # Check if folder name is in ignored list
        if ($ignoredFolders -contains $folderName.ToLower()) {
            return $true
        }
        
        # Check if .ignore file exists in the folder
        $ignoreFile = Join-Path $folderPath ".ignore"
        if (Test-Path -LiteralPath $ignoreFile -ErrorAction SilentlyContinue) {
            return $true
        }
        
        return $false
    } catch {
        return $false
    }
}

# Function to check if a folder contains video files
function ContainsVideoFiles {
    param (
        [string]$folderPath
    )
    
    try {
        foreach ($ext in $extensions) {
            $videoFiles = Get-ChildItem -LiteralPath $folderPath -Filter $ext -File -ErrorAction SilentlyContinue
            if ($videoFiles) {
                return $true
            }
        }
        return $false
    } catch {
        # If there's an error checking, assume it doesn't contain videos
        return $false
    }
}

# Create destination folder if it doesn't exist
if (-not (Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Write-Host "Destination folder created: $destination" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== STARTING FOLDER SYMLINK CREATION ===" -ForegroundColor Cyan
Write-Host "Destination: $destination" -ForegroundColor Yellow
Write-Host ""

$counter = 0
$errors = 0
$ignored = 0
$alreadyExist = 0

foreach ($source in $sources) {
    if (-not (Test-Path -LiteralPath $source)) {
        Write-Host "Path not found: $source" -ForegroundColor Yellow
        continue
    }
    
    Write-Host ""
    Write-Host "Processing: $source" -ForegroundColor Cyan
    
    # Get all folders that contain video files
    $folders = Get-ChildItem -Path $source -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
        ContainsVideoFiles -folderPath $_.FullName
    }
    
    foreach ($folder in $folders) {
        try {
            # DEBUG: Show folder information
            if ($debugMode) {
                Write-Host ""
                Write-Host "DEBUG - Processing folder:" -ForegroundColor Magenta
                Write-Host "  Name: $($folder.Name)" -ForegroundColor DarkGray
                Write-Host "  FullName: $($folder.FullName)" -ForegroundColor DarkGray
            }
            
            # Check if folder should be ignored
            if (ShouldIgnoreFolder -folderPath $folder.FullName -folderName $folder.Name) {
                Write-Host "  Ignored: $($folder.Name)" -ForegroundColor DarkYellow
                $ignored++
                continue
            }
            
            # Destination symlink path
            $symlinkPath = Join-Path $destination $folder.Name
            
            # Check if it already exists
            if (Test-Path -LiteralPath $symlinkPath) {
                if ($debugMode) {
                    Write-Host "  Already exists: $($folder.Name)" -ForegroundColor Gray
                }
                $alreadyExist++
                continue
            }
            
            # DEBUG: Show what will be created
            if ($debugMode) {
                Write-Host "  Attempting to create folder symlink:" -ForegroundColor Cyan
                Write-Host "    Target: $($folder.FullName)" -ForegroundColor DarkGray
                Write-Host "    Path: $symlinkPath" -ForegroundColor DarkGray
            }
            
            # Escape brackets in source path (fix for PowerShell bug)
            $escapedTarget = $folder.FullName -replace '\[','`[' -replace '\]','`]'
            
            # Create the directory symlink
            New-Item -ItemType SymbolicLink -Path $symlinkPath -Value $escapedTarget -Force -ErrorAction Stop | Out-Null
            
            Write-Host "  Created: $($folder.Name)" -ForegroundColor Green
            
            $counter++
            
        } catch {
            Write-Host "  Error with: $($folder.Name)" -ForegroundColor Red
            Write-Host "    Source path: $($folder.FullName)" -ForegroundColor DarkRed
            Write-Host "    Destination path: $symlinkPath" -ForegroundColor DarkRed
            Write-Host "    Message: $($_.Exception.Message)" -ForegroundColor DarkRed
            $errors++
        }
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Folder symlinks created: $counter" -ForegroundColor Green
Write-Host "Already existed: $alreadyExist" -ForegroundColor Gray
Write-Host "Folders ignored: $ignored" -ForegroundColor Yellow
if ($errors -gt 0) {
    Write-Host "Errors: $errors" -ForegroundColor Red
    Write-Host ""
    Write-Host "SUGGESTION: Change `$debugMode = `$true at the beginning of the script" -ForegroundColor Yellow
    Write-Host "to see detailed information about errors." -ForegroundColor Yellow
} else {
    Write-Host "Errors: $errors" -ForegroundColor Green
}
Write-Host ""
Write-Host "You can now configure Radarr to point to: $destination" -ForegroundColor Yellow
Write-Host "Radarr should now be able to follow the symlinks and access the files." -ForegroundColor Yellow
Write-Host ""

# Pause to see results
Read-Host "Press Enter to exit"