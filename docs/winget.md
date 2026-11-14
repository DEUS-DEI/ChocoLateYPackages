# winget (`Paquetes/actuales/<paquete>/winget/`)

Hasta el 2026-11-14 era la sección «winget» del README.

Algunos paquetes van también al [repositorio de la comunidad de winget](https://github.com/microsoft/winget-pkgs). Allí no se sube un paquete: cada versión es un PR con tres manifiestos YAML (dirección del instalador del fabricante, su SHA256 y cómo instalarlo) que Microsoft valida instalándolo en una máquina virtual y que aprueba un moderador.

**Ahora mismo no se envía nada.** `Scripts\update_all.bat` prepara los manifiestos de cada versión que publica en Chocolatey (estado `Actualizado`) y solo los envía si la variable `WINGET_SUBMIT` vale `true` y `WINGET_TOKEN` tiene el token de GitHub. Ninguna de las dos existe todavía.

| Paquete | ID en winget | Manifiestos |
| :--- | :--- | :--- |
| `github-desktop-pre` | `GitHub.GitHubDesktop.Beta` (ya existe; iba por 3.5.5-beta2) | `komac update` |
| `nicepage` | `ArtisteerLimited.Nicepage` (ya existe; iba por 6.3.1) | `komac update` |
| `cloudflare-warp-pre` | `Cloudflare.Warp.Beta` (nuevo) | Plantillas |
| `thunderbird-mozilla` | `Mozilla.Thunderbird.Beta` (nuevo; en-US, como `Mozilla.Thunderbird`) | Plantillas |
| `fenix-web-server` | `CoreyButler.FenixWebServer` 2.0.0 (nuevo) | Manifiesto fijo, se envía una vez a mano |

Fuera de winget: `thunderbird-nightly` (todas las builds de un ciclo se llaman igual en Windows, `161.0a1`, así que winget no sabría cuál está instalada), `flarectl` (Cloudflare solo lo publica en `.tar.gz` y winget solo admite `.zip`) y Fenix 3.x (su instalador se para en un aviso aunque sea silencioso, y winget no admite scripts como `AcceptUsageNotice.ps1`).

**Cómo se hacen los manifiestos:**

- **`komac update`** (carpeta `winget/` con solo `winget.psd1`): [Komac](https://github.com/russellbanks/Komac) parte de los manifiestos de la versión anterior que ya están en winget y cambia la versión y los instaladores, que descarga y analiza (SHA256, `ProductCode`…).
- **Plantillas** (`*.yaml` en `winget/`): `Scripts\update_all.bat` rellena lo que va entre llaves dobles (versión, direcciones y SHA256 de los instaladores, que descarga) y deja los manifiestos en `winget-manifests\<ID>\<versión>\` (en la raíz del repositorio), que no va a Git. Se envían tal cual con `komac submit`. Thunderbird las usa siempre, porque Komac toma el instalador de Mozilla por un programa portátil de 32 bits; WARP, porque su ID todavía no existe en winget y `komac update` no tiene de dónde partir. Cuando `Cloudflare.Warp.Beta` ya esté en winget se pueden borrar sus `*.yaml`, y pasa a `komac update`, que añade el `ProductCode` del MSI.

`winget.psd1` dice el `Id`, la `Version` y los `Installers` (nombre = dirección de descarga), y opcionalmente `VersionPattern` (expresión regular cuyo grupo `v` es la versión para winget) y `ReleaseNotesUrl`. `{Clave}` es el dato `Clave` del `$Latest` de Chocolatey-AU (lo que devuelve `au_GetLatest` del `update.ps1`). Si la versión no tiene la forma esperada no se prepara nada, para no mandar una versión equivocada.

Al terminar, `Scripts\update_all.bat` muestra una tabla con cada versión: `Preparado` (manifiestos listos; en el workflow, los de plantilla se guardan en el artefacto `winget-manifests` y los de Komac salen en el log), `Enviado` (PR abierto), `Aviso` (no se pudo preparar; no marca la ejecución en rojo porque la versión ya está en Chocolatey) o `Error` (falló el envío: la ejecución termina con código 1). Una versión que no se envió no se reintenta: winget recibe la siguiente.

**Para empezar a enviar:**

1. Crea un token **clásico** de GitHub con el permiso `public_repo` (Komac no puede abrir el PR con uno de grano fino) y guárdalo como secreto `WINGET_TOKEN` del repositorio. Komac crea solo el fork `DEUS-DEI/winget-pkgs` desde el que abre los PR.
2. Crea la variable de repositorio `WINGET_SUBMIT` con el valor `true` (*Settings → Secrets and variables → Actions → Variables*). Para dejar de enviar, bórrala o cámbiale el valor.
3. En el primer PR, un bot de Microsoft pide firmar su acuerdo de contribución (CLA) con un comentario: hay que hacerlo una vez.
4. Fenix 2.0.0 no cambia, así que `Scripts\update_all.bat` nunca lo envía: se manda una vez a mano, con Komac instalado (`winget install komac`) y el token en `GITHUB_TOKEN`:

```powershell
$env:GITHUB_TOKEN = '<token>'
komac submit --yes Paquetes\actuales\fenix-web-server\winget
```

En local valen las mismas variables de entorno; sin Komac instalado, los paquetes de `komac update` salen como `Aviso`. Para probar un manifiesto antes de enviarlo: `winget settings --enable LocalManifestFiles` (como administrador) y `winget install --manifest winget-manifests\<ID>\<versión>`.
