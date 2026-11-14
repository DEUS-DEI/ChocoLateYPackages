# Catálogo de fabricantes e instalación directa (`Scripts\vendor_catalog.bat`)

Hasta el 2026-11-14 era la sección del mismo nombre del README, y el script era `vendor_catalog.ps1` (con sus datos
en `vendor_catalog.psd1`, hoy `Scripts\lib\vendor_catalog.psd1`).

El script hace dos cosas con el software para Windows de Mozilla, Cloudflare, GitHub, Google, Amazon (Kiro incluido), Cursor y el autor de Fenix:

- **Informar** (sin `-Install`): qué publican hoy, en qué versión, y si tienen paquete en Chocolatey. Es solo consulta: no instala, no empaqueta, no publica y no escribe en el repositorio.
- **Instalar** (`-Install`): baja el instalador oficial del fabricante y lo instala en esta PC, **sin pasar por Chocolatey**.

## Instalar

```batch
Scripts\vendor_catalog.bat -Install firefox,kiro -WhatIf
Scripts\vendor_catalog.bat -Install chrome,gh
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

### Todo lo demás: el índice de winget

No hay una lista oficial de todo lo que publica cada fabricante. La más completa es el [índice público de winget](https://github.com/microsoft/winget-pkgs), que mantiene la comunidad y valida Microsoft: unos 135 paquetes de estos fabricantes (Kindle, Amazon Music, WorkSpaces, todas las versiones de Corretto, Quick Share, Play Games, Antigravity, Android Studio, Gemini…). El informe los lista en una tabla aparte y `-Install` acepta sus nombres **tal cual están escritos allí**:

```batch
Scripts\vendor_catalog.bat -Install Google.QuickShare,Amazon.Kindle -WhatIf
```

Con esos paquetes el script lee el manifiesto de su última versión y saca de ahí la dirección del instalador en el servidor del fabricante, su SHA256 y los argumentos silenciosos; descarga e instala él mismo, sin llamar a `winget` ni a Chocolatey. La regla de seguridad cambia en un punto: el archivo solo se ejecuta si su **SHA256 es el del manifiesto**, y entonces se acepta también un instalador sin firma digital (hay herramientas libres que no la llevan; el script lo avisa). Una firma rota se rechaza siempre.

Límites: solo paquetes de los editores del catálogo (`Winget` en el `.psd1`); solo instaladores `.msi` y `.exe` (los `.zip`, `.msix` y portables se dejan a `winget`); y un `.exe` cuyo manifiesto no diga cómo instalarlo en silencio no se instala. El índice puede ir unos días por detrás del fabricante y no dice si un producto sigue vivo: ahí siguen Picasa, Google Talk o Amazon Chime.

Para añadir un producto instalable basta darle en `Scripts\lib\vendor_catalog.psd1` un `Id` y un `Installer` (dirección fija, archivo de un release de GitHub o la que dé su fuente de versiones; argumentos silenciosos; firmante).

## Informar

Para cada producto pregunta la última versión al fabricante y la del paquete a Chocolatey, y separa el resultado en **actuales** y **descontinuados**:

| Columna | Qué es |
| :--- | :--- |
| Versión, Fecha | Lo último que publica el fabricante (la fecha, cuando la fuente la da). `(ultima)` cuando el fabricante solo ofrece una descarga «latest» sin decir la versión |
| Chocolatey | ID y versión del paquete en el repositorio de la comunidad; `(atrasado)` si va por detrás del fabricante; `-` si no hay paquete |
| En este repo | `actual` si el paquete está en `Paquetes/actuales/`, y a qué IDs retirados sustituye |
| Instalar | El nombre para `-Install`, si el script sabe instalarlo |
| Nota | `repositorio archivado`, `sin versiones desde <año>` (tres años sin publicar) o el motivo anotado en el catálogo |
| winget | El paquete del producto en el índice de winget y su última versión; `-` si no lo tiene. Vacía con `-NoDiscover` o sin token, porque entonces no se lee el índice |
| Descarga | Lo que publica el fabricante para Windows (`exe, msi`, `zip`, `tar.gz`, `npm`…): los archivos del release de GitHub o, si no, lo que dice `Format` en el `.psd1` |
| Se puede (choco), Se puede (winget) | `ya` (hay paquete; `ya (?)`, uno con el nombre del repositorio), `si` (se podría hacer), `no (motivo)`, `preparado: <ID>` (este repositorio lo deja listo para winget, ver [winget](winget.md)) o `?` (no hay datos) |

Las columnas winget, Descarga y Se puede salen en el Markdown dentro de cada tabla y en la consola en una tabla aparte, **CHOCOLATEY Y WINGET**, con un resumen al final. Cómo decide «Se puede»:

- Chocolatey instala cualquier formato, así que basta una descarga para Windows; un paquete de npm solo se puede con Node.js como dependencia.
- winget solo admite `msi`, `msix`, `exe` y `zip`, sin scripts y sin preguntas: un `.tar.gz`, un `.7z` o una DLL suelta dan `no`. Sin el índice no se sabe si ya está, y sale `?`.
- Lo que no se ve en los archivos va en el `.psd1`: `Winget` (ID del paquete), `NoPackage` (por qué no se empaqueta: una extensión de `gh`, una biblioteca, un complemento) y `NoWinget` (por qué no vale para winget), en cada producto o, para los repositorios que encuentra la búsqueda, en `Repos` (con su nombre o un patrón como `github/gh-*`). `Repos` también da el `Choco` de un repositorio cuyo paquete no se llama como él (`google/flatbuffers` → `flatc`).
- En la tabla del índice de winget, la columna Chocolatey es el paquete del producto con ese ID o el que da `WingetChoco`; `WingetNoChoco` dice por qué uno no puede tenerlo (retirado, versión sin soporte…).

Los productos salen de tres sitios:

- **`Scripts\lib\vendor_catalog.psd1`**: los que tienen nombre propio (Firefox, Thunderbird, WARP, Chrome, Google Drive, Kiro, AWS CLI, Cursor, GitHub Desktop, gh…), con su canal, de dónde se lee la versión y el ID de su paquete en Chocolatey. Para añadir uno basta una línea.
- **Búsqueda en GitHub**: cualquier otro repositorio de las organizaciones de cada fabricante (lista `Owners` del `.psd1`) cuya última versión estable tenga una descarga para Windows. Aquí el único ID que se prueba en Chocolatey es el nombre del repositorio, y por eso lleva `(?)`: un paquete con el mismo nombre puede ser otro programa.
- **Índice de winget**: todo lo que registra de los editores de cada fabricante, en su propia tabla, con la versión que tiene el índice y el nombre para `-Install`.

Un producto es **descontinuado** si su repositorio está archivado o si el catálogo lo dice (`Status`); todo lo demás es actual.

El informe guardado en [`catalogo-fabricantes.md`](catalogo-fabricantes.md) es una de estas ejecuciones; para ponerlo al día basta `Scripts\vendor_catalog.bat -OutFile docs\catalogo-fabricantes.md` (desde la raíz del repositorio).

| Comando | Qué hace |
| :--- | :--- |
| `Scripts\vendor_catalog.bat` | Todo: unos 225 productos. Tarda unos cinco minutos, casi todo en recorrer las organizaciones de Google y Amazon en GitHub |
| `Scripts\vendor_catalog.bat -NoDiscover` | Solo los productos del `.psd1` (medio minuto), sin buscar en GitHub ni leer el índice de winget |
| `Scripts\vendor_catalog.bat -Vendor Cloudflare,GitHub` | Solo esos fabricantes (vale el principio del nombre: `Fenix`) |
| `Scripts\vendor_catalog.bat -OutFile catalogo.md` | Guarda además el informe en Markdown |
| `& .\Scripts\lib\Lanzar.ps1 .\Scripts\vendor_catalog.bat -PassThru` | Desde PowerShell: devuelve objetos en vez de tablas, para `Where-Object`, `Export-Csv`… |

GitHub se consulta por su API GraphQL, que pide un token: la variable `GITHUB_TOKEN` (o `GH_TOKEN`) o la sesión de GitHub CLI (`gh auth login`). El token solo se envía a `api.github.com`. Sin token, los productos alojados en GitHub salen sin versión y no se hace la búsqueda.
