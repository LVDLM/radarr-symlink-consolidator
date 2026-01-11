# radarr-symlink-consolidator
PowerShell script para consolidar bibliotecas de películas dispersas en múltiples discos mediante symlinks, optimizado para Radarr y Plex


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
