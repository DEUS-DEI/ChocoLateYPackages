# ChocoLateYPackages: reglas para trabajar en este repositorio

Paquetes de Chocolatey actualizados solos con Chocolatey-AU. El README explica la estructura, las reglas de moderacion
y como mantenerlo.

## Idioma y forma
- Responder al usuario en espanol. Los mensajes de commit siguen el estilo del log: ingles, `fix:`, `feat:`,
  `chore:`, `docs:`.
- Los cambios van por PR a `main`. La accion `.github/workflows/update_packages.yml` publica en Chocolatey y hace
  commits en `main` todos los dias a las 04:47 UTC: no ejecutarla, no empaquetar ni publicar nada, y contar con que
  `main` avanza sola (traer `main` antes de subir una rama).

## Compatibilidad
- Los scripts de `*/tools/` se ejecutan al instalar y tienen que funcionar en **PowerShell v2** (regla de los
  moderadores). PSScriptAnalyzer no puede comprobarlo: pasar ademas la busqueda con `Select-String` del README
  (seccion "Analisis estatico") y, ante la duda, evitar cualquier cosa de v3 o posterior.
- `update_all.ps1` y los `update.ps1` corren en Windows PowerShell 5.1 (`update_all.bat`, `menu.bat` y el workflow).
- Codificacion: los `chocolateyinstall.ps1` son UTF-8 con BOM; los demas `.ps1`, ASCII. Los `.bat` en CRLF.

## Antes de subir
- `Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1`: cero avisos. Una regla solo se
  apaga con un comentario que diga por que no aplica.
- Las funciones `au_GetLatest` y `au_SearchReplace` las llama Chocolatey-AU con su firma; no cambiarlas de forma.
  `au_GetLatest` debe devolver solo lo que AU espera (nada de `Write-Output` extra).

## Secretos
- La API key de Chocolatey vive en el secreto `CHOCO_API_KEY` de GitHub y en `choco apikey` de la PC. Nunca
  imprimirla ni escribirla en el repositorio.
