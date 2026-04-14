@echo off
setlocal enabledelayedexpansion

echo Preparando paquetes de transicion...

REM set packages=fenix-web-server-beta github-desktop-beta warp-beta thunderbird-beta thunderbird-daily
set packages=warp-beta thunderbird-beta thunderbird-daily

for %%p in (%packages%) do (
    echo.
    echo --- Procesando %%p ---
    cd deprecated\%%p
    choco pack
    if !errorlevel! equ 0 (
        echo Empaquetado con exito. Intentando subir...
        for %%n in (*.nupkg) do (
            choco push %%n --source="https://push.chocolatey.org/"
        )
    ) else (
        echo ERROR al empaquetar %%p
    )
    cd ..\..
)

echo.
echo Proceso finalizado. 
echo NOTA: Si algun paquete falla por la regla del ID (CPMR0024), 
echo deberas contactar a un moderador en chocolatey.org para solicitar 
echo el "Unlist" manual de los paquetes antiguos.
pause
