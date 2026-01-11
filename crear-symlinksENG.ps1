# Script to create symlinks for movies scattered across multiple drives
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
    Write-Host "4. Execute: .\create-symlinks.ps1" -ForegroundColor White
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

# Valid video extensions
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

# Words in file names to ignore
$ignoredWordsInFileName = @(
    "sample"
)

# Debug mode (change to $true to see more details)
$debugMode = $false

# Function to check if a path should be ignored
function ShouldIgnore {
    param (
        [string]$filePath,
        [string]$fileName
    )
    
    try {
        # Check if the file name contains words to ignore
        foreach ($word in $ignoredWordsInFileName) {
            if ($fileName.ToLower() -like "*$word*") {
                return $true
            }
        }
        
        # Get all folders in the path
        $folders = $filePath.Split([IO.Path]::DirectorySeparatorChar)
        
        # Check if any folder in the path matches ignored ones
        foreach ($folder in $folders) {
            if ($ignoredFolders -contains $folder.ToLower()) {
                return $true
            }
        }
        
        # Check if .ignore file exists in the file's folder or parent folders
        $currentDirectory = Split-Path -LiteralPath $filePath -Parent
        
        while ($currentDirectory) {
            $ignoreFile = Join-Path $currentDirectory ".ignore"
            if (Test-Path -LiteralPath $ignoreFile -ErrorAction SilentlyContinue) {
                return $true
            }
            
            # Move up one level (stop if we reach the root)
            $parentDirectory = Split-Path -LiteralPath $currentDirectory -Parent
            if ($parentDirectory -eq $currentDirectory) {
                break
            }
            $currentDirectory = $parentDirectory
        }
        
        return $false
    } catch {
        # If there's an error checking, don't ignore the file
        return $false
    }
}

# Create destination folder if it doesn't exist
if (-not (Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Write-Host "Destination folder created: $destination" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== STARTING SYMLINK CREATION ===" -ForegroundColor Cyan
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
    
    # Search for all video files recursively
    foreach ($ext in $extensions) {
        $files = Get-ChildItem -Path $source -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            try {
                # DEBUG: Show file information
                if ($debugMode) {
                    Write-Host ""
                    Write-Host "DEBUG - Processing file:" -ForegroundColor Magenta
                    Write-Host "  Name: $($file.Name)" -ForegroundColor DarkGray
                    Write-Host "  FullName: $($file.FullName)" -ForegroundColor DarkGray
                    Write-Host "  Directory: $($file.DirectoryName)" -ForegroundColor DarkGray
                }
                
                # Verify the file still exists
                if (-not (Test-Path -LiteralPath $file.FullName)) {
                    Write-Host "  File disappeared: $($file.Name)" -ForegroundColor Magenta
                    Write-Host "    Reported path: $($file.FullName)" -ForegroundColor DarkGray
                    $ignored++
                    continue
                }
            } catch {
                Write-Host "  Error verifying existence: $($file.Name)" -ForegroundColor Magenta
                Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkGray
                $ignored++
                continue
            }
            
            # Check if should be ignored
            if (ShouldIgnore -filePath $file.FullName -fileName $file.Name) {
                Write-Host "  Ignored: $($file.Name)" -ForegroundColor DarkYellow
                $ignored++
                continue
            }
            
            try {
                # Get file name without extension
                $movieName = $file.BaseName
                
                # Create destination folder for the movie
                $movieFolder = Join-Path $destination $movieName
                
                if (-not (Test-Path -LiteralPath $movieFolder)) {
                    New-Item -ItemType Directory -Path $movieFolder -Force -ErrorAction Stop | Out-Null
                }
                
                # Full path of the symlink
                $symlinkPath = Join-Path $movieFolder $file.Name
                
                # Check if it already exists
                if (Test-Path -LiteralPath $symlinkPath) {
                    if ($debugMode) {
                        Write-Host "  Already exists: $movieName" -ForegroundColor Gray
                    }
                    $alreadyExist++
                    continue
                }
                
                # DEBUG: Show what will be created
                if ($debugMode) {
                    Write-Host "  Attempting to create symlink:" -ForegroundColor Cyan
                    Write-Host "    Target: $($file.FullName)" -ForegroundColor DarkGray
                    Write-Host "    Path: $symlinkPath" -ForegroundColor DarkGray
                }
                
                # Escape brackets in source path (fix for PowerShell bug)
                $escapedTarget = $file.FullName -replace '\[','`[' -replace '\]','`]'
                
                # Create the symlink using -Value instead of -Target (better bracket handling)
                New-Item -ItemType SymbolicLink -Path $symlinkPath -Value $escapedTarget -Force -ErrorAction Stop | Out-Null
                
                Write-Host "  Created: $movieName" -ForegroundColor Green
                
                $counter++
                
            } catch {
                Write-Host "  Error with: $($file.Name)" -ForegroundColor Red
                Write-Host "    Source path: $($file.FullName)" -ForegroundColor DarkRed
                Write-Host "    Destination folder: $movieFolder" -ForegroundColor DarkRed
                Write-Host "    Message: $($_.Exception.Message)" -ForegroundColor DarkRed
                $errors++
            }
        }
    }
}

Write-Host ""
Write-Host "=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Symlinks created: $counter" -ForegroundColor Green
Write-Host "Already existed: $alreadyExist" -ForegroundColor Gray
Write-Host "Files ignored: $ignored" -ForegroundColor Yellow
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
Write-Host "Original files have NOT been moved or copied." -ForegroundColor Yellow
Write-Host ""

# Pause to see results
Read-Host "Press Enter to exit"