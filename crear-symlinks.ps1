# Script para crear symlinks de peliculas dispersas en varios discos
# EJECUTAR COMO ADMINISTRADOR

# Verificar si se esta ejecutando como administrador
$esAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $esAdmin) {
    Write-Host ""
    Write-Host "ERROR: Este script necesita ejecutarse como ADMINISTRADOR" -ForegroundColor Red
    Write-Host ""
    Write-Host "Como ejecutar:" -ForegroundColor Yellow
    Write-Host "1. Click derecho en PowerShell" -ForegroundColor White
    Write-Host "2. Seleccionar 'Ejecutar como administrador'" -ForegroundColor White
    Write-Host "3. Navegar a la carpeta del script: cd 'ruta\del\script'" -ForegroundColor White
    Write-Host "4. Ejecutar: .\crear-symlinks.ps1" -ForegroundColor White
    Write-Host ""
    Read-Host "Presiona Enter para salir"
    exit
}

# Configuracion
$destino = "F:\Animación"

# Lista de rutas origen (agrega todas tus carpetas con peliculas)
$origenes = @(
    "I:\",
    "N:\",
    "Q:\",
    "O:\",
    "P:\",
    "R:\#Sagas",
    "S:\Filmografias",
    "T:\",
    "U:\"
)

# Extensiones de video validas
$extensiones = @("*.mkv", "*.mp4", "*.avi", "*.m4v", "*.mov")

# Nombres de carpetas a ignorar (puedes agregar más)
$carpetasIgnoradas = @(
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

# Palabras en nombres de archivo a ignorar
$palabrasIgnoradasEnArchivo = @(
    "sample"
)

# Modo debug (cambiar a $true para ver más detalles)
$modoDebug = $false

# Función para verificar si una ruta debe ser ignorada
function DebeIgnorar {
    param (
        [string]$rutaArchivo,
        [string]$nombreArchivo
    )
    
    try {
        # Verificar si el nombre del archivo contiene palabras a ignorar
        foreach ($palabra in $palabrasIgnoradasEnArchivo) {
            if ($nombreArchivo.ToLower() -like "*$palabra*") {
                return $true
            }
        }
        
        # Obtener todas las carpetas en la ruta
        $carpetas = $rutaArchivo.Split([IO.Path]::DirectorySeparatorChar)
        
        # Verificar si alguna carpeta en la ruta coincide con las ignoradas
        foreach ($carpeta in $carpetas) {
            if ($carpetasIgnoradas -contains $carpeta.ToLower()) {
                return $true
            }
        }
        
        # Verificar si existe archivo .ignore en la carpeta del archivo o en carpetas superiores
        $directorioActual = Split-Path -LiteralPath $rutaArchivo -Parent
        
        while ($directorioActual) {
            $archivoIgnore = Join-Path $directorioActual ".ignore"
            if (Test-Path -LiteralPath $archivoIgnore -ErrorAction SilentlyContinue) {
                return $true
            }
            
            # Subir un nivel (detener si llegamos a la raíz)
            $directorioPadre = Split-Path -LiteralPath $directorioActual -Parent
            if ($directorioPadre -eq $directorioActual) {
                break
            }
            $directorioActual = $directorioPadre
        }
        
        return $false
    } catch {
        # Si hay error al verificar, no ignorar el archivo
        return $false
    }
}

# Crear carpeta destino si no existe
if (-not (Test-Path -LiteralPath $destino)) {
    New-Item -ItemType Directory -Path $destino -Force | Out-Null
    Write-Host "Carpeta destino creada: $destino" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== INICIANDO CREACION DE SYMLINKS ===" -ForegroundColor Cyan
Write-Host "Destino: $destino" -ForegroundColor Yellow
Write-Host ""

$contador = 0
$errores = 0
$ignorados = 0
$yaExisten = 0

foreach ($origen in $origenes) {
    if (-not (Test-Path -LiteralPath $origen)) {
        Write-Host "Ruta no encontrada: $origen" -ForegroundColor Yellow
        continue
    }
    
    Write-Host ""
    Write-Host "Procesando: $origen" -ForegroundColor Cyan
    
    # Buscar todos los archivos de video recursivamente
    foreach ($ext in $extensiones) {
        $archivos = Get-ChildItem -Path $origen -Filter $ext -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($archivo in $archivos) {
            try {
                # DEBUG: Mostrar información del archivo
                if ($modoDebug) {
                    Write-Host ""
                    Write-Host "DEBUG - Procesando archivo:" -ForegroundColor Magenta
                    Write-Host "  Nombre: $($archivo.Name)" -ForegroundColor DarkGray
                    Write-Host "  FullName: $($archivo.FullName)" -ForegroundColor DarkGray
                    Write-Host "  Directory: $($archivo.DirectoryName)" -ForegroundColor DarkGray
                }
                
                # Verificar que el archivo aún existe
                if (-not (Test-Path -LiteralPath $archivo.FullName)) {
                    Write-Host "  Archivo desaparecido: $($archivo.Name)" -ForegroundColor Magenta
                    Write-Host "    Ruta reportada: $($archivo.FullName)" -ForegroundColor DarkGray
                    $ignorados++
                    continue
                }
            } catch {
                Write-Host "  Error al verificar existencia: $($archivo.Name)" -ForegroundColor Magenta
                Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkGray
                $ignorados++
                continue
            }
            
            # Verificar si debe ignorarse
            if (DebeIgnorar -rutaArchivo $archivo.FullName -nombreArchivo $archivo.Name) {
                Write-Host "  Ignorado: $($archivo.Name)" -ForegroundColor DarkYellow
                $ignorados++
                continue
            }
            
            try {
                # Obtener nombre del archivo sin extension
                $nombrePelicula = $archivo.BaseName
                
                # Crear carpeta de destino para la pelicula
                $carpetaPelicula = Join-Path $destino $nombrePelicula
                
                if (-not (Test-Path -LiteralPath $carpetaPelicula)) {
                    New-Item -ItemType Directory -Path $carpetaPelicula -Force -ErrorAction Stop | Out-Null
                }
                
                # Ruta completa del symlink
                $symlinkPath = Join-Path $carpetaPelicula $archivo.Name
                
                # Verificar si ya existe
                if (Test-Path -LiteralPath $symlinkPath) {
                    if ($modoDebug) {
                        Write-Host "  Ya existe: $nombrePelicula" -ForegroundColor Gray
                    }
                    $yaExisten++
                    continue
                }
                
                # DEBUG: Mostrar lo que se va a crear
                if ($modoDebug) {
                    Write-Host "  Intentando crear symlink:" -ForegroundColor Cyan
                    Write-Host "    Target: $($archivo.FullName)" -ForegroundColor DarkGray
                    Write-Host "    Path: $symlinkPath" -ForegroundColor DarkGray
                }
                
                # Escapar corchetes en la ruta de origen (fix para bug de PowerShell)
                $targetEscapado = $archivo.FullName -replace '\[','`[' -replace '\]','`]'
                
                # Crear el symlink usando -Value en lugar de -Target (mejor manejo de corchetes)
                New-Item -ItemType SymbolicLink -Path $symlinkPath -Value $targetEscapado -Force -ErrorAction Stop | Out-Null
                
                Write-Host "  Creado: $nombrePelicula" -ForegroundColor Green
                
                $contador++
                
            } catch {
                Write-Host "  Error con: $($archivo.Name)" -ForegroundColor Red
                Write-Host "    Ruta origen: $($archivo.FullName)" -ForegroundColor DarkRed
                Write-Host "    Carpeta destino: $carpetaPelicula" -ForegroundColor DarkRed
                Write-Host "    Mensaje: $($_.Exception.Message)" -ForegroundColor DarkRed
                $errores++
            }
        }
    }
}

Write-Host ""
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Symlinks creados: $contador" -ForegroundColor Green
Write-Host "Ya existían: $yaExisten" -ForegroundColor Gray
Write-Host "Archivos ignorados: $ignorados" -ForegroundColor Yellow
if ($errores -gt 0) {
    Write-Host "Errores: $errores" -ForegroundColor Red
    Write-Host ""
    Write-Host "SUGERENCIA: Cambia `$modoDebug = `$true al inicio del script" -ForegroundColor Yellow
    Write-Host "para ver información detallada sobre los errores." -ForegroundColor Yellow
} else {
    Write-Host "Errores: $errores" -ForegroundColor Green
}
Write-Host ""
Write-Host "Ahora puedes configurar Radarr para que apunte a: $destino" -ForegroundColor Yellow
Write-Host "Los archivos originales NO se han movido ni copiado." -ForegroundColor Yellow
Write-Host ""

# Pausar para ver resultados
Read-Host "Presiona Enter para salir"