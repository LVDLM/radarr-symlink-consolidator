# radarr-symlink-consolidator
PowerShell script para consolidar bibliotecas de películas dispersas en múltiples discos mediante symlinks, optimizado para Radarr y Plex

PowerShell script to consolidate movie libraries scattered across multiple drives using symlinks, optimized for Radarr and Plex

# Español
# Media Symlink Manager

Script de PowerShell para consolidar bibliotecas de películas dispersas en múltiples discos duros mediante enlaces simbólicos (symlinks).

## 🎯 Propósito

Si tienes películas distribuidas en varios discos (internos, externos, NAS) y quieres:
- Configurar **Radarr** o **Plex** apuntando a una única ubicación
- **NO mover ni copiar** archivos originales (ahorra espacio y tiempo)
- Mantener los archivos en sus ubicaciones originales
- Actualizar fácilmente cuando agregues nuevas películas

Este script crea una estructura unificada usando symlinks, permitiendo que aplicaciones como Radarr vean todo en un solo lugar.

## ✨ Características

- ✅ Procesa múltiples discos y carpetas simultáneamente
- ✅ Soporte completo para caracteres especiales y corchetes `[]` en nombres
- ✅ Ignora automáticamente extras, featurettes, samples y trailers
- ✅ Sistema de carpetas `.ignore` personalizables
- ✅ Ejecución incremental (solo crea enlaces nuevos)
- ✅ Modo debug para diagnóstico
- ✅ Manejo robusto de errores

## 📋 Requisitos

- Windows 10/11
- PowerShell 5.1 o superior
- Permisos de administrador (necesario para crear symlinks)

## 🚀 Uso

1. Edita el script y configura tus rutas:
```powershell
$destino = "F:\Peliculas"  # Carpeta donde se crearán los symlinks

$origenes = @(
    "D:\Peliculas",
    "E:\",
    "H:\Cine\Accion"
)
```

2. Ejecuta PowerShell como **Administrador**

3. Ejecuta el script:
```powershell
.\crear-symlinks.ps1
```

## 🎬 Ejemplo

**Antes:**
```
D:\Peliculas\Inception (2010)\Inception.mkv
E:\Marvel\Avengers.mp4
H:\Anime\Akira\Akira.mkv
```

**Después (en F:\Peliculas):**
```
F:\Peliculas\Inception (2010)\Inception.mkv  → D:\Peliculas\Inception (2010)\Inception.mkv
F:\Peliculas\Avengers\Avengers.mp4           → E:\Marvel\Avengers.mp4
F:\Peliculas\Akira\Akira.mkv                 → H:\Anime\Akira\Akira.mkv
```

## ⚙️ Configuración avanzada

### Ignorar carpetas específicas
El script ignora automáticamente: extras, featurettes, samples, trailers, etc.

### Sistema .ignore
Crea un archivo `.ignore` en cualquier carpeta para que todo su contenido sea ignorado.

### Modo Debug
Cambia `$modoDebug = $true` para ver información detallada del procesamiento.

## 🤝 Integración con Radarr

1. Ejecuta el script para crear los symlinks
2. En Radarr, configura la ruta raíz apuntando a tu carpeta destino (ej: `F:\Peliculas`)
3. Radarr verá todos los archivos como si estuvieran en un solo lugar

## ⚠️ Notas importantes

- Los archivos originales **nunca** se mueven ni copian
- Los symlinks ocupan ~0 bytes de espacio
- Si eliminas un symlink, el archivo original permanece intacto
- Puedes ejecutar el script múltiples veces de forma segura

## 📝 Licencia

MIT License

## 🐛 Problemas conocidos

Si encuentras errores, activa el modo debug y abre un issue con la salida detallada.

# English

# Media Symlink Manager

PowerShell script to consolidate movie libraries scattered across multiple hard drives using symbolic links (symlinks).

## 🎯 Purpose

If you have movies distributed across several drives (internal, external, NAS) and want to:
- Configure **Radarr** or **Plex** pointing to a single location
- **NOT move or copy** original files (saves space and time)
- Keep files in their original locations
- Easily update when you add new movies

This script creates a unified structure using symlinks, allowing applications like Radarr to see everything in one place.

## ✨ Features

- ✅ Process multiple drives and folders simultaneously
- ✅ Full support for special characters and brackets `[]` in names
- ✅ Automatically ignores extras, featurettes, samples, and trailers
- ✅ Customizable `.ignore` folder system
- ✅ Incremental execution (only creates new links)
- ✅ Debug mode for diagnostics
- ✅ Robust error handling

## 📋 Requirements

- Windows 10/11
- PowerShell 5.1 or higher
- Administrator privileges (required to create symlinks)

## 🚀 Usage

1. Edit the script and configure your paths:
```powershell
$destination = "F:\Movies"  # Folder where symlinks will be created

$sources = @(
    "D:\Movies",
    "E:\",
    "H:\Cinema\Action"
)
```

2. Run PowerShell as **Administrator**

3. Execute the script:
```powershell
.\create-symlinks.ps1
```

## 🎬 Example

**Before:**
```
D:\Movies\Inception (2010)\Inception.mkv
E:\Marvel\Avengers.mp4
H:\Anime\Akira\Akira.mkv
```

**After (in F:\Movies):**
```
F:\Movies\Inception (2010)\Inception.mkv  → D:\Movies\Inception (2010)\Inception.mkv
F:\Movies\Avengers\Avengers.mp4           → E:\Marvel\Avengers.mp4
F:\Movies\Akira\Akira.mkv                 → H:\Anime\Akira\Akira.mkv
```

## ⚙️ Advanced Configuration

### Ignore specific folders
The script automatically ignores: extras, featurettes, samples, trailers, etc.

### .ignore system
Create a `.ignore` file in any folder to have all its content ignored.

### Debug Mode
Change `$debugMode = $true` to see detailed processing information.

## 🤝 Radarr Integration

1. Run the script to create the symlinks
2. In Radarr, configure the root path pointing to your destination folder (e.g., `F:\Movies`)
3. Radarr will see all files as if they were in one place

## ⚠️ Important Notes

- Original files are **never** moved or copied
- Symlinks take up ~0 bytes of space
- If you delete a symlink, the original file remains intact
- You can safely run the script multiple times

## 📝 License

MIT License

## 🐛 Known Issues

If you encounter errors, enable debug mode and open an issue with the detailed output.

## 🌐 Language

This script includes English messages and comments. Variable names and folder structures can be customized for any region.

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## ⭐ Star this repo

If this script helped you organize your media library, please give it a star!
