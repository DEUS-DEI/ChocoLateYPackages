# 📦 Mis Paquetes Chocolatey (100% Automatizados)

Este repositorio contiene una colección de paquetes de Chocolatey mantenidos de forma autónoma mediante el framework **[Chocolatey-AU](https://github.com/chocolatey-community/chocolatey-au)** y un orquestador centralizado (`update_all.ps1`).

## 🚀 Estado de la Automatización

Los paquetes se revisan, empaquetan y publican bajo demanda (botón **Run workflow** en GitHub Actions o `menu.bat` en local). El cron diario del workflow está desactivado; basta con descomentarlo en `.github/workflows/update_packages.yml` para reactivarlo.

| Paquete | Nivel | Método de Descubrimiento | Estado |
| :--- | :---: | :--- | :---: |
| `fenix-web-server` | 🟢 Lvl 3 | GitHub API (releases estables) | ✅ Activo |
| `fenix-web-server-pre` | 🟢 Lvl 3 | GitHub API (pre-releases) | ✅ Activo |
| `thunderbird-mozilla` | 🟢 Lvl 3 | Mozilla product-details + `SHA256SUMS` (**Multi-Idioma y Arquitectura**) | ✅ Activo |
| `thunderbird-nightly` | 🟢 Lvl 3 | Mozilla product-details + build nightly fechada (**Multi-Idioma y Arquitectura**) | ✅ Activo |
| `github-desktop-pre` | 🟢 Lvl 3 | GitHub Desktop Central API (canal beta) | ✅ Activo |
| `nicepage` | 🟢 Lvl 3 | Manifiesto de actualización oficial (`latest.yml`) | ✅ Activo |
| `cloudflare-warp-pre` | 🟢 Lvl 3 | Feed JSON oficial de betas de Cloudflare | ✅ Activo |
| `fenix-web-server-beta` | 🔀 Bridge | Redirige → `fenix-web-server-pre` | 🟡 v999.0.0 |
| `github-desktop-beta` | 🔀 Bridge | Redirige → `github-desktop-pre` | 🟡 v999.0.0 |
| `warp-beta` | 🔀 Bridge | Redirige → `cloudflare-warp-pre` | ⏳ Pendiente Moderador |
| `thunderbird-beta` | 🔀 Bridge | Redirige → `thunderbird-mozilla` | ⏳ Pendiente Moderador |
| `thunderbird-daily` | 🔀 Bridge | Redirige → `thunderbird-nightly` | ⏳ Pendiente Moderador |
| `flarectl` | 💀 Discontinuado | *Cloudflare eliminó binarios Win* | ⛔ Archivado |

## 🗂️ Estructura

```
<paquete>/
├── <paquete>.nuspec          # Metadatos (AU actualiza la versión)
├── update.ps1                # Chocolatey-AU: au_GetLatest / au_SearchReplace del paquete
└── tools/
    ├── chocolateyinstall.ps1   # URL + checksum (AU los actualiza)
    ├── chocolateyuninstall.ps1
    ├── checksums.txt           # Solo Thunderbird: checksums oficiales por idioma/arquitectura
    └── VERIFICATION.txt
deprecated/                   # Bridges y paquetes descontinuados (push_deprecated.bat)
update_all.ps1 / .bat         # Orquestador: actualiza, publica y sincroniza Git
menu.bat                      # Panel de control interactivo
```

Cualquier carpeta con un `update.ps1` se considera un paquete activo: no hay listas que mantener a mano.

## 🧠 Características Inteligentes Implementadas

*   **Detección de Idioma y Bits**: Los paquetes de Thunderbird instalan el idioma de Windows (idioma de la interfaz y luego formato regional). Si Mozilla no publica ese idioma exacto prueban el idioma base (`de-DE` → `de`) o una variante (`es-CO` → `es-AR`) y, como último recurso, **`en-US`**. Se puede forzar con `--params "'/Language:es-MX /Arch:win32'"`.
*   **Gestión de Seguridad (Checksums)**: Cada paquete lleva el SHA256 del instalador calculado por AU (o copiado del manifiesto oficial de Mozilla), así que el binario se verifica siempre sin depender de descargas externas de checksums.
*   **URLs Inmutables**: WARP y Thunderbird Nightly apuntan a descargas versionadas (no a enlaces "latest"), por lo que el checksum embebido sigue siendo válido aunque el fabricante publique una build nueva.
*   **Orquestador Central (`update_all.ps1`)**: Un único script controla todo el ciclo de vida: búsqueda, actualización del nuspec y los scripts, empaquetado, subida (push) y commit. Solo se hace commit de los paquetes que se publicaron: si un push falla, la siguiente ejecución lo reintenta.
*   **Limpieza Automática**: Los `.nupkg` y los instaladores descargados por AU para calcular checksums se borran después de cada paquete.
*   **Sin Shims Fantasma**: Los instaladores se descargan a la caché de Chocolatey (nunca a la carpeta del paquete), así Chocolatey no crea accesos directos que vuelvan a ejecutar el setup.

## 🛡️ Cumplimiento y Seguridad (Moderation Ready)

Este repositorio sigue las guías de moderación de Chocolatey:

1.  **Archivo de Verificación (`VERIFICATION.txt`)**: Cada paquete explica de dónde sale el instalador y cómo comprobar su checksum.
2.  **Etiquetas Optimizadas**: Todos los paquetes incluyen etiquetas estandarizadas (`admin`, `gui`, `foss`, etc.).
3.  **Metadatos Precisos**: `packageSourceUrl` en todos los paquetes (también los bridges), `bugTrackerUrl` y `releaseNotes` reales.
4.  **Scripts de Desinstalación Robustos**: Buscan la entrada en el registro de Windows, soportan rutas con espacios (`C:\Program Files\...`) y los argumentos propios del desinstalador; los MSI se desinstalan por su código de producto.
5.  **Fallo Explícito**: Si el sistema no cumple los requisitos (p. ej. WARP en Windows < 10 1909) la instalación falla con un mensaje claro en lugar de "instalarse" sin hacer nada.

## 🛠️ Cómo mantener este repo

Requisitos (una vez): Chocolatey y el módulo Chocolatey-AU.

```batch
choco install chocolatey-au
choco apikey add -k <TU_API_KEY> -s https://push.chocolatey.org/
```

Uso:

| Comando | Qué hace |
| :--- | :--- |
| `.\menu.bat` | Panel interactivo |
| `.\update_all.bat` | Actualiza y publica todo lo que tenga versión nueva |
| `.\update_all.bat -Package nicepage -Force` | Re-empaqueta y sube un paquete aunque no haya versión nueva |
| `.\update_all.bat -NoPush` | Solo actualiza y empaqueta (deja los `.nupkg` para revisarlos) |
| `.\update_all.bat -NoGit` | Publica en Chocolatey sin hacer commit/push en Git |
| `cd nicepage` y `powershell -File update.ps1` | Prueba un solo paquete con AU |

En GitHub Actions la API Key se toma del secreto `CHOCO_API_KEY` (se puede configurar desde la opción 4 de `menu.bat`).

---
*Mantenido con ❤️ y automatización nivel Dios.*
