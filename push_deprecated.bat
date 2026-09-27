@echo off
setlocal enabledelayedexpansion
rem Trabajar siempre desde la carpeta del repositorio, se lance desde donde se lance
cd /d "%~dp0"

rem Si CHOCO_API_KEY esta definida se usa; si no, la clave guardada con "choco apikey add"
set "apikey="
if defined CHOCO_API_KEY set "apikey=--api-key=%CHOCO_API_KEY%"

echo ========================================================
echo   Gestor de Paquetes Deprecados (bridges)
echo ========================================================
echo.

REM ============================================================
REM  BRIDGES DE TRANSICION (ID retirado)
REM  Se publica v999.0.0 (solo el nuspec, <files />) con una
REM  dependencia del paquete nuevo, para que los usuarios
REM  existentes actualicen automaticamente al nuevo ID.
REM
REM  fenix-web-server-beta  --> fenix-web-server (pre-releases)
REM  fenix-web-server-pre   --> fenix-web-server (pre-releases)
REM  github-desktop-beta    --> github-desktop-pre
REM  thunderbird-beta       --> thunderbird-mozilla
REM  thunderbird-daily      --> thunderbird-nightly
REM ============================================================
set bridges=fenix-web-server-beta fenix-web-server-pre github-desktop-beta thunderbird-beta thunderbird-daily

echo Procesando bridges de transicion...
echo --------------------------------------------------------
for %%p in (%bridges%) do (
    echo.
    echo --- Bridge: %%p ---
    pushd "deprecated\%%p"
    del /f /q *.nupkg 2>nul
    choco pack --limit-output
    if !errorlevel! equ 0 (
        echo Empaquetado con exito. Intentando subir...
        for %%n in (*.nupkg) do (
            choco push "%%n" --source="https://push.chocolatey.org/" !apikey!
            if !errorlevel! equ 0 (
                echo [OK] %%p subido correctamente.
            ) else (
                echo [WARN] %%p fallo el push - puede que la version ya exista o requiera un moderador.
                echo        Contactar: https://community.chocolatey.org/packages/%%p/ContactAdmins
            )
            del /f /q "%%n" 2>nul
        )
    ) else (
        echo [ERROR] Fallo al empaquetar %%p
    )
    popd
)

echo.
echo ========================================================
echo   Proceso finalizado.
echo ========================================================
echo.
echo NOTAS IMPORTANTES:
echo  - Publica cada bridge DESPUES de que se apruebe la version
echo    del paquete destino de la que depende (si no, la
echo    verificacion automatica no puede instalarlo).
echo  - Si el validador marca CPMR0024 (beta/pre en el ID),
echo    responde en la revision que es la deprecacion de un ID
echo    ya existente, siguiendo la guia oficial:
echo    https://docs.chocolatey.org/en-us/community-repository/maintainers/deprecate-a-chocolatey-package/
echo  - Cuando el bridge este aprobado, oculta (unlist) todas
echo    las versiones anteriores del ID deprecado.
echo  - Los paquetes ACTIVOS se gestionan con update_all.bat
echo  - Estado de moderacion: https://ch0.co/moderation
echo ========================================================
pause
