# 📦 Mis Paquetes Chocolatey (100% Automatizados)

Este repositorio contiene una colección de paquetes de Chocolatey mantenidos de forma autónoma mediante el framework **[Chocolatey-AU](https://github.com/chocolatey-community/chocolatey-au)** y un orquestador centralizado (`Scripts/update_all.bat`).

## 🚀 Estado de la Automatización

GitHub Actions revisa, empaqueta y publica los paquetes **todos los días** (cron a las 04:47 UTC) y también bajo demanda (botón **Run workflow**, con opción de elegir paquetes o forzar). En local se usa `Scripts\menu.bat`. `thunderbird-nightly` publica como máximo una build por semana para no saturar la cola de moderación, y espera a que Mozilla suba todos sus idiomas (llegan unas horas después de la build en inglés).

### Actuales (`Paquetes/actuales/`)

| Paquete | Nivel | Método de Descubrimiento | Estado |
| :--- | :---: | :--- | :---: |
| `fenix-web-server` | 🟢 Lvl 3 | GitHub API, 2 *streams*: estable + pre-releases (`--pre`) | ✅ Activo |
| `thunderbird-mozilla` | 🟢 Lvl 3 | Mozilla product-details + `SHA256SUMS` (**Multi-Idioma y Arquitectura**) | ✅ Activo |
| `thunderbird-nightly` | 🟢 Lvl 3 | Mozilla product-details + build nightly fechada (**Multi-Idioma y Arquitectura**) | ✅ Activo |
| `github-desktop-pre` | 🟢 Lvl 3 | GitHub Desktop Central API (canal beta) | ✅ Activo |
| `nicepage` | 🟢 Lvl 3 | Manifiesto de actualización oficial (`latest.yml`) | ✅ Activo |
| `cloudflare-warp-pre` | 🟢 Lvl 3 | Feed JSON oficial de betas de Cloudflare | ✅ Activo |
| `flarectl` | 🟢 Lvl 3 | Tags `v0.*` de cloudflare-go (`git ls-remote`) | ✅ Activo |

### Descontinuados (`Paquetes/descontinuados/`)

IDs retirados: cada uno publica un *bridge* que lleva a quien lo tenga instalado al paquete actual (cómo debe quedar cada uno, en [docs/mantenimiento.md](docs/mantenimiento.md#los-ids-descontinuados)).

| Paquete | Nivel | Método de Descubrimiento | Estado |
| :--- | :---: | :--- | :---: |
| `fenix-web-server-beta` | 🔀 Bridge | Redirige → `fenix-web-server` (pre-releases) | ⏳ `999.0.1-deprecated` enviado el 2026-10-08; versiones anteriores ocultas |
| `fenix-web-server-pre` | 🔀 Bridge | Redirige → `fenix-web-server` (pre-releases) | ⏳ `999.0.1-deprecated` enviado el 2026-10-08; versiones anteriores ocultas |
| `github-desktop-beta` | 🔀 Bridge | Redirige → `github-desktop-pre` | ⏳ `999.0.1-deprecated` enviado el 2026-10-04; retenido por CPMR0024 (explicado en su revisión el 2026-10-08); versiones anteriores ocultas |
| `thunderbird-beta` | 🔀 Bridge | Redirige → `thunderbird-mozilla` | ⏳ `999.0.1-deprecated` enviado el 2026-10-04; retenido por CPMR0024 (explicado en su revisión el 2026-10-08); versiones anteriores ocultas |
| `thunderbird-daily` | 🔀 Bridge | Redirige → `thunderbird-nightly` | ✅ `999.0.1-deprecated` exento desde el 2026-10-06; versiones anteriores ocultas |
| `warp-beta` | 🔀 Bridge | Redirige → `cloudflare-warp-pre` | ⏳ `999.0.1-deprecated` enviado el 2026-10-08; versiones anteriores ocultas |

La columna «Estado» de los bridges es una foto del 2026-10-08; el estado al día se ve en [la lista de paquetes de la cuenta](https://community.chocolatey.org/profiles/DEUS-DEI).

## 🛠️ Uso

Requisitos (una vez): Chocolatey y el módulo Chocolatey-AU.

```batch
choco install chocolatey-au
choco apikey add -k <TU_API_KEY> -s https://push.chocolatey.org/
```

| Comando | Qué hace |
| :--- | :--- |
| `Scripts\menu.bat` | Panel interactivo |
| `Scripts\update_all.bat` | Actualiza y publica todo lo que tenga versión nueva (`-Package`, `-Force`, `-NoPush`, `-NoGit`, `-NoWinget`: ver [docs/mantenimiento.md](docs/mantenimiento.md)) |
| `Scripts\push_deprecated.bat` | Publica los bridges de `Paquetes/descontinuados/` |
| `Scripts\vendor_catalog.bat` | Catálogo del software de los fabricantes; con `-Install`, lo instala desde el fabricante ([docs/vendor_catalog.md](docs/vendor_catalog.md)) |

## 🗂️ Estructura

```
Paquetes/
├── actuales/<paquete>/           # Paquetes activos: los que revisa y publica Scripts/update_all.bat
│   ├── <paquete>.nuspec          # Metadatos (AU actualiza la versión)
│   ├── update.ps1                # Chocolatey-AU: au_GetLatest / au_SearchReplace del paquete
│   ├── <paquete>.json            # Solo fenix-web-server: versión publicada de cada stream (AU)
│   ├── winget/                   # Si va también a winget: winget.psd1 y, a veces, plantillas *.yaml (docs/winget.md)
│   └── tools/
│       ├── chocolateyinstall.ps1   # URL + checksum literales (AU los actualiza; Thunderbird lleva uno por idioma/arquitectura)
│       └── chocolateyuninstall.ps1
└── descontinuados/<id>/          # IDs retirados: solo el nuspec del bridge (Scripts/push_deprecated.bat)
deprecated/<id>/README.md         # Avisos de «se movió»: no borrar (las versiones viejas enlazan aquí)
icons/                            # Iconos de los paquetes (servidos por jsDelivr fijado a un commit)
Scripts/
├── update_all.bat                # Orquestador: actualiza, publica y sincroniza Git (lleva su PowerShell dentro)
├── vendor_catalog.bat            # Catálogo de los fabricantes e instalación directa (-Install)
├── menu.bat                      # Panel de control interactivo
├── push_deprecated.bat           # Publica los bridges
└── lib/                          # Lanzar.ps1 (el cargador de los .bat), Get-Secret.ps1, vendor_catalog.psd1
tests/                            # Pruebas Pester en Windows y la configuración de PSScriptAnalyzer
docs/                             # La documentación (abajo)
```

## 📚 Documentación

| Documento | De qué trata |
| :--- | :--- |
| [docs/mantenimiento.md](docs/mantenimiento.md) | Cómo funciona, las reglas de moderación que cumple, el uso completo de los scripts, los secretos y las notas (fix versions, streams, 403, bridges, iconos) |
| [docs/winget.md](docs/winget.md) | Los paquetes que van también a winget y cómo se preparan sus manifiestos |
| [docs/vendor_catalog.md](docs/vendor_catalog.md) | El catálogo de fabricantes y la instalación directa desde el fabricante |
| [docs/catalogo-fabricantes.md](docs/catalogo-fabricantes.md) | El último informe guardado del catálogo |
| [docs/pruebas.md](docs/pruebas.md) | El análisis estático y las pruebas en Windows |

---
*Mantenido con ❤️ y automatización nivel Dios.*
