@echo off
setlocal enabledelayedexpansion
title AU Maestro - Panel de Control

set "timer=15"

:main_menu
cls
echo ========================================================
echo           PANEL DE CONTROL - AU MAESTRO
echo ========================================================
echo.
echo [1] Actualizacion Normal (Automatico)
echo [2] Forzar TODO (Pack + Push de todos los paquetes)
echo [3] Forzar un paquete especifico (Elegir de lista)
echo [4] Configurar Secretos GitHub (CHOCO_API_KEY)
echo [5] Salir (Cerrar)
echo.
echo ========================================================
echo.

:timer_loop
if !timer! LEQ 0 goto end
echo Saliendo por defecto (opcion 5) en !timer! segundos...

:: Truco: usamos el 6 como opcion invisible para el timeout
choice /c 123456 /t 1 /d 6 /n
set res=%errorlevel%

if %res%==6 (
    set /a timer-=1
    goto main_menu_no_cls
)

if %res%==5 goto end

set opt=%res%
goto handle_choice

:main_menu_no_cls
cls
echo ========================================================
echo           PANEL DE CONTROL - AU MAESTRO
echo ========================================================
echo.
echo [1] Actualizacion Normal (Automatico)
echo [2] Forzar TODO (Pack + Push de todos los paquetes)
echo [3] Forzar un paquete especifico (Elegir de lista)
echo [4] Configurar Secretos GitHub (CHOCO_API_KEY)
echo [5] Salir (Cerrar)
echo.
echo ========================================================
echo.
goto timer_loop

:handle_choice
if %opt%==1 goto normal_update
if %opt%==2 goto force_all
if %opt%==3 goto choose_package
if %opt%==4 goto set_secrets
goto end

:normal_update
echo.
echo ^>^>^> Iniciando actualizacion automatica normal...
call update_all.bat
timeout /t 5
set timer=15
goto main_menu

:force_all
echo.
echo ^>^>^> Iniciando FORZADO de todos los paquetes...
call update_all.bat -Force
timeout /t 5
set timer=15
goto main_menu

:set_secrets
cls
echo ========================================================
echo   CONFIGURADOR DE SECRETOS GITHUB (CHOCO_API_KEY)
echo ========================================================
echo.
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] GitHub CLI (gh) no esta instalado.
    timeout /t 5
    set timer=15
    goto main_menu
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ApiKey = Read-Host '>>> Pega tu Chocolatey API Key'; if (-not $ApiKey) { Write-Host '[ERROR]'; return }; $u = gh api user --jq .login 2>$null; if (-not $u) { Write-Host '[ERROR]'; return }; $ApiKey | gh secret set CHOCO_API_KEY; if ($LASTEXITCODE -eq 0) { Write-Host '¡EXITO!' } else { Write-Host '¡ERROR!' }"
timeout /t 5
set timer=15
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
echo [B] Volver al menu principal
echo.

set /p pkg_opt="Seleccione el numero del paquete: "

if "%pkg_opt%"=="1" set pkg=fenix-web-server
if "%pkg_opt%"=="2" set pkg=fenix-web-server-beta
if "%pkg_opt%"=="3" set pkg=thunderbird-beta
if "%pkg_opt%"=="4" set pkg=thunderbird-daily
if "%pkg_opt%"=="5" set pkg=github-desktop-beta
if "%pkg_opt%"=="6" set pkg=nicepage
if "%pkg_opt%"=="7" set pkg=warp-beta
if /i "%pkg_opt%"=="B" set timer=15 & goto main_menu

if defined pkg (
    echo.
    echo ^>^>^> Forzando PUSH para: !pkg!
    powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Push-Location '!pkg!'; try { Get-ChildItem -Filter *.nupkg | Remove-Item -Force -ErrorAction SilentlyContinue; choco pack; $n = Get-ChildItem -Filter *.nupkg | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if ($n) { choco push $n.FullName --source https://push.chocolatey.org/ } } finally { Pop-Location } }"
    set pkg=
    timeout /t 5
    goto choose_package
) else (
    echo [ERROR] Seleccion invalida.
    timeout /t 2 >nul
    goto choose_package
)

:end
echo.
echo Saliendo...
timeout /t 2 >nul
exit /b
