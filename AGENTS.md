# ChocoLateYPackages: instrucciones para agentes de IA

Para cualquier agente que trabaje en este repositorio (Codex, Copilot, Cursor, Gemini, Devin, Jules, Windsurf y los
demas que leen `AGENTS.md`). **Las reglas completas estan en [`CLAUDE.md`](CLAUDE.md), en esta misma carpeta: leelo
antes de cambiar nada.** Este archivo es su resumen; si algo no cuadra, manda `CLAUDE.md`. Claude Code lee `CLAUDE.md`
y no este archivo. Si una regla cambia, se cambia en los dos.

## Lo minimo

- **Respuestas al usuario en espanol**; los mensajes de commit, en ingles con el estilo del log (`fix:`, `feat:`,
  `chore:`, `docs:`).
- **El repositorio es publico**: nada privado (rutas de la PC, cuentas, secretos) en archivos, commits ni PR.
- **Los cambios van por PR a `main`.** `.github/workflows/update_packages.yml` publica en Chocolatey y hace commits en
  `main` todos los dias a las 04:47 UTC: no ejecutarlo, no empaquetar ni publicar nada, y traer `main` antes de subir
  una rama.
- **Un PR que abre el agente se fusiona el mismo**, con merge commit (nunca squash), cuando su ultimo commit tiene en
  verde `Tests / test` y `Devin Review`, GitHub lo da por fusionable y no queda ningun comentario de revision por
  contestar. Nunca se fusiona el PR de un tercero sin que el usuario lo diga.
- **Sin pruebas antes de subir**, salvo que el usuario las pida (el CI si las corre). Las pruebas usan un `choco` falso
  y nunca publican nada.
- **Scripts en `Scripts/`, documentacion en `docs/`.** `update_all.bat` y `vendor_catalog.bat` llevan su PowerShell
  dentro, detras de `### POWERSHELL ###` (los lanza `Scripts\lib\Lanzar.ps1` con Windows PowerShell 5.1); un script
  nuevo va igual, no como un `.ps1` suelto. Los `update.ps1` y `tools\*.ps1` de cada paquete se quedan como `.ps1` en
  su carpeta: asi los piden Chocolatey y Chocolatey-AU.
- **Los scripts de `Paquetes/actuales/*/tools/` corren en PowerShell v2** al instalar, y el checksum de cada descarga
  va escrito en el script como literal (regla CPMR0073 del validador).
- **`Scripts\vendor_catalog.bat -Install`** instala programas en la PC del usuario: nunca sin `-WhatIf`, salvo que el
  usuario lo pida para un producto concreto.
- **winget**: no se envia nada todavia; no crear `WINGET_SUBMIT` ni `WINGET_TOKEN`, ni ejecutar `komac submit`.
- **Secretos** (`CHOCO_API_KEY`, `GITHUB_TOKEN`, `WINGET_TOKEN`): nunca se imprimen ni se escriben en el repositorio;
  en la PC los toma `Scripts\lib\Get-Secret.ps1` sin decir de donde salen.
- **Codificacion**: `chocolateyinstall.ps1` en UTF-8 con BOM; los demas `.ps1` y los `.bat`, en ASCII; los `.bat`,
  en CRLF.

## Donde esta cada cosa

| Carpeta | Que hay |
|---|---|
| `Paquetes/actuales/`, `Paquetes/descontinuados/` | los paquetes activos y los bridges de los IDs retirados |
| `deprecated/` | avisos de "se movio" que enlazan las versiones viejas: no se borran |
| `Scripts/` | `update_all.bat`, `vendor_catalog.bat`, `menu.bat`, `push_deprecated.bat`; `lib/` con el cargador, `Get-Secret.ps1` y `vendor_catalog.psd1` |
| `tests/` | pruebas Pester (Windows PowerShell 5.1) y la configuracion de PSScriptAnalyzer |
| `docs/` | la documentacion (la lista esta en `README.md`) |
