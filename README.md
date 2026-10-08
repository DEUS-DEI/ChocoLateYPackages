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
| `fenix-web-server-beta` | 🔀 Bridge | Redirige → `fenix-web-server` (pre-releases) | ⏳ `999.0.1-deprecated` enviado el 2026-10-08; versiones anteriores ocultas |
| `fenix-web-server-pre` | 🔀 Bridge | Redirige → `fenix-web-server` (pre-releases) | ⏳ `999.0.1-deprecated` enviado el 2026-10-08; versiones anteriores ocultas |
| `github-desktop-beta` | 🔀 Bridge | Redirige → `github-desktop-pre` | ⏳ `999.0.1-deprecated` enviado el 2026-10-04; retenido por CPMR0024 (explicado en su revisión el 2026-10-08); versiones anteriores ocultas |
| `thunderbird-beta` | 🔀 Bridge | Redirige → `thunderbird-mozilla` | ⏳ `999.0.1-deprecated` enviado el 2026-10-04; retenido por CPMR0024 (explicado en su revisión el 2026-10-08); versiones anteriores ocultas |
| `thunderbird-daily` | 🔀 Bridge | Redirige → `thunderbird-nightly` | ✅ `999.0.1-deprecated` exento desde el 2026-10-06; versiones anteriores ocultas |
| `warp-beta` | 🔀 Bridge | Redirige → `cloudflare-warp-pre` | ⏳ `999.0.1-deprecated` enviado el 2026-10-08; versiones anteriores ocultas |

**Cómo debe quedar un ID descontinuado** (guía oficial de deprecación): una sola versión listada, el bridge `999.x-deprecated` exento o aprobado, y todas las versiones anteriores ocultas (*unlisted*). Quien tenga instalado el ID antiguo pasa al paquete nuevo con `choco upgrade`, y quien lo instale de cero recibe el paquete nuevo como dependencia. Las versiones anteriores de los seis IDs se ocultaron el 2026-10-08, sin esperar a que cada bridge estuviera listado: eran builds de 2022 (las de Fenix se cuelgan al instalar) y no convenía dejarlas a la vista. Mientras un bridge sigue en moderación, su ID no tiene ninguna versión instalable directamente; quien ya lo tenga instalado no nota nada. Ocultar es reversible (*Change Listing Status* en la página de cada versión).

La columna «Estado» de los bridges es una foto del 2026-10-08; el estado al día se ve en [la lista de paquetes de la cuenta](https://community.chocolatey.org/profiles/DEUS-DEI). Los bridges `999.0.0` de `fenix-web-server-beta` y `github-desktop-beta` se enviaron en abril de 2026 y Chocolatey los rechazó el 19 de mayo, porque su dependencia no se podía satisfacer; ver la nota «Bridges de deprecación» más abajo.

## 🗂️ Estructura

```
<paquete>/
├── <paquete>.nuspec          # Metadatos (AU actualiza la versión)
├── update.ps1                # Chocolatey-AU: au_GetLatest / au_SearchReplace del paquete
├── <paquete>.json            # Solo fenix-web-server: versión publicada de cada stream (AU)
└── tools/
    ├── chocolateyinstall.ps1   # URL + checksum literales (AU los actualiza; Thunderbird lleva uno por idioma/arquitectura)
    └── chocolateyuninstall.ps1
icons/                        # Iconos de los paquetes (servidos por jsDelivr fijado a un commit)
deprecated/                   # Bridges de IDs retirados (push_deprecated.bat)
update_all.ps1 / .bat         # Orquestador: actualiza, publica y sincroniza Git
menu.bat                      # Panel de control interactivo
tests/                        # Pruebas Pester en Windows (tests/README.md)
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
8.  **Deprecación según la guía oficial**: los bridges llevan `[Deprecated]` en el título, `<files />`, sin icono y con dependencia con versión mínima, y son versiones prerelease para que esa dependencia se pueda resolver (nota «Bridges de deprecación»).
9.  **Checksums que el validador puede leer (CPMR0073)**: el validador automático no ejecuta los scripts, así que el checksum de cada descarga va escrito en `chocolateyinstall.ps1` como literal (o en una variable que solo recibe literales). Un checksum elegido al instalar (`$installer.Hash`, `$tabla['checksum']`, un archivo en `tools\`) verifica igual el binario, pero el validador lo marca como «descarga sin checksum» y retiene la versión. Por eso los Thunderbird llevan un `switch` con el SHA256 de cada idioma/arquitectura, que `update.ps1` reescribe en cada versión. Lo vigila `tests/Packages.Tests.ps1`.
10. **Instalación desatendida de verdad (Fenix 3.x)**: su instalador muestra, incluso con `/S`, un aviso que hay que aceptar («la aplicación recoge estadísticas de uso no personales») y no tiene parámetro para saltarlo, así que la instalación se quedaba esperando hasta agotar el tiempo. `fenix-web-server\tools\AcceptUsageNotice.ps1` responde OK a ese aviso (y solo a ese) mientras corre el instalador, y la descripción del paquete avisa de que instalar la prerelease lo acepta. Fenix 2.x no muestra ningún aviso.

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
| `.\update_all.bat -NoPush` | Solo empaqueta para revisar: deja los `.nupkg` y restaura los archivos, así la siguiente ejecución normal publica la versión nueva (si la hay: un paquete que solo se empaquetó por `-Force` no se publica) |
| `.\update_all.bat -NoGit` | Publica en Chocolatey sin hacer commit/push en Git |
| `.\push_deprecated.bat` | Publica los bridges de `deprecated/`. Termina con código 1 si falla algún empaquetado o push; `--no-pause` no espera una tecla al final |
| `cd nicepage` y `powershell -File update.ps1` | Prueba un solo paquete con AU |

En GitHub Actions la API Key se toma del secreto `CHOCO_API_KEY` (se puede configurar desde la opción 4 de `menu.bat`).

> **Arreglos de un paquete ya aprobado sin versión nueva del software**: usa la notación de *fix version* (`2.0.0` → `2.0.0.20260926`). En `fenix-web-server` se declara en `$packageFixes` de su `update.ps1`, así que AU la publica solo en la siguiente ejecución.

> **Streams (`fenix-web-server`)**: cada ejecución publica por separado la versión estable y la prerelease. Si solo se publica una, la otra se reintenta en la siguiente ejecución. `-Force` re-empaqueta únicamente el stream que está en ese momento en la carpeta.

> **Versión publicada sin commit en Git** (p. ej. el runner no pudo hacer push): AU la salta porque ya existe en Chocolatey. `update_all.ps1` lo detecta, actualiza los archivos sin volver a publicarla y hace el commit (estado `Registrado`).

> **Push rechazado con `403 (Forbidden)`**: la API key no suele ser la causa (compruébalo: los demás paquetes se publican en la misma ejecución). Chocolatey rechaza una versión nueva mientras una anterior del mismo paquete siga retenida en moderación y el paquete no tenga ninguna versión estable aprobada, que es el caso de los que solo publican prereleases. Abre `https://community.chocolatey.org/packages/<id>/<versión anterior>`: si dice *Waiting for Maintainer*, corrige lo que pide el validador y vuelve a subir **esa misma versión** (`choco pack` y `choco push` en la carpeta del paquete con el nuspec todavía en esa versión; `-Force` solo sirve si no hay una versión más nueva, porque si la hay AU actualiza primero). Cuando quede exenta o aprobada, la siguiente ejecución publica la nueva.

> **Bridges de deprecación** (`deprecated/`, `push_deprecated.bat`): se publican como versión **prerelease** (`999.0.1-deprecated`), no estable. Los paquetes a los que redirigen solo publican prereleases, y `choco` solo resuelve una dependencia prerelease si el paquete que la pide también lo es (o con `--pre`). Comprobado con `choco` 2.7.4: con el bridge prerelease, `choco upgrade <id antiguo>` y `choco upgrade all` actualizan sin `--pre` e instalan el paquete nuevo; con un bridge estable fallan siempre con «Unable to resolve dependency». Una versión rechazada no se puede volver a subir: hay que subir el número (`999.0.2-deprecated`). Los IDs que llevan `beta` o `pre` fallan el requisito CPMR0024 del validador («el ID incluye un nombre de prerelease») y eso no tiene arreglo en el paquete, porque el ID es justo lo que se depreca: la versión queda *Waiting for Maintainer* hasta que el verificador la pruebe (una prerelease se aprueba entonces aunque la validación haya fallado, pero puede tardar días) o hasta que se explique en la revisión de su página que es la deprecación de un ID que ya existía. Ojo con el orden: si el validador se pronuncia después del comentario del mantenedor, el estado vuelve a *Waiting for Maintainer* y hay que responder otra vez para que quede en *Responded*, que es cuando lo ve un moderador. Las versiones anteriores de un ID retirado se ocultan (*unlist*) en la web, como pide la [guía oficial](https://docs.chocolatey.org/en-us/community-repository/maintainers/deprecate-a-chocolatey-package/); las de los seis IDs actuales ya lo están (ver «Cómo debe quedar un ID descontinuado»).

> **Nuevos iconos**: añade el PNG a `icons/`, haz commit y usa `https://cdn.jsdelivr.net/gh/DEUS-DEI/ChocoLateYPackages@<commit>/icons/<id>.png`.

### Análisis estático (PSScriptAnalyzer)

`PSScriptAnalyzerSettings.psd1` guarda la configuración del analizador: cada regla desactivada explica por qué no aplica y además se comprueba que la sintaxis funcione en Windows PowerShell 5.1. Desde la raíz del repo debe dar **cero avisos**:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser   # solo la primera vez
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

**PowerShell v2 no lo comprueba el analizador.** Los scripts de `tools/` se ejecutan al instalar y tienen que funcionar en PowerShell v2 (punto 7 de arriba), pero PSScriptAnalyzer solo sabe comprobar la sintaxis desde la 3.0 (con `2.0` no comprueba nada y no avisa), así que los cero avisos no lo garantizan. Esta búsqueda aparte no debe encontrar nada; cada patrón es algo que no existe en v2 (`[ordered]`, `[pscustomobject]`, `-in`/`-notin`, `$PSItem`, `$using:`, `$PSScriptRoot` fuera de módulos, `Where-Object Nombre -eq ...`, `::new()`, `class`, `#requires -Version 3` o más, `Get-Content -Raw`, `-NoNewline` y los cmdlets de la 3.0 en adelante). **No es exhaustiva**: busca lo más común, y que no encuentre nada no garantiza que el script funcione en v2; eso solo lo asegura probarlo con PowerShell v2.

```powershell
Select-String -Path .\*\tools\*.ps1 -Pattern '\[ordered\]', '\[pscustomobject\]', '\$PSItem\b', '\s-(not)?in\s', '::new\(', '\$using:', '^\s*class\s', '\$PSScriptRoot', 'Where-Object\s+\w+\s+-\w', 'Invoke-WebRequest', 'Invoke-RestMethod', 'ConvertFrom-Json', 'ConvertTo-Json', 'Get-CimInstance', '#requires\s+-version\s+[3-9]', 'Get-Content\b.*\s-Raw\b', '-NoNewline\b', '\[array\]\s*\$\w+\s*=.*Get-UninstallRegistryKey'
```

El último patrón busca `[array]$x = Get-UninstallRegistryKey ...`: el helper devuelve `$null` cuando no encuentra nada, y en v2 `$null` no tiene `.Count`. Se usa `@(Get-UninstallRegistryKey ... | Where-Object { $_ })`, que siempre es un array.

### Pruebas en Windows (Pester)

`tests/` prueba en Windows lo que el análisis estático no ve: los `.bat` en `cmd.exe`, `update_all.ps1` en Windows PowerShell 5.1 y los scripts de `tools/` con los helpers reales de Chocolatey. No publica nada (usa un `choco` falso) y no necesita administrador. Corre en cada PR (workflow `Tests`); en local:

```powershell
Invoke-Pester .\tests -Output Detailed   # Pester 5; ver tests/README.md
```

---
*Mantenido con ❤️ y automatización nivel Dios.*
