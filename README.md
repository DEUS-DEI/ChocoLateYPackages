# 📦 Mis Paquetes Chocolatey (100% Automatizados)

Este repositorio contiene una colección de paquetes de Chocolatey mantenidos de forma totalmente autónoma mediante el framework **Chocolatey AU** y un orquestador centralizado.

## 🚀 Estado de la Automatización

Todos los paquetes se revisan, empaquetan y despliegan automáticamente todos los días.

| Paquete | Nivel | Método de Descubrimiento | Estado |
| :--- | :---: | :--- | :---: |
| `fenix-web-server` | 🟢 Lvl 3 | GitHub API (Stable releases) | ✅ Activo |
| `fenix-web-server-pre` | 🟢 Lvl 3 | GitHub API (Pre-releases) | ✅ Activo |
| `thunderbird-mozilla` | 🟢 Lvl 3 | **Smart Multi-Lang & Arch** (Mozilla API) | ✅ Activo |
| `thunderbird-nightly` | 🟢 Lvl 3 | **Smart Multi-Lang & Arch** (Mozilla API) | ✅ Activo |
| `github-desktop-pre` | 🟢 Lvl 3 | GitHub Central Desktop API | ✅ Activo |
| `nicepage` | 🟢 Lvl 3 | Web Scraping (HTML Parsing) | ✅ Activo |
| `cloudflare-warp-pre` | 🟢 Lvl 3 | Cloudflare Technical Scraping | ✅ Activo |
| `fenix-web-server-beta` | 🔀 Bridge | Redirige → `fenix-web-server-pre` | 🟡 v999.0.0 |
| `github-desktop-beta` | 🔀 Bridge | Redirige → `github-desktop-pre` | 🟡 v999.0.0 |
| `warp-beta` | 🔀 Bridge | Redirige → `cloudflare-warp-pre` | ⏳ Pendiente Moderador |
| `thunderbird-beta` | 🔀 Bridge | Redirige → `thunderbird-mozilla` | ⏳ Pendiente Moderador |
| `thunderbird-daily` | 🔀 Bridge | Redirige → `thunderbird-nightly` | ⏳ Pendiente Moderador |
| `flarectl` | 💀 Discontinuado | *Cloudflare eliminó binarios Win* | ⛔ Archivado |

## 🧠 Características Inteligentes Implementadas

*   **Detección de Idioma y Bits**: Los paquetes de Thunderbird detectan automáticamente el idioma (`es-MX`, etc.) y la arquitectura (`win64`/`win32`) de tu Windows. Si un idioma específico no está disponible en los servidores de Mozilla, el script hace **fallback automático a `en-US`** para garantizar que la instalación no falle.
*   **Gestión de Seguridad (Checksums)**: El sistema embebe los hashes SHA256 dentro del paquete durante el proceso de empaquetado, garantizando la validación sin descargas externas inseguras.
*   **Orquestador Central (`update_all.bat`)**: Un único script controla todo el ciclo de vida: búsqueda, actualización de Nuspec, empaquetado, limpieza y subida (push).
*   **Limpieza Automática**: El repositorio se mantiene siempre limpio, eliminando ejecutables y archivos temporales después de procesarlos.
*   **Scripts de Instalación Correctos**: Todos los paquetes usan el patrón correcto de Chocolatey: `Install-ChocolateyInstallPackage` para archivos locales ya descargados, e `Install-ChocolateyZipPackage` para ZIPs, eliminando descargas dobles.
*   **Iconos Estables**: Los iconos de todos los paquetes apuntan a URLs permanentes (`raw.githubusercontent.com`) en lugar de subdominios de preview que pueden desaparecer.

## 🛡️ Cumplimiento y Seguridad (Moderation Ready)

Este repositorio sigue las guías estrictas de moderación de Chocolatey:

1.  **Archivo de Verificación (`VERIFICATION.txt`)**: Cada paquete incluye instrucciones claras en la carpeta `tools` sobre cómo verificar manualmente la integridad de los binarios.
2.  **Etiquetas Optimizadas**: Todos los paquetes incluyen etiquetas estandarizadas (`admin`, `gui`, `foss`, etc.) para mejor descubrimiento y cumplimiento.
3.  **Metadatos Precisos**: Se han depurado los links de `projectSourceUrl` y descriptores para evitar banderas rojas en la revisión manual.
4.  **Fallback Robusto**: Los scripts están diseñados para ser resilientes a errores de red o disponibilidad de idiomas.
5.  **Scripts de Desinstalación Auditados**: Los `chocolateyuninstall.ps1` de todos los paquetes usan el `packageName` correcto y buscan la entrada de desinstalación en el registro de Windows de forma dinámica.
6.  **Sin Descargas Redundantes**: Se eliminó el anti-patrón de doble descarga en todos los paquetes (`fenix-web-server`, `fenix-web-server-pre`, `github-desktop-pre`).

## 🛠️ Cómo mantener este repo

Para ejecutar la actualización manual y despliegue de todos los paquetes, simplemente ejecuta:

```batch
.\update_all.bat
```

*Nota: Asegúrate de tener tu API Key configurada localmente para `choco push`.*

---
*Mantenido con ❤️ y automatización nivel Dios.*
