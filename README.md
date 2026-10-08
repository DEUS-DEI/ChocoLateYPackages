# 📦 Mis Paquetes Chocolatey (100% Automatizados)

Este repositorio contiene una colección de paquetes de Chocolatey mantenidos de forma autónoma mediante el framework **[Chocolatey-AU](https://github.com/chocolatey-community/chocolatey-au)** y un orquestador centralizado (`update_all.ps1`).

## 🚀 Estado de la Automatización

GitHub Actions revisa, empaqueta y publica los paquetes **todos los días** (cron a las 04:47 UTC) y también bajo demanda (botón **Run workflow**, con opción de elegir paquetes o forzar). En local se usa `menu.bat`. `thunderbird-nightly` publica como máximo una build por semana para no saturar la cola de moderación.

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

IDs retirados: cada uno publica un *bridge* que lleva a quien lo tenga instalado al paquete actual.

| Paquete | Nivel | Método de Descubrimiento | Estado |
| :--- | :---: | :--- | :---: |
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
Paquetes/
├── actuales/<paquete>/           # Paquetes activos: los que revisa y publica update_all.ps1
│   ├── <paquete>.nuspec          # Metadatos (AU actualiza la versión)
│   ├── update.ps1                # Chocolatey-AU: au_GetLatest / au_SearchReplace del paquete
│   ├── <paquete>.json            # Solo fenix-web-server: versión publicada de cada stream (AU)
│   └── tools/
│       ├── chocolateyinstall.ps1   # URL + checksum literales (AU los actualiza; Thunderbird lleva uno por idioma/arquitectura)
│       └── chocolateyuninstall.ps1
└── descontinuados/<id>/          # IDs retirados: solo el nuspec del bridge (push_deprecated.bat)
icons/                            # Iconos de los paquetes (servidos por jsDelivr fijado a un commit)
deprecated/<id>/README.md         # Avisos de «se movió»: no borrar (ver abajo)
update_all.ps1 / .bat             # Orquestador: actualiza, publica y sincroniza Git
vendor_catalog.ps1 / .bat / .psd1 # Catálogo del software de los fabricantes e instalación directa (-Install)
menu.bat                          # Panel de control interactivo
tests/                            # Pruebas Pester en Windows (tests/README.md)
```

Cualquier carpeta de `Paquetes/actuales/` con un `update.ps1` se considera un paquete activo: no hay listas que mantener a mano. Solo se empaqueta `tools\` (elemento `<files>` del nuspec), así que `update.ps1` no viaja en el `.nupkg`.

Hasta el 2026-10-08 los paquetes activos estaban en la raíz y los bridges en `deprecated/`. Las versiones publicadas antes enlazan a esas rutas como «Package Source» y Chocolatey no deja corregir una versión ya publicada. Los paquetes activos enlazan a la ruta nueva desde su siguiente versión; un bridge no se vuelve a publicar, así que `deprecated/<id>/README.md` se queda para que su enlace siga abriendo.

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
10. **Instalación desatendida de verdad (Fenix 3.x)**: su instalador muestra, incluso con `/S`, un aviso que hay que aceptar («la aplicación recoge estadísticas de uso no personales») y no tiene parámetro para saltarlo, así que la instalación se quedaba esperando hasta agotar el tiempo. `Paquetes\actuales\fenix-web-server\tools\AcceptUsageNotice.ps1` responde OK a ese aviso (y solo a ese) mientras corre el instalador, y la descripción del paquete avisa de que instalar la prerelease lo acepta. Fenix 2.x no muestra ningún aviso.

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
| `.\push_deprecated.bat` | Publica los bridges de `Paquetes/descontinuados/`. Termina con código 1 si falla algún empaquetado o push; `--no-pause` no espera una tecla al final |
| `cd Paquetes\actuales\nicepage` y `powershell -File update.ps1` | Prueba un solo paquete con AU |
| `.\vendor_catalog.bat` | Lista el software para Windows de Mozilla, Cloudflare, GitHub, Google, Amazon, Cursor y Fenix con su última versión y su paquete en Chocolatey. Solo consulta (ver «Catálogo de fabricantes e instalación directa») |
| `.\vendor_catalog.bat -Install chrome,kiro` | Instala esos productos con el instalador oficial del fabricante, sin Chocolatey. También acepta nombres del índice de winget (`Google.QuickShare`) |

En GitHub Actions la API Key se toma del secreto `CHOCO_API_KEY` (se puede configurar desde la opción 4 de `menu.bat`).

> **Arreglos de un paquete ya aprobado sin versión nueva del software**: usa la notación de *fix version* (`2.0.0` → `2.0.0.20260926`). En `fenix-web-server` se declara en `$packageFixes` de su `update.ps1`, así que AU la publica solo en la siguiente ejecución.

> **Streams (`fenix-web-server`)**: cada ejecución publica por separado la versión estable y la prerelease. Si solo se publica una, la otra se reintenta en la siguiente ejecución. `-Force` re-empaqueta únicamente el stream que está en ese momento en la carpeta.

> **Versión publicada sin commit en Git** (p. ej. el runner no pudo hacer push): AU la salta porque ya existe en Chocolatey. `update_all.ps1` lo detecta, actualiza los archivos sin volver a publicarla y hace el commit (estado `Registrado`).

> **Push rechazado con `403 (Forbidden)`**: la API key no suele ser la causa (compruébalo: los demás paquetes se publican en la misma ejecución). Chocolatey rechaza una versión nueva mientras una anterior del mismo paquete siga retenida en moderación y el paquete no tenga ninguna versión estable aprobada, que es el caso de los que solo publican prereleases. Abre `https://community.chocolatey.org/packages/<id>/<versión anterior>`: si dice *Waiting for Maintainer*, corrige lo que pide el validador y vuelve a subir **esa misma versión** (`choco pack` y `choco push` en la carpeta del paquete con el nuspec todavía en esa versión; `-Force` solo sirve si no hay una versión más nueva, porque si la hay AU actualiza primero). Cuando quede exenta o aprobada, la siguiente ejecución publica la nueva.

> **Bridges de deprecación** (`Paquetes/descontinuados/`, `push_deprecated.bat`): se publican como versión **prerelease** (`999.0.1-deprecated`), no estable. Los paquetes a los que redirigen solo publican prereleases, y `choco` solo resuelve una dependencia prerelease si el paquete que la pide también lo es (o con `--pre`). Comprobado con `choco` 2.7.4: con el bridge prerelease, `choco upgrade <id antiguo>` y `choco upgrade all` actualizan sin `--pre` e instalan el paquete nuevo; con un bridge estable fallan siempre con «Unable to resolve dependency». Una versión rechazada no se puede volver a subir: hay que subir el número (`999.0.2-deprecated`). Los IDs que llevan `beta` o `pre` fallan el requisito CPMR0024 del validador («el ID incluye un nombre de prerelease») y eso no tiene arreglo en el paquete, porque el ID es justo lo que se depreca: la versión queda *Waiting for Maintainer* hasta que el verificador la pruebe (una prerelease se aprueba entonces aunque la validación haya fallado, pero puede tardar días) o hasta que se explique en la revisión de su página que es la deprecación de un ID que ya existía. Ojo con el orden: si el validador se pronuncia después del comentario del mantenedor, el estado vuelve a *Waiting for Maintainer* y hay que responder otra vez para que quede en *Responded*, que es cuando lo ve un moderador. Las versiones anteriores de un ID retirado se ocultan (*unlist*) en la web, como pide la [guía oficial](https://docs.chocolatey.org/en-us/community-repository/maintainers/deprecate-a-chocolatey-package/); las de los seis IDs actuales ya lo están (ver «Cómo debe quedar un ID descontinuado»).

> **Nuevos iconos**: añade el PNG a `icons/`, haz commit y usa `https://cdn.jsdelivr.net/gh/DEUS-DEI/ChocoLateYPackages@<commit>/icons/<id>.png`.

### Catálogo de fabricantes e instalación directa (`vendor_catalog.ps1`)

El script hace dos cosas con el software para Windows de Mozilla, Cloudflare, GitHub, Google, Amazon (Kiro incluido), Cursor y el autor de Fenix:

- **Informar** (sin `-Install`): qué publican hoy, en qué versión, y si tienen paquete en Chocolatey. Es solo consulta: no instala, no empaqueta, no publica y no escribe en el repositorio.
- **Instalar** (`-Install`): baja el instalador oficial del fabricante y lo instala en esta PC, **sin pasar por Chocolatey**.

#### Instalar

```batch
.\vendor_catalog.bat -Install firefox,kiro -WhatIf
.\vendor_catalog.bat -Install chrome,gh
```

Para cada producto pedido el script:

1. Pregunta la última versión al fabricante y resuelve la dirección de su instalador (solo `https`).
2. Pide confirmación (`-Yes` no pregunta; `-WhatIf` enseña lo que haría y no descarga nada).
3. Descarga el instalador a la carpeta temporal. Si la descarga acaba, por una redirección, en una dirección que no es `https`, se descarta.
4. Comprueba su **firma digital**: Windows tiene que darla por válida y, si el catálogo dice quién firma (`Signer`), tiene que ser ese. Si no, el archivo se borra sin ejecutarlo.
5. Lo ejecuta en silencio. Los instaladores para todos los usuarios piden elevación (UAC); los de usuario (Kiro, Cursor, GitHub Desktop) no.
6. Borra la descarga y resume el resultado. Termina con error si algún producto no se instaló.

Los nombres que acepta `-Install` son los de la columna **Instalar** del informe: `firefox`, `firefox-esr`, `firefox-beta`, `firefox-dev`, `firefox-nightly`, `thunderbird`, `thunderbird-esr`, `thunderbird-beta`, `thunderbird-daily`, `mozilla-vpn`, `warp`, `warp-beta`, `cloudflared`, `github-desktop`, `github-desktop-beta`, `gh`, `git-lfs`, `gcm`, `chrome`, `chrome-beta`, `chrome-dev`, `drive`, `earth-pro`, `chrome-remote-desktop`, `gcpw`, `gcloud`, `go`, `kiro`, `aws-cli`, `sam-cli`, `session-manager-plugin`, `corretto-21`, `corretto-25` y `cursor`.

Firefox y Thunderbird se bajan en el idioma de Windows (`-Language es-MX` para elegir otro); si el fabricante no tiene ese idioma, en inglés. El script no desinstala ni lleva la cuenta de lo instalado: volver a ejecutarlo instala la versión que haya en ese momento, que es como se actualiza.

`-Vendor`, `-NoDiscover` y `-OutFile` son del informe y no cuentan al instalar: un producto se instala sea del fabricante que sea. Si GitHub no responde, solo se quedan sin instalar los productos que salen de GitHub.

##### Todo lo demás: el índice de winget

No hay una lista oficial de todo lo que publica cada fabricante. La más completa es el [índice público de winget](https://github.com/microsoft/winget-pkgs), que mantiene la comunidad y valida Microsoft: unos 135 paquetes de estos fabricantes (Kindle, Amazon Music, WorkSpaces, todas las versiones de Corretto, Quick Share, Play Games, Antigravity, Android Studio, Gemini…). El informe los lista en una tabla aparte y `-Install` acepta sus nombres **tal cual están escritos allí**:

```batch
.\vendor_catalog.bat -Install Google.QuickShare,Amazon.Kindle -WhatIf
```

Con esos paquetes el script lee el manifiesto de su última versión y saca de ahí la dirección del instalador en el servidor del fabricante, su SHA256 y los argumentos silenciosos; descarga e instala él mismo, sin llamar a `winget` ni a Chocolatey. La regla de seguridad cambia en un punto: el archivo solo se ejecuta si su **SHA256 es el del manifiesto**, y entonces se acepta también un instalador sin firma digital (hay herramientas libres que no la llevan; el script lo avisa). Una firma rota se rechaza siempre.

Límites: solo paquetes de los editores del catálogo (`Winget` en el `.psd1`); solo instaladores `.msi` y `.exe` (los `.zip`, `.msix` y portables se dejan a `winget`); y un `.exe` cuyo manifiesto no diga cómo instalarlo en silencio no se instala. El índice puede ir unos días por detrás del fabricante y no dice si un producto sigue vivo: ahí siguen Picasa, Google Talk o Amazon Chime.

Para añadir un producto instalable basta darle en `vendor_catalog.psd1` un `Id` y un `Installer` (dirección fija, archivo de un release de GitHub o la que dé su fuente de versiones; argumentos silenciosos; firmante).

#### Informar

Para cada producto pregunta la última versión al fabricante y la del paquete a Chocolatey, y separa el resultado en **actuales** y **descontinuados**:

| Columna | Qué es |
| :--- | :--- |
| Versión, Fecha | Lo último que publica el fabricante (la fecha, cuando la fuente la da). `(ultima)` cuando el fabricante solo ofrece una descarga «latest» sin decir la versión |
| Chocolatey | ID y versión del paquete en el repositorio de la comunidad; `(atrasado)` si va por detrás del fabricante; `-` si no hay paquete |
| En este repo | `actual` si el paquete está en `Paquetes/actuales/`, y a qué IDs retirados sustituye |
| Instalar | El nombre para `-Install`, si el script sabe instalarlo |
| Nota | `repositorio archivado`, `sin versiones desde <año>` (tres años sin publicar) o el motivo anotado en el catálogo |

Los productos salen de tres sitios:

- **`vendor_catalog.psd1`**: los que tienen nombre propio (Firefox, Thunderbird, WARP, Chrome, Google Drive, Kiro, AWS CLI, Cursor, GitHub Desktop, gh…), con su canal, de dónde se lee la versión y el ID de su paquete en Chocolatey. Para añadir uno basta una línea.
- **Búsqueda en GitHub**: cualquier otro repositorio de las organizaciones de cada fabricante (lista `Owners` del `.psd1`) cuya última versión estable tenga una descarga para Windows. Aquí el único ID que se prueba en Chocolatey es el nombre del repositorio, y por eso lleva `(?)`: un paquete con el mismo nombre puede ser otro programa.

- **Índice de winget**: todo lo que registra de los editores de cada fabricante, en su propia tabla, con la versión que tiene el índice y el nombre para `-Install`.

Un producto es **descontinuado** si su repositorio está archivado o si el catálogo lo dice (`Status`); todo lo demás es actual.

| Comando | Qué hace |
| :--- | :--- |
| `.\vendor_catalog.bat` | Todo: unos 225 productos. Tarda unos cinco minutos, casi todo en recorrer las organizaciones de Google y Amazon en GitHub |
| `.\vendor_catalog.bat -NoDiscover` | Solo los productos del `.psd1` (medio minuto), sin buscar en GitHub ni leer el índice de winget |
| `.\vendor_catalog.bat -Vendor Cloudflare,GitHub` | Solo esos fabricantes (vale el principio del nombre: `Fenix`) |
| `.\vendor_catalog.bat -OutFile catalogo.md` | Guarda además el informe en Markdown |
| `.\vendor_catalog.ps1 -PassThru` | Devuelve objetos en vez de tablas, para `Where-Object`, `Export-Csv`… |

GitHub se consulta por su API GraphQL, que pide un token: la variable `GITHUB_TOKEN` (o `GH_TOKEN`) o la sesión de GitHub CLI (`gh auth login`). El token solo se envía a `api.github.com`. Sin token, los productos alojados en GitHub salen sin versión y no se hace la búsqueda.

### Análisis estático (PSScriptAnalyzer)

`PSScriptAnalyzerSettings.psd1` guarda la configuración del analizador: cada regla desactivada explica por qué no aplica y además se comprueba que la sintaxis funcione en Windows PowerShell 5.1. Desde la raíz del repo debe dar **cero avisos**:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser   # solo la primera vez
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
```

**PowerShell v2 no lo comprueba el analizador.** Los scripts de `tools/` se ejecutan al instalar y tienen que funcionar en PowerShell v2 (punto 7 de arriba), pero PSScriptAnalyzer solo sabe comprobar la sintaxis desde la 3.0 (con `2.0` no comprueba nada y no avisa), así que los cero avisos no lo garantizan. Esta búsqueda aparte no debe encontrar nada; cada patrón es algo que no existe en v2 (`[ordered]`, `[pscustomobject]`, `-in`/`-notin`, `$PSItem`, `$using:`, `$PSScriptRoot` fuera de módulos, `Where-Object Nombre -eq ...`, `::new()`, `class`, `#requires -Version 3` o más, `Get-Content -Raw`, `-NoNewline` y los cmdlets de la 3.0 en adelante). **No es exhaustiva**: busca lo más común, y que no encuentre nada no garantiza que el script funcione en v2; eso solo lo asegura probarlo con PowerShell v2.

```powershell
Select-String -Path .\Paquetes\actuales\*\tools\*.ps1 -Pattern '\[ordered\]', '\[pscustomobject\]', '\$PSItem\b', '\s-(not)?in\s', '::new\(', '\$using:', '^\s*class\s', '\$PSScriptRoot', 'Where-Object\s+\w+\s+-\w', 'Invoke-WebRequest', 'Invoke-RestMethod', 'ConvertFrom-Json', 'ConvertTo-Json', 'Get-CimInstance', '#requires\s+-version\s+[3-9]', 'Get-Content\b.*\s-Raw\b', '-NoNewline\b', '\[array\]\s*\$\w+\s*=.*Get-UninstallRegistryKey'
```

El último patrón busca `[array]$x = Get-UninstallRegistryKey ...`: el helper devuelve `$null` cuando no encuentra nada, y en v2 `$null` no tiene `.Count`. Se usa `@(Get-UninstallRegistryKey ... | Where-Object { $_ })`, que siempre es un array.

### Pruebas en Windows (Pester)

`tests/` prueba en Windows lo que el análisis estático no ve: los `.bat` en `cmd.exe`, `update_all.ps1` en Windows PowerShell 5.1 y los scripts de `tools/` con los helpers reales de Chocolatey. No publica nada (usa un `choco` falso) y no necesita administrador. Corre en cada PR (workflow `Tests`); en local:

```powershell
Invoke-Pester .\tests -Output Detailed   # Pester 5; ver tests/README.md
```

---
*Mantenido con ❤️ y automatización nivel Dios.*
