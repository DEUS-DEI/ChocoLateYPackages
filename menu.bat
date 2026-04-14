@echo off
setlocal enabledelayedexpansion
title AU Maestro - Panel de Control
chcp 65001 >nul

:main_menu
cls
echo ========================================================
echo           PANEL DE CONTROL - AU MAESTRO
echo ========================================================
echo.
echo [1] FORZAR TODO (Pack + Push de todos los paquetes)
echo [2] Actualizar Todo (Modo normal / Automático)
echo [3] Forzar un paquete específico (Elegir de lista)
echo [4] Salir sin hacer nada
echo.
echo ========================================================
echo.

:: Temporizador de 15 segundos, defecto la opción 1 (según pedido del usuario)
echo La opción [1] se ejecutará automáticamente en 15 segundos...
choice /c 1234 /t 15 /d 1 /m "Seleccione una opción:"

set opt=%errorlevel%

if %opt%==1 goto force_all
if %opt%==2 goto normal_update
if %opt%==3 goto choose_package
if %opt%==4 goto end

:force_all
echo.
echo >>> Iniciando FORZADO de todos los paquetes...
call update_all.bat -Force
pause
goto main_menu

:normal_update
echo.
echo >>> Iniciando actualización automática normal...
call update_all.bat
pause
goto main_menu

:choose_package
cls
echo ========================================================
echo           SELECCIONAR PAQUETE PARA FORZAR
echo ========================================================
echo.
:: Listado manual basado en update_all.bat para evitar lentitud de parsing
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
    call force_push.bat %pkg%
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
