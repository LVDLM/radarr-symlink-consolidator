# Script para crear symlinks de carpetas de películas dispersas en varios discos
# Esta versión crea symlinks a carpetas completas (mejor para Radarr)
# EJECUTAR COMO ADMINISTRADOR

# Verificar si se está ejecutando como administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "ERROR: Este script necesita ejecutarse como ADMINISTRADOR" -ForegroundColor Red
    Write-Host ""
    Write-Host "Cómo ejecutar:" -ForegroundColor Yellow
    Write-Host "1. Click derecho en PowerShell" -ForegroundColor White
    Write-Host "2. Seleccionar 'Ejecutar como administrador'" -ForegroundColor White
    Write-Host "3. Navegar a la carpeta del script: cd 'ruta\del\script'" -ForegroundColor White
    Write-Host "4. Ejecutar: .\create-folder-symlinks.ps1" -ForegroundColor White
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit
}

# Configuración (carpeta de destino de los enlaces)
$destination = "F:\Cine"

# Lista de rutas origen (agrega todas tus carpetas con películas)
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

# Extensiones de video válidas (para identificar carpetas con películas)
$extensions = @("*.mkv", "*.mp4", "*.avi", "*.m4v", "*.mov")

# Nombres de carpetas a ignorar (puedes agregar más)
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

# Modo debug (cambiar a $true para ver más detalles)
$debugMode = $false

# Función para verificar si una carpeta debe ser ignorada
function ShouldIgnoreFolder {
    param (
        [string]$folderPath,
        [string]$folderName
    )
    
    try {
        # Verificar si el nombre de la carpeta está en la lista de ignorados
        if ($ignoredFolders -contains $folderName.ToLower()) {
            return $true
        }
        
        # Verificar si existe archivo .ignore en la carpeta
        $ignoreFile = Join-Path $folderPath ".ignore"
        if (Test-Path -LiteralPath $ignoreFile -ErrorAction SilentlyContinue) {
            return $true
        }
        
        return $false
    } catch {
        return $false
    }
}

# Función para verificar si una carpeta contiene archivos de video
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
        # Si hay error al verificar, asumir que no contiene videos
        return $false
    }
}

# Crear carpeta destino si no existe
if (-not (Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Write-Host "Carpeta destino creada: $destination" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== INICIANDO CREACIÓN DE SYMLINKS DE CARPETAS ===" -ForegroundColor Cyan
Write-Host "Destino: $destination" -ForegroundColor Yellow
Write-Host ""

$counter = 0
$errors = 0
$ignored = 0
$alreadyExist = 0

foreach ($source in $sources) {
    if (-not (Test-Path -LiteralPath $source)) {
        Write-Host "Ruta no encontrada: $source" -ForegroundColor Yellow
        continue
    }
    
    Write-Host ""
    Write-Host "Procesando: $source" -ForegroundColor Cyan
    
    # Obtener todas las carpetas que contienen archivos de video
    $folders = Get-ChildItem -Path $source -Directory -Recurse -ErrorAction SilentlyContinue | Where-Object {
        ContainsVideoFiles -folderPath $_.FullName
    }
    
    foreach ($folder in $folders) {
        try {
            # DEBUG: Mostrar información de la carpeta
            if ($debugMode) {
                Write-Host ""
                Write-Host "DEBUG - Procesando carpeta:" -ForegroundColor Magenta
                Write-Host "  Nombre: $($folder.Name)" -ForegroundColor DarkGray
                Write-Host "  FullName: $($folder.FullName)" -ForegroundColor DarkGray
            }
            
            # Verificar si la carpeta debe ser ignorada
            if (ShouldIgnoreFolder -folderPath $folder.FullName -folderName $folder.Name) {
                Write-Host "  Ignorado: $($folder.Name)" -ForegroundColor DarkYellow
                $ignored++
                continue
            }
            
            # Ruta del symlink de destino
            $symlinkPath = Join-Path $destination $folder.Name
            
            # Verificar si ya existe
            if (Test-Path -LiteralPath $symlinkPath) {
                if ($debugMode) {
                    Write-Host "  Ya existe: $($folder.Name)" -ForegroundColor Gray
                }
                $alreadyExist++
                continue
            }
            
            # DEBUG: Mostrar lo que se va a crear
            if ($debugMode) {
                Write-Host "  Intentando crear symlink de carpeta:" -ForegroundColor Cyan
                Write-Host "    Target: $($folder.FullName)" -ForegroundColor DarkGray
                Write-Host "    Path: $symlinkPath" -ForegroundColor DarkGray
            }
            
            # Escapar corchetes en la ruta de origen (fix para bug de PowerShell)
            $escapedTarget = $folder.FullName -replace '\[','`[' -replace '\]','`]'
            
            # Crear el symlink de directorio
            New-Item -ItemType SymbolicLink -Path $symlinkPath -Value $escapedTarget -Force -ErrorAction Stop | Out-Null
            
            Write-Host "  Creado: $($folder.Name)" -ForegroundColor Green
            
            $counter++
            
        } catch {
            Write-Host "  Error con: $($folder.Name)" -ForegroundColor Red
            Write-Host "    Ruta origen: $($folder.FullName)" -ForegroundColor DarkRed
            Write-Host "    Ruta destino: $symlinkPath" -ForegroundColor DarkRed
            Write-Host "    Mensaje: $($_.Exception.Message)" -ForegroundColor DarkRed
            $errors++
        }
    }
}

Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Symlinks de carpetas creados: $counter" -ForegroundColor Green
Write-Host "Ya existían: $alreadyExist" -ForegroundColor Gray
Write-Host "Carpetas ignoradas: $ignored" -ForegroundColor Yellow
if ($errors -gt 0) {
    Write-Host "Errores: $errors" -ForegroundColor Red
    Write-Host ""
    Write-Host "SUGERENCIA: Cambia `$debugMode = `$true al inicio del script" -ForegroundColor Yellow
    Write-Host "para ver información detallada sobre los errores." -ForegroundColor Yellow
} else {
    Write-Host "Errores: $errors" -ForegroundColor Green
}
Write-Host ""
Write-Host "Ahora puedes configurar Radarr para que apunte a: $destination" -ForegroundColor Yellow
Write-Host "Radarr debería poder seguir los symlinks y acceder a los archivos." -ForegroundColor Yellow
Write-Host ""

# Pausar para ver resultados
Read-Host "Presiona Enter para salir"