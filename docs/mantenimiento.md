# Cómo funciona y cómo se mantiene

Lo que hasta el 2026-11-14 estaba en el README: las características, las reglas de moderación que se cumplen, el uso
de los scripts y las notas de mantenimiento. El README se quedó con lo básico.

## Los IDs descontinuados

**Cómo debe quedar un ID descontinuado** (guía oficial de deprecación): una sola versión listada, el bridge `999.x-deprecated` exento o aprobado, y todas las versiones anteriores ocultas (*unlisted*). Quien tenga instalado el ID antiguo pasa al paquete nuevo con `choco upgrade`, y quien lo instale de cero recibe el paquete nuevo como dependencia. Las versiones anteriores de los seis IDs se ocultaron el 2026-10-08, sin esperar a que cada bridge estuviera listado: eran builds de 2022 (las de Fenix se cuelgan al instalar) y no convenía dejarlas a la vista. Mientras un bridge sigue en moderación, su ID no tiene ninguna versión instalable directamente; quien ya lo tenga instalado no nota nada. Ocultar es reversible (*Change Listing Status* en la página de cada versión).

La columna «Estado» de los bridges (README) es una foto del 2026-10-08; el estado al día se ve en [la lista de paquetes de la cuenta](https://community.chocolatey.org/profiles/DEUS-DEI). Los bridges `999.0.0` de `fenix-web-server-beta` y `github-desktop-beta` se enviaron en abril de 2026 y Chocolatey los rechazó el 19 de mayo, porque su dependencia no se podía satisfacer; ver la nota «Bridges de deprecación» más abajo.

## Estructura de un paquete

Cualquier carpeta de `Paquetes/actuales/` con un `update.ps1` se considera un paquete activo: no hay listas que mantener a mano. Solo se empaqueta `tools\` (elemento `<files>` del nuspec), así que `update.ps1` no viaja en el `.nupkg`.

Hasta el 2026-10-08 los paquetes activos estaban en la raíz y los bridges en `deprecated/`. Las versiones publicadas antes enlazan a esas rutas como «Package Source» y Chocolatey no deja corregir una versión ya publicada. Los paquetes activos enlazan a la ruta nueva desde su siguiente versión; un bridge no se vuelve a publicar, así que `deprecated/<id>/README.md` se queda para que su enlace siga abriendo.

Desde el 2026-11-14 los scripts de mantenimiento están en `Scripts/` y la documentación en `docs/`. `update_all.bat` y `vendor_catalog.bat` llevan su PowerShell dentro (antes eran `update_all.ps1` y `vendor_catalog.ps1`, cada uno con un `.bat` que solo lo lanzaba): la cabecera del `.bat` corre `Scripts\lib\Lanzar.ps1` con Windows PowerShell 5.1, que lee como PowerShell lo que va detrás de la línea `### POWERSHELL ###`. Los scripts de los paquetes (`update.ps1` y `tools\*.ps1`) siguen siendo `.ps1` en su carpeta: así los piden Chocolatey y Chocolatey-AU.

## 🧠 Características Inteligentes Implementadas

*   **Detección de Idioma y Bits**: Los paquetes de Thunderbird instalan el idioma de Windows (idioma de la interfaz y luego formato regional). Si Mozilla no publica ese idioma exacto prueban el idioma base (`de-DE` → `de`) o una variante (`es-CO` → `es-AR`) y, como último recurso, **`en-US`**. Se puede forzar con `--params "'/Language:es-MX /Arch:win32'"`.
*   **Gestión de Seguridad (Checksums)**: Cada paquete lleva el SHA256 del instalador calculado por AU (o copiado del manifiesto oficial de Mozilla), así que el binario se verifica siempre sin depender de descargas externas de checksums.
*   **URLs Inmutables**: WARP y Thunderbird Nightly apuntan a descargas versionadas (no a enlaces "latest"), por lo que el checksum embebido sigue siendo válido aunque el fabricante publique una build nueva.
*   **Orquestador Central (`Scripts\update_all.bat`)**: Un único script controla todo el ciclo de vida: búsqueda, actualización del nuspec y los scripts, empaquetado, subida (push) y commit. Si un push falla, la carpeta del paquete se restaura y la siguiente ejecución lo reintenta; solo se hace commit (limitado a esas carpetas) de lo que llegó a Chocolatey.
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
7.  **Compatibles con PowerShell v2**: los scripts que se ejecutan al instalar evitan sintaxis de PowerShell 3+ (requisito de la revisión de moderadores). La búsqueda que lo vigila está en [pruebas](pruebas.md).
8.  **Deprecación según la guía oficial**: los bridges llevan `[Deprecated]` en el título, `<files />`, sin icono y con dependencia con versión mínima, y son versiones prerelease para que esa dependencia se pueda resolver (nota «Bridges de deprecación»).
9.  **Checksums que el validador puede leer (CPMR0073)**: el validador automático no ejecuta los scripts, así que el checksum de cada descarga va escrito en `chocolateyinstall.ps1` como literal (o en una variable que solo recibe literales). Un checksum elegido al instalar (`$installer.Hash`, `$tabla['checksum']`, un archivo en `tools\`) verifica igual el binario, pero el validador lo marca como «descarga sin checksum» y retiene la versión. Por eso los Thunderbird llevan un `switch` con el SHA256 de cada idioma/arquitectura, que `update.ps1` reescribe en cada versión. Lo vigila `tests/Packages.Tests.ps1`.
10. **Instalación desatendida de verdad (Fenix 3.x)**: su instalador muestra, incluso con `/S`, un aviso que hay que aceptar («la aplicación recoge estadísticas de uso no personales») y no tiene parámetro para saltarlo, así que la instalación se quedaba esperando hasta agotar el tiempo. `Paquetes\actuales\fenix-web-server\tools\AcceptUsageNotice.ps1` responde OK a ese aviso (y solo a ese) mientras corre el instalador, y la descripción del paquete avisa de que instalar la prerelease lo acepta. Fenix 2.x no muestra ningún aviso.

## 🛠️ Cómo mantener este repo

Requisitos (una vez): Chocolatey y el módulo Chocolatey-AU.

```batch
choco install chocolatey-au
choco apikey add -k <TU_API_KEY> -s https://push.chocolatey.org/
```

Uso (desde la raíz del repositorio; cada script trabaja sobre el repositorio aunque se lance desde otra carpeta):

| Comando | Qué hace |
| :--- | :--- |
| `Scripts\menu.bat` | Panel interactivo |
| `Scripts\update_all.bat` | Actualiza y publica todo lo que tenga versión nueva |
| `Scripts\update_all.bat -Package nicepage -Force` | Re-empaqueta y sube un paquete aunque no haya versión nueva |
| `Scripts\update_all.bat -NoPush` | Solo empaqueta para revisar: deja los `.nupkg` y restaura los archivos, así la siguiente ejecución normal publica la versión nueva (si la hay: un paquete que solo se empaquetó por `-Force` no se publica) |
| `Scripts\update_all.bat -NoGit` | Publica en Chocolatey sin hacer commit/push en Git |
| `Scripts\update_all.bat -NoWinget` | No prepara las versiones para winget (ver [winget](winget.md)) |
| `Scripts\push_deprecated.bat` | Publica los bridges de `Paquetes/descontinuados/`. Termina con código 1 si falla algún empaquetado o push; `--no-pause` no espera una tecla al final |
| `cd Paquetes\actuales\nicepage` y `powershell -File update.ps1` | Prueba un solo paquete con AU |
| `Scripts\vendor_catalog.bat` | Lista el software para Windows de Mozilla, Cloudflare, GitHub, Google, Amazon, Cursor y Fenix con su última versión y su paquete en Chocolatey. Solo consulta (ver [el catálogo de fabricantes](vendor_catalog.md)) |
| `Scripts\vendor_catalog.bat -Install chrome,kiro` | Instala esos productos con el instalador oficial del fabricante, sin Chocolatey. También acepta nombres del índice de winget (`Google.QuickShare`) |

Desde PowerShell, sin `cmd.exe`, `update_all.bat` y `vendor_catalog.bat` se lanzan igual que lo hace su cabecera: `powershell -File Scripts\lib\Lanzar.ps1 Scripts\update_all.bat -NoPush`. En el mismo proceso (`& .\Scripts\lib\Lanzar.ps1 .\Scripts\vendor_catalog.bat -NoDiscover -PassThru`), `-PassThru` devuelve objetos.

En GitHub Actions la API Key se toma del secreto `CHOCO_API_KEY` (se puede configurar desde la opción 4 de `Scripts\menu.bat`).

En la PC, los scripts toman `CHOCO_API_KEY`, `GITHUB_TOKEN` (o `GH_TOKEN`) y `WINGET_TOKEN` con `Scripts\lib\Get-Secret.ps1`, en este orden: las variables de entorno (de la ejecución y las guardadas en Windows), el Administrador de credenciales de Windows (una credencial genérica con ese nombre) y, al final, un `.env.var`, `.dev.var`, `.env` o `.dev.vars` de la raíz del repositorio (`NOMBRE=valor`; todos en `.gitignore`). Ningún mensaje dice el valor ni de dónde salió. Sin ninguno, `choco` usa su `choco apikey`, como siempre.

> **Arreglos de un paquete ya aprobado sin versión nueva del software**: usa la notación de *fix version* (`2.0.0` → `2.0.0.20260926`). En `fenix-web-server` se declara en `$packageFixes` de su `update.ps1`, así que AU la publica solo en la siguiente ejecución.

> **Streams (`fenix-web-server`)**: cada ejecución publica por separado la versión estable y la prerelease. Si solo se publica una, la otra se reintenta en la siguiente ejecución. `-Force` re-empaqueta únicamente el stream que está en ese momento en la carpeta.

> **Versión publicada sin commit en Git** (p. ej. el runner no pudo hacer push): AU la salta porque ya existe en Chocolatey. `Scripts\update_all.bat` lo detecta, actualiza los archivos sin volver a publicarla y hace el commit (estado `Registrado`).

> **Push rechazado con `403 (Forbidden)`**: la API key no suele ser la causa (compruébalo: los demás paquetes se publican en la misma ejecución). Chocolatey rechaza una versión nueva mientras una anterior del mismo paquete siga retenida en moderación y el paquete no tenga ninguna versión estable aprobada, que es el caso de los que solo publican prereleases. Abre `https://community.chocolatey.org/packages/<id>/<versión anterior>`: si dice *Waiting for Maintainer*, corrige lo que pide el validador y vuelve a subir **esa misma versión** (`choco pack` y `choco push` en la carpeta del paquete con el nuspec todavía en esa versión; `-Force` solo sirve si no hay una versión más nueva, porque si la hay AU actualiza primero). Cuando quede exenta o aprobada, la siguiente ejecución publica la nueva.

> **Bridges de deprecación** (`Paquetes/descontinuados/`, `Scripts\push_deprecated.bat`): se publican como versión **prerelease** (`999.0.1-deprecated`), no estable. Los paquetes a los que redirigen solo publican prereleases, y `choco` solo resuelve una dependencia prerelease si el paquete que la pide también lo es (o con `--pre`). Comprobado con `choco` 2.7.4: con el bridge prerelease, `choco upgrade <id antiguo>` y `choco upgrade all` actualizan sin `--pre` e instalan el paquete nuevo; con un bridge estable fallan siempre con «Unable to resolve dependency». Una versión rechazada no se puede volver a subir: hay que subir el número (`999.0.2-deprecated`). Los IDs que llevan `beta` o `pre` fallan el requisito CPMR0024 del validador («el ID incluye un nombre de prerelease») y eso no tiene arreglo en el paquete, porque el ID es justo lo que se depreca: la versión queda *Waiting for Maintainer* hasta que el verificador la pruebe (una prerelease se aprueba entonces aunque la validación haya fallado, pero puede tardar días) o hasta que se explique en la revisión de su página que es la deprecación de un ID que ya existía. Ojo con el orden: si el validador se pronuncia después del comentario del mantenedor, el estado vuelve a *Waiting for Maintainer* y hay que responder otra vez para que quede en *Responded*, que es cuando lo ve un moderador. Las versiones anteriores de un ID retirado se ocultan (*unlist*) en la web, como pide la [guía oficial](https://docs.chocolatey.org/en-us/community-repository/maintainers/deprecate-a-chocolatey-package/); las de los seis IDs actuales ya lo están (ver «Los IDs descontinuados»).

> **Nuevos iconos**: añade el PNG a `icons/`, haz commit y usa `https://cdn.jsdelivr.net/gh/DEUS-DEI/ChocoLateYPackages@<commit>/icons/<id>.png`.
