@echo off
setlocal enabledelayedexpansion

echo ========================================================
echo   Gestor de Paquetes Deprecados / Descontinuados
echo ========================================================
echo.

REM ============================================================
REM  CATEGORIA 1: BRIDGES DE TRANSICION (ID Renombrado)
REM  Estos paquetes fueron renombrados para cumplir las normas
REM  de nomenclatura de Chocolatey. Se publica v999.0.0 para
REM  que los usuarios existentes actualicen al nuevo ID.
REM
REM  fenix-web-server-beta  --> fenix-web-server-pre
REM  github-desktop-beta    --> github-desktop-pre
REM  warp-beta              --> cloudflare-warp-pre
REM  thunderbird-beta       --> thunderbird-mozilla
REM  thunderbird-daily      --> thunderbird-nightly
REM ============================================================
set bridges=fenix-web-server-beta github-desktop-beta warp-beta thunderbird-beta thunderbird-daily

REM ============================================================
REM  CATEGORIA 2: DESCONTINUADOS (Software ya no mantenido)
REM  Estos paquetes fueron abandonados por sus desarrolladores
REM  originales y no tienen sucesor. El nuspec ya tiene el
REM  mensaje de discontinuacion. Solo se re-empaquetan y suben
REM  si la version actual NO coincide con la de chocolatey.org.
REM
REM  flarectl  --> Cloudflare dejó de distribuir binarios Win
REM ============================================================
set discontinued=flarectl

echo [PASO 1] Procesando bridges de transicion (renombrados)...
echo --------------------------------------------------------
for %%p in (%bridges%) do (
    echo.
    echo --- Bridge: %%p ---
    cd deprecated\%%p
    choco pack
    if !errorlevel! equ 0 (
        echo Empaquetado con exito. Intentando subir...
        for %%n in (*.nupkg) do (
            choco push %%n --source="https://push.chocolatey.org/"
            if !errorlevel! equ 0 (
                echo [OK] %%p subido correctamente.
            ) else (
                echo [WARN] %%p fallo el push - puede requerir intervencion manual del moderador.
                echo        Contactar: https://community.chocolatey.org/packages/%%p/contact
            )
            del /f /q %%n 2>nul
        )
    ) else (
        echo [ERROR] Fallo al empaquetar %%p
    )
    cd ..\..
)

echo.
echo [PASO 2] Procesando paquetes DESCONTINUADOS...
echo --------------------------------------------------------
for %%p in (%discontinued%) do (
    echo.
    echo --- Descontinuado: %%p ---
    cd deprecated\%%p
    choco pack
    if !errorlevel! equ 0 (
        echo Empaquetado con exito. Intentando subir version final...
        for %%n in (*.nupkg) do (
            choco push %%n --source="https://push.chocolatey.org/"
            if !errorlevel! equ 0 (
                echo [OK] %%p - version final publicada correctamente.
            ) else (
                echo [INFO] %%p ya tiene la version correcta en linea o requiere moderador.
            )
            del /f /q %%n 2>nul
        )
    ) else (
        echo [ERROR] Fallo al empaquetar %%p
    )
    cd ..\..
)

echo.
echo ========================================================
echo   Proceso finalizado.
echo ========================================================
echo.
echo NOTAS IMPORTANTES:
echo  - Si un BRIDGE fallo con 403: el paquete viejo ya tiene
echo    una version en linea. Debes pedir al moderador que
echo    haga "Unlist" de la version antigua en chocolatey.org.
echo    URL del formulario: https://community.chocolatey.org/packages/{id}/contact
echo.
echo  - Los paquetes ACTIVOS (no deprecated) se gestionan
echo    exclusivamente mediante update_all.bat
echo.
echo  - Estado de moderacion: https://ch0.co/moderation
echo ========================================================
pause
