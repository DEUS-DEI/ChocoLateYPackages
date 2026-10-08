# ChocoLateYPackages: reglas para trabajar en este repositorio

Paquetes de Chocolatey actualizados solos con Chocolatey-AU. El README explica la estructura, las reglas de moderacion
y como mantenerlo.

## Idioma y forma
- Responder al usuario en espanol. Los mensajes de commit siguen el estilo del log: ingles, `fix:`, `feat:`,
  `chore:`, `docs:`.
- Los cambios van por PR a `main`. La accion `.github/workflows/update_packages.yml` publica en Chocolatey y hace
  commits en `main` todos los dias a las 04:47 UTC: no ejecutarla, no empaquetar ni publicar nada, y contar con que
  `main` avanza sola (traer `main` antes de subir una rama).

## Estructura
- `Paquetes/actuales/<id>/`: paquetes activos. Los revisa y publica `update_all.ps1`, que toma cualquier carpeta de
  ahi que tenga un `update.ps1`.
- `Paquetes/descontinuados/<id>/`: IDs retirados; solo el nuspec del bridge (`push_deprecated.bat`).
- `deprecated/<id>/README.md`: avisos de "se movio". No borrarlos: las versiones ya publicadas en Chocolatey enlazan
  a esa ruta como "Package Source" y un bridge no se vuelve a publicar.
- Al mover o renombrar la carpeta de un paquete, actualizar su `packageSourceUrl`.
- `vendor_catalog.ps1` (datos en `vendor_catalog.psd1`): catalogo del software de los fabricantes. Sin `-Install` solo
  consulta a los fabricantes, a GitHub y a Chocolatey; no empaqueta, no publica y no escribe en el repositorio.
- `vendor_catalog.ps1 -Install <nombre>` descarga y ejecuta instaladores en la PC del usuario. No ejecutarlo sin
  `-WhatIf` salvo que el usuario lo pida para un producto concreto. Un producto nuevo solo entra como instalable con
  una descarga `https` del fabricante y su firmante (`Signer`), leido de la firma del instalador real: sin el no se
  instala. Los nombres con punto (`Google.QuickShare`) son paquetes del indice de winget de los editores de `Winget`
  en el `.psd1`: se instalan desde la direccion de su manifiesto y solo si el SHA256 coincide.

## Compatibilidad
- Los scripts de `Paquetes/actuales/*/tools/` se ejecutan al instalar y tienen que funcionar en **PowerShell v2**
  (regla de los moderadores). PSScriptAnalyzer no puede comprobarlo: pasar ademas la busqueda con `Select-String` del
  README (seccion "Analisis estatico") y, ante la duda, evitar cualquier cosa de v3 o posterior.
- En esos scripts, el checksum de cada descarga (`Install-ChocolateyPackage`, `Install-ChocolateyZipPackage`,
  `Get-ChocolateyWebFile`) va escrito en el script: un literal, o una variable que solo recibe literales. El
  validador de Chocolatey no ejecuta el script (regla CPMR0073): si el checksum sale de un objeto, una tabla o un
  archivo, retiene la version en moderacion y Chocolatey responde 403 a las siguientes. Lo comprueba
  `tests/Packages.Tests.ps1`; README, "Cumplimiento" punto 9 y nota "Push rechazado con 403".
- `update_all.ps1` y los `update.ps1` corren en Windows PowerShell 5.1 (`update_all.bat`, `menu.bat` y el workflow).
- Codificacion: los `chocolateyinstall.ps1` son UTF-8 con BOM; los demas `.ps1`, ASCII. Los `.bat` en CRLF.

## Antes de subir
- `Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1`: cero avisos. Una regla solo se
  apaga con un comentario que diga por que no aplica.
- `Invoke-Pester .\tests` (Pester 5, Windows PowerShell 5.1): todo en verde. Usa un `choco` falso y no publica nada
  (`tests/README.md`); cualquier prueba nueva tiene que seguir sin tocar Chocolatey, GitHub ni el sistema.
- Las funciones `au_GetLatest` y `au_SearchReplace` las llama Chocolatey-AU con su firma; no cambiarlas de forma.
  `au_GetLatest` debe devolver solo lo que AU espera (nada de `Write-Output` extra).

## Secretos
- La API key de Chocolatey vive en el secreto `CHOCO_API_KEY` de GitHub y en `choco apikey` de la PC. Nunca
  imprimirla ni escribirla en el repositorio.
