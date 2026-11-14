# ChocoLateYPackages: reglas para trabajar en este repositorio

Paquetes de Chocolatey actualizados solos con Chocolatey-AU. El README es la presentacion corta (paquetes, uso,
estructura); el detalle esta en `docs/`: `docs/mantenimiento.md` (como funciona, las reglas de moderacion, el uso de
los scripts y las notas), `docs/winget.md`, `docs/vendor_catalog.md` y `docs/pruebas.md`. Ver "Documentos y agentes"
abajo.

## Idioma y forma
- Responder al usuario en espanol. Los mensajes de commit siguen el estilo del log: ingles, `fix:`, `feat:`,
  `chore:`, `docs:`.
- Los cambios van por PR a `main`. La accion `.github/workflows/update_packages.yml` publica en Chocolatey y hace
  commits en `main` todos los dias a las 04:47 UTC: no ejecutarla, no empaquetar ni publicar nada, y contar con que
  `main` avanza sola (traer `main` antes de subir una rama).
- Con el CI en verde se fusiona, sin esperar a que el usuario lo pida (lo pidio el 2026-10-13, para todos sus
  repositorios). Un PR abierto en la sesion se fusiona con commit de merge (`gh pr merge --merge`) en cuanto su
  ultimo commit tiene en verde `Tests / test` y el estado `Devin Review`, GitHub lo da por fusionable (sin
  conflictos) y no queda ningun comentario de revision por contestar; GitHub borra la rama al fusionar. Rojo,
  pendiente o con conflicto: se arregla primero. No cambia lo de "Sin pruebas ni tests" ni vale para un PR que el
  usuario pida no fusionar o que no abrio la sesion (el repositorio es publico: el PR de un tercero nunca se fusiona
  sin que el usuario lo diga). La fusion automatica de GitHub (auto-merge) esta activada, pero `main` no exige
  comprobaciones (el ruleset "Proteger main" solo impide borrarla y el push forzado), asi que nada hace esperar a
  `gh pr merge --auto`: la fusion la hace la sesion.

## Estructura
- `Scripts/`: los scripts de mantenimiento (desde el 2026-11-14; antes en la raiz). `update_all.bat` y
  `vendor_catalog.bat` llevan su PowerShell dentro, detras de la linea `### POWERSHELL ###`: la cabecera batch corre
  `Scripts\lib\Lanzar.ps1` con Windows PowerShell 5.1, que lee esa parte con la ruta del .bat como su archivo
  (`$PSScriptRoot` es `Scripts`; la raiz del repositorio es `$repoRoot`, la carpeta de encima). `menu.bat` y
  `push_deprecated.bat` son batch y trabajan desde la raiz (`pushd "%~dp0.."`). `Scripts/lib/`: `Lanzar.ps1`
  (`Get-ChocoSeccionBat`: la parte PowerShell de un .bat como bloque, o con `-Texto` como texto), `Get-Secret.ps1` y
  `vendor_catalog.psd1`. Un script nuevo va igual: un `.bat` en `Scripts/` con su PowerShell dentro, nunca un `.ps1`
  suelto con un `.bat` que solo lo lanza. Los `update.ps1` y `tools\*.ps1` de los paquetes NO: Chocolatey y AU los
  piden como `.ps1` en su carpeta.
- `Paquetes/actuales/<id>/`: paquetes activos. Los revisa y publica `Scripts/update_all.bat`, que toma cualquier
  carpeta de ahi que tenga un `update.ps1`.
- `Paquetes/descontinuados/<id>/`: IDs retirados; solo el nuspec del bridge (`Scripts/push_deprecated.bat`).
- `deprecated/<id>/README.md`: avisos de "se movio". No borrarlos: las versiones ya publicadas en Chocolatey enlazan
  a esa ruta como "Package Source" y un bridge no se vuelve a publicar.
- Al mover o renombrar la carpeta de un paquete, actualizar su `packageSourceUrl`.
- `Paquetes/actuales/<id>/winget/`: lo que va a winget (`docs/winget.md`). `Scripts/update_all.bat` prepara los
  manifiestos de cada version que publica y solo los envia con `WINGET_SUBMIT=true` y `WINGET_TOKEN`. El usuario
  pidio el 2026-10-30 que no se envie nada todavia: no crear esa variable ni ese secreto, ni ejecutar
  `komac submit` o `komac update --submit`, salvo que lo pida. Las plantillas `*.yaml` y los `winget.psd1`, en ASCII.
- `Scripts/vendor_catalog.bat` (datos en `Scripts/lib/vendor_catalog.psd1`): catalogo del software de los
  fabricantes (`docs/vendor_catalog.md`). Sin `-Install` solo consulta a los fabricantes, a GitHub y a Chocolatey; no
  empaqueta, no publica y no escribe en el repositorio.
- `Scripts/vendor_catalog.bat -Install <nombre>` descarga y ejecuta instaladores en la PC del usuario. No ejecutarlo sin
  `-WhatIf` salvo que el usuario lo pida para un producto concreto. Un producto nuevo solo entra como instalable con
  una descarga `https` del fabricante y su firmante (`Signer`), leido de la firma del instalador real: sin el no se
  instala. Los nombres con punto (`Google.QuickShare`) son paquetes del indice de winget de los editores de `Winget`
  en el `.psd1`: se instalan desde la direccion de su manifiesto y solo si el SHA256 coincide.

## Compatibilidad
- Los scripts de `Paquetes/actuales/*/tools/` se ejecutan al instalar y tienen que funcionar en **PowerShell v2**
  (regla de los moderadores). PSScriptAnalyzer no puede comprobarlo; lo mira la busqueda con `Select-String` de
  `docs/pruebas.md` (seccion "Analisis estatico"), que solo se corre si el usuario pide pruebas ("Sin pruebas ni
  tests"). Ante la duda, evitar cualquier cosa de v3 o posterior.
- En esos scripts, el checksum de cada descarga (`Install-ChocolateyPackage`, `Install-ChocolateyZipPackage`,
  `Get-ChocolateyWebFile`) va escrito en el script: un literal, o una variable que solo recibe literales. El
  validador de Chocolatey no ejecuta el script (regla CPMR0073): si el checksum sale de un objeto, una tabla o un
  archivo, retiene la version en moderacion y Chocolatey responde 403 a las siguientes. Lo comprueba
  `tests/Packages.Tests.ps1`; `docs/mantenimiento.md`, "Cumplimiento" punto 9 y nota "Push rechazado con 403".
- La parte PowerShell de `Scripts/update_all.bat` y `Scripts/vendor_catalog.bat`, y los `update.ps1`, corren en
  Windows PowerShell 5.1 (la cabecera de cada .bat, `menu.bat` y el workflow, que llama a `Scripts\update_all.bat`).
- Codificacion: los `chocolateyinstall.ps1` son UTF-8 con BOM; los demas `.ps1`, ASCII. Los `.bat` en ASCII y CRLF
  (`.gitattributes`: `eol=crlf`), tambien los que llevan PowerShell dentro: un BOM rompe el `@echo off`.
- Las funciones `au_GetLatest` y `au_SearchReplace` las llama Chocolatey-AU con su firma; no cambiarlas de forma.
  `au_GetLatest` debe devolver solo lo que AU espera (nada de `Write-Output` extra).

## Sin pruebas ni tests
- Lo pidio el usuario el 2026-10-20, para acelerar el trabajo: antes de subir no se corren tests ni pruebas (ni
  `Invoke-ScriptAnalyzer`, ni `Invoke-Pester`, ni la busqueda de `docs/pruebas.md`, ni nada que "compruebe" el
  cambio), no se escriben pruebas nuevas ni se rompe nada a proposito para comprobarlas. Se hace el cambio, se sube y
  listo; el PR se fusiona con el CI en verde, como arriba. Si el usuario detecta un error, lo pide y se arregla.
- Solo se corren pruebas si el usuario las pide expresamente; entonces, las de siempre (`docs/pruebas.md`):
  `Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./tests/PSScriptAnalyzerSettings.psd1` mas la parte PowerShell de
  cada `Scripts\*.bat` con `-ScriptDefinition` (cero avisos; una regla solo se apaga con un comentario que diga por
  que no aplica) e `Invoke-Pester .\tests` (Pester 5, Windows PowerShell 5.1). Las pruebas usan un `choco` falso y no
  publican nada; una prueba nueva tiene que seguir sin tocar Chocolatey, GitHub ni el sistema.

## Secretos
- La API key de Chocolatey vive en el secreto `CHOCO_API_KEY` de GitHub y en `choco apikey` de la PC. Nunca
  imprimirla ni escribirla en el repositorio. Lo mismo con el token de winget (`WINGET_TOKEN`), cuando exista.
- En la PC los scripts los toman con `Scripts/lib/Get-Secret.ps1`, en el orden de todos los repositorios del dueno
  (entorno, credencial de Windows, `.env.var`/`.dev.var` de la raiz), sin decir nunca el valor ni de donde salio.

## Documentos y agentes (2026-11-14)
- Lo pidio el usuario para todos sus repositorios ("script en carpetas Scripts, md documentacion y otros relacionados
  en docs ... todo para poder tener ordenado todo"): los scripts van en `Scripts/` y la documentacion en `docs/`. En
  la raiz quedan solo `README.md` (presentacion corta: paquetes, uso, estructura y la lista de `docs/`), `CLAUDE.md`,
  `AGENTS.md` y lo que piden las herramientas (`Paquetes/`, `deprecated/`, `icons/`, `tests/`, `.github/`). Un
  documento nuevo va en `docs/`. Los `README.md` de `deprecated/<id>/` se quedan donde estan (ver "Estructura").
- `CLAUDE.md` se queda en la raiz: las sesiones que trabajan desde la carpeta que tiene todos los repositorios (fuera
  de este) solo cargan el `CLAUDE.md` de la raiz del repositorio, al leer sus archivos; tambien lo leen Devin y la
  revision de Copilot.
- `AGENTS.md` (raiz): lo mismo, resumido, para Codex, Copilot, Cursor, Gemini, Devin y los demas agentes que leen
  ese archivo; remite aqui para lo completo. Si una regla cambia aqui, se cambia tambien alla.
