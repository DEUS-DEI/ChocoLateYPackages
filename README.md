# 📦 Mis Paquetes Chocolatey (100% Automatizados)

Este repositorio contiene una colección de paquetes de Chocolatey mantenidos de forma totalmente autónoma mediante el framework **Chocolatey AU** y un orquestador centralizado.

## 🚀 Estado de la Automatización

Todos los paquetes se revisan, empaquetan y despliegan automáticamente todos los días.

| Paquete | Nivel | Método de Descubrimiento | Estado Actual |
| :--- | :---: | :--- | :---: |
| `fenix-web-server` | 🟢 Lvl 3 | GitHub API (Stable releases) | ✅ Activo |
| `fenix-web-server-beta` | 🟢 Lvl 3 | GitHub API (Pre-releases) | ✅ Activo |
| `thunderbird-beta` | 🟢 Lvl 3 | **Smart Multi-Lang & Arch** (Mozilla API) | ✅ Activo |
| `thunderbird-daily` | 🟢 Lvl 3 | **Smart Multi-Lang & Arch** (Mozilla API) | ✅ Activo |
| `github-desktop-beta` | 🟢 Lvl 3 | GitHub Central Desktop API | ✅ Activo |
| `nicepage` | 🟢 Lvl 3 | Web Scraping (HTML Parsing) | ✅ Activo |
| `warp-beta` | 🟢 Lvl 3 | Cloudflare Technical Scraping | ✅ Activo |
| `flarectl` | 💀 Descontinuado | *Sustituido por herramientas oficiales* | ⛔ Archivada |

## 🧠 Características Inteligentes Implementadas

*   **Detección de Idioma y Bits**: Los paquetes de Thunderbird detectan automáticamente el idioma (`es-MX`, etc.) y la arquitectura (`x64`/`x86`) de tu Windows.
*   **Gestión de Seguridad (Checksums)**: El sistema descarga y valida los hashes SHA256 directamente desde los servidores oficiales al momento de instalar.
*   **Orquestador Central (`update_all.bat`)**: Un único script controla todo el ciclo de vida: búsqueda, actualización de Nuspec, empaquetado, limpieza y subida (push).
*   **Limpieza Automática**: El repositorio se mantiene siempre limpio, eliminando ejecutables y archivos temporales después de procesarlos.

## 🛠️ Cómo mantener este repo

Para ejecutar la actualización manual y despliegue de todos los paquetes, simplemente ejecuta:

```batch
.\update_all.bat
```

*Nota: Asegúrate de tener tu API Key configurada localmente para `choco push`.*

---
*Mantenido con ❤️ y automatización nivel Dios.*
