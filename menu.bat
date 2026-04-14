@echo off
setlocal enabledelayedexpansion
title AU Maestro - Panel de Control
chcp 65001 >nul

set "timer=15"

:main_menu
cls
echo ========================================================
echo           PANEL DE CONTROL - AU MAESTRO
echo ========================================================
echo.
echo [1] Actualización Normal (Automático)
echo [2] Forzar TODO (Pack + Push de todos los paquetes)
echo [3] Forzar un paquete específico (Elegir de lista)
echo [4] Configurar Secretos GitHub (CHOCO_API_KEY)
echo [5] Salir (Cerrar)
echo.
echo ========================================================
echo.

:timer_loop
if %timer% LEQ 0 goto end
echo Saliendo por defecto (opción 5) en !timer! segundos...
choice /c 12345 /t 1 /d 5 /n
set opt=%errorlevel%

:: Si el usuario presionó algo del 1 al 4, vamos a la acción.
:: Si devolvió 5, puede ser por timeout o por presionar 5.
if %opt% LSS 5 goto handle_choice
if %opt%==5 (
    :: Si el usuario presiona 5, salimos. Pero Choice /t 1 /d 5 siempre devuelve 5.
    :: Usamos un truco: Si no se presionó una tecla, seguimos el loop.
    :: Lamentablemente Batch puro es limitado aquí. Usaremos un pequeño script PS para el menú con timer.
    set /a timer-=1
    cls
    echo ========================================================
    echo           PANEL DE CONTROL - AU MAESTRO
    echo ========================================================
    echo.
    echo [1] Actualización Normal (Automático)
    echo [2] Forzar TODO (Pack + Push de todos los paquetes)
    echo [3] Forzar un paquete específico (Elegir de lista)
    echo [4] Configurar Secretos GitHub (CHOCO_API_KEY)
    echo [5] Salir (Cerrar)
    echo.
    echo ========================================================
    echo.
    goto timer_loop
)

:handle_choice
set timer=15
if %opt%==1 goto normal_update
if %opt%==2 goto force_all
if %opt%==3 goto choose_package
if %opt%==4 goto set_secrets
if %opt%==5 goto end

:normal_update
echo.
echo >>> Iniciando actualización automática normal...
call update_all.bat
pause
goto main_menu

:force_all
echo.
echo >>> Iniciando FORZADO de todos los paquetes...
call update_all.bat -Force
pause
goto main_menu

:set_secrets
echo.
echo >>> Abriendo configurador de secretos de GitHub...
call set_github_secrets.bat
pause
goto main_menu

:choose_package
cls
echo ========================================================
echo           SELECCIONAR PAQUETE PARA FORZAR
echo ========================================================
echo.
echo [1] fenix-web-server
echo [2] fenix-web-server-beta
echo [3] thunderbird-beta
echo [4] thunderbird-daily
echo [5] github-desktop-beta
echo [6] nicepage
echo [7] warp-beta
echo [B] Volver al menú principal
echo.

set /p pkg_opt="Seleccione el número del paquete: "

if "%pkg_opt%"=="1" set pkg=fenix-web-server
if "%pkg_opt%"=="2" set pkg=fenix-web-server-beta
if "%pkg_opt%"=="3" set pkg=thunderbird-beta
if "%pkg_opt%"=="4" set pkg=thunderbird-daily
if "%pkg_opt%"=="5" set pkg=github-desktop-beta
if "%pkg_opt%"=="6" set pkg=nicepage
if "%pkg_opt%"=="7" set pkg=warp-beta
if /i "%pkg_opt%"=="B" goto main_menu

if defined pkg (
    echo.
    echo >>> Forzando PUSH para: %pkg%
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Push-Location '%pkg%'; try { Get-ChildItem -Filter *.nupkg | Remove-Item -Force -ErrorAction SilentlyContinue; choco pack; $n = Get-ChildItem -Filter *.nupkg | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if ($n) { choco push $n.FullName --source https://push.chocolatey.org/ } } finally { Pop-Location } }"
    set pkg=
    pause
    goto choose_package
) else (
    echo [ERROR] Selección inválida.
    timeout /t 2 >nul
    goto choose_package
)

:end
echo.
echo Saliendo...
timeout /t 2 >nul
exit /b
