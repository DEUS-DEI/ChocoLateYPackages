# 📦 Mis Paquetes Chocolatey (100% Automatizados)

Este repositorio contiene una colección de paquetes de Chocolatey mantenidos de forma autónoma mediante el framework **[Chocolatey-AU](https://github.com/chocolatey-community/chocolatey-au)** y un orquestador centralizado (`update_all.ps1`).

## 🚀 Estado de la Automatización

GitHub Actions revisa, empaqueta y publica los paquetes **todos los días** (cron a las 04:47 UTC) y también bajo demanda (botón **Run workflow**, con opción de elegir paquetes o forzar). En local se usa `menu.bat`. `thunderbird-nightly` publica como máximo una build por semana para no saturar la cola de moderación.

| Paquete | Nivel | Método de Descubrimiento | Estado |
| :--- | :---: | :--- | :---: |
| `fenix-web-server` | 🟢 Lvl 3 | GitHub API, 2 *streams*: estable + pre-releases (`--pre`) | ✅ Activo |
| `thunderbird-mozilla` | 🟢 Lvl 3 | Mozilla product-details + `SHA256SUMS` (**Multi-Idioma y Arquitectura**) | ✅ Activo |
| `thunderbird-nightly` | 🟢 Lvl 3 | Mozilla product-details + build nightly fechada (**Multi-Idioma y Arquitectura**) | ✅ Activo |
| `github-desktop-pre` | 🟢 Lvl 3 | GitHub Desktop Central API (canal beta) | ✅ Activo |
| `nicepage` | 🟢 Lvl 3 | Manifiesto de actualización oficial (`latest.yml`) | ✅ Activo |
| `cloudflare-warp-pre` | 🟢 Lvl 3 | Feed JSON oficial de betas de Cloudflare | ✅ Activo |
| `flarectl` | 🟢 Lvl 3 | Tags `v0.*` de cloudflare-go (`git ls-remote`) | ✅ Activo |
| `fenix-web-server-beta` | 🔀 Bridge | Redirige → `fenix-web-server` (pre-releases) | 🟡 v999.0.0 |
| `fenix-web-server-pre` | 🔀 Bridge | Redirige → `fenix-web-server` (pre-releases) | 🟡 v999.0.0 |
| `github-desktop-beta` | 🔀 Bridge | Redirige → `github-desktop-pre` | 🟡 v999.0.0 |
| `thunderbird-beta` | 🔀 Bridge | Redirige → `thunderbird-mozilla` | ⏳ Pendiente Moderador |
| `thunderbird-daily` | 🔀 Bridge | Redirige → `thunderbird-nightly` | ⏳ Pendiente Moderador |

## 🗂️ Estructura

```
<paquete>/
├── <paquete>.nuspec          # Metadatos (AU actualiza la versión)
├── update.ps1                # Chocolatey-AU: au_GetLatest / au_SearchReplace del paquete
├── <paquete>.json            # Solo fenix-web-server: versión publicada de cada stream (AU)
└── tools/
    ├── chocolateyinstall.ps1   # URL + checksum (AU los actualiza)
    ├── chocolateyuninstall.ps1
    └── checksums.txt           # Solo Thunderbird: checksums oficiales por idioma/arquitectura
icons/                        # Iconos de los paquetes (servidos por jsDelivr fijado a un commit)
deprecated/                   # Bridges de IDs retirados (push_deprecated.bat)
update_all.ps1 / .bat         # Orquestador: actualiza, publica y sincroniza Git
menu.bat                      # Panel de control interactivo
```

Cualquier carpeta con un `update.ps1` se considera un paquete activo: no hay listas que mantener a mano. Solo se empaqueta `tools\` (elemento `<files>` del nuspec), así que `update.ps1` no viaja en el `.nupkg`.

## 🧠 Características Inteligentes Implementadas

*   **Detección de Idioma y Bits**: Los paquetes de Thunderbird instalan el idioma de Windows (idioma de la interfaz y luego formato regional). Si Mozilla no publica ese idioma exacto prueban el idioma base (`de-DE` → `de`) o una variante (`es-CO` → `es-AR`) y, como último recurso, **`en-US`**. Se puede forzar con `--params "'/Language:es-MX /Arch:win32'"`.
*   **Gestión de Seguridad (Checksums)**: Cada paquete lleva el SHA256 del instalador calculado por AU (o copiado del manifiesto oficial de Mozilla), así que el binario se verifica siempre sin depender de descargas externas de checksums.
*   **URLs Inmutables**: WARP y Thunderbird Nightly apuntan a descargas versionadas (no a enlaces "latest"), por lo que el checksum embebido sigue siendo válido aunque el fabricante publique una build nueva.
*   **Orquestador Central (`update_all.ps1`)**: Un único script controla todo el ciclo de vida: búsqueda, actualización del nuspec y los scripts, empaquetado, subida (push) y commit. Si un push falla, la carpeta del paquete se restaura y la siguiente ejecución lo reintenta; solo se hace commit (limitado a esas carpetas) de lo que llegó a Chocolatey.
*   **Betas bajo el mismo ID**: las pre-releases de Fenix se publican como versiones prerelease de `fenix-web-server` (streams de AU), como pide la regla CPMR0024. Los paquetes beta cuyo ID estable pertenece a otro mantenedor (`warp`, `github-desktop`, `thunderbird`) siguen con su ID propio.
*   **Limpieza Automática**: Los `.nupkg` y los instaladores descargados por AU para calcular checksums se borran después de cada paquete.
*   **Sin Shims Fantasma**: Los instaladores se descargan a la caché de Chocolatey (nunca a la carpeta del paquete), así Chocolatey no crea accesos directos que vuelvan a ejecutar el setup.

## 🛡️ Cumplimiento y Seguridad (Moderation Ready)

Este repositorio sigue las guías de moderación de Chocolatey:

1.  **Sin `VERIFICATION.txt` / `LICENSE.txt`**: solo se exigen cuando el binario va embebido en el paquete; aquí los instaladores se descargan con checksum (lo pidió un moderador en la revisión de `cloudflare-warp-pre`).
2.  **Etiquetas Optimizadas**: Todos los paquetes incluyen etiquetas estandarizadas (`admin`, `gui`, `foss`, etc.).
3.  **Metadatos Precisos**: `packageSourceUrl` en todos los paquetes (también los bridges), `bugTrackerUrl` y `releaseNotes` reales. La descripción de Nicepage indica que es software freemium con periodo de prueba.
4.  **Scripts de Desinstalación Robustos**: Buscan la entrada en el registro de Windows, soportan rutas con espacios (`C:\Program Files\...`) y los argumentos propios del desinstalador; los MSI se desinstalan por su código de producto.
5.  **Fallo Explícito**: Si el sistema no cumple los requisitos (Windows 10, o 10 1909 para WARP) la instalación falla con un mensaje claro en lugar de "instalarse" sin hacer nada.
6.  **Iconos propios**: PNG de 256 px alojados en `icons/` y servidos por jsDelivr fijado a un commit (Chocolatey prohíbe `raw.githubusercontent.com` y exige que el mantenedor controle el icono).
7.  **Compatibles con PowerShell v2**: los scripts que se ejecutan al instalar evitan sintaxis de PowerShell 3+ (requisito de la revisión de moderadores).
8.  **Deprecación según la guía oficial**: los bridges llevan `[Deprecated]` en el título, `<files />`, sin icono y con dependencia con versión mínima.

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
| `.\update_all.bat -NoPush` | Solo empaqueta para revisar: deja los `.nupkg` y restaura los archivos, así la siguiente ejecución normal publica la versión nueva |
| `.\update_all.bat -NoGit` | Publica en Chocolatey sin hacer commit/push en Git |
| `cd nicepage` y `powershell -File update.ps1` | Prueba un solo paquete con AU |

En GitHub Actions la API Key se toma del secreto `CHOCO_API_KEY` (se puede configurar desde la opción 4 de `menu.bat`).

> **Arreglos de un paquete ya aprobado sin versión nueva del software**: usa la notación de *fix version* (`2.0.0` → `2.0.0.20260926`). En `fenix-web-server` se declara en `$packageFixes` de su `update.ps1`, así que AU la publica solo en la siguiente ejecución.

> **Streams (`fenix-web-server`)**: cada ejecución publica por separado la versión estable y la prerelease. Si solo se publica una, la otra se reintenta en la siguiente ejecución. `-Force` re-empaqueta únicamente el stream que está en ese momento en la carpeta.

> **Nuevos iconos**: añade el PNG a `icons/`, haz commit y usa `https://cdn.jsdelivr.net/gh/DEUS-DEI/ChocoLateYPackages@<commit>/icons/<id>.png`.

### Análisis estático (PSScriptAnalyzer)

`PSScriptAnalyzerSettings.psd1` guarda la configuración del analizador: cada regla desactivada explica por qué no aplica y además se comprueba que la sintaxis funcione en Windows PowerShell 5.1. Desde la raíz del repo debe dar **cero avisos**:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser   # solo la primera vez
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

---
*Mantenido con ❤️ y automatización nivel Dios.*
