@echo off
setlocal
title AU Maestro - Panel de Control
rem Trabajar siempre desde la carpeta del repositorio, se lance desde donde se lance (pushd, y no cd /d,
rem tambien funciona desde una ruta UNC). Las opciones llaman a .\update_all.bat relativo a esta carpeta.
pushd "%~dp0" || (echo [ERROR] No se pudo entrar en "%~dp0". & pause & exit /b 1)

:main_menu
set "timer=15"
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
echo Saliendo por defecto (opcion 5) en %timer% segundos...

rem Una sola espera: cada choice.exe nuevo descarta las teclas pulsadas antes de arrancar, asi que una
rem cuenta atras que lo relanzaba cada segundo perdia pulsaciones
choice /c 12345 /t %timer% /d 5 /n >nul
set "res=%errorlevel%"
if "%res%"=="1" goto normal_update
if "%res%"=="2" goto force_all
if "%res%"=="3" goto choose_package
if "%res%"=="4" goto set_secrets
goto end

:normal_update
echo.
echo ^>^>^> Iniciando actualizacion automatica normal...
call .\update_all.bat
timeout /t 15
goto main_menu

:force_all
echo.
echo ^>^>^> Iniciando FORZADO de todos los paquetes...
call .\update_all.bat -Force
timeout /t 15
goto main_menu

:choose_package
cls
echo ========================================================
echo           SELECCIONAR PAQUETE PARA FORZAR
echo ========================================================
echo.
rem Paquetes activos = carpetas de Paquetes\actuales con update.ps1 (la lista se genera sola)
set "count=0"
for /d %%D in (Paquetes\actuales\*) do if exist "%%D\update.ps1" (
    set /a count+=1
    call set "pkg_%%count%%=%%~nxD"
    call echo [%%count%%] %%~nxD
)
echo [B] o Enter: Volver al menu principal
echo.
set "pkg_opt="
set /p "pkg_opt=Seleccione el numero del paquete: "
rem Entrada vacia, o fin de la entrada si llega por una tuberia: volver al menu (repetir la pregunta
rem seria un bucle sin fin al 100% de CPU)
if not defined pkg_opt goto main_menu
rem La entrada solo se usa con expansion retardada, que nunca la interpreta como comando:
rem se quitan los digitos (si queda algo, no es un numero) y se busca el paquete sin re-expandirla.
setlocal EnableDelayedExpansion
set "rest=!pkg_opt!"
for %%d in (0 1 2 3 4 5 6 7 8 9) do if defined rest set "rest=!rest:%%d=!"
set "sel="
if /i "!pkg_opt!"=="B" (
    set "sel=back"
) else if not defined rest (
    for %%n in ("!pkg_opt!") do set "sel=!pkg_%%~n!"
)
for %%s in ("!sel!") do endlocal & set "sel=%%~s"
if "%sel%"=="back" goto main_menu
if not defined sel goto invalid_package
set "pkg=%sel%"

echo.
echo ^>^>^> Forzando actualizacion + push para: %pkg%
call .\update_all.bat -Force -Package %pkg%
timeout /t 15
goto choose_package

:invalid_package
echo [ERROR] Seleccion invalida.
timeout /t 2 >nul
goto choose_package

:set_secrets
cls
echo ========================================================
echo   CONFIGURADOR DE SECRETOS GITHUB (CHOCO_API_KEY)
echo ========================================================
echo.
where gh >nul 2>nul
if errorlevel 1 goto gh_missing

rem La clave se lee oculta y se pasa a gh por la entrada estandar (no queda en pantalla ni en el historial)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = Read-Host '>>> Pega tu Chocolatey API Key' -AsSecureString; $k = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)); if (-not $k) { Write-Host '[ERROR] No se ingreso ninguna clave.'; exit 1 }; gh auth status *> $null; if ($LASTEXITCODE -ne 0) { Write-Host '[ERROR] gh no tiene sesion iniciada. Ejecuta: gh auth login'; exit 1 }; $k | gh secret set CHOCO_API_KEY; if ($LASTEXITCODE -eq 0) { Write-Host '[OK] Secreto CHOCO_API_KEY configurado.' } else { Write-Host '[ERROR] No se pudo configurar el secreto.' }"
timeout /t 5
goto main_menu

:gh_missing
echo [ERROR] GitHub CLI (gh) no esta instalado: https://cli.github.com/
timeout /t 5
goto main_menu

:end
echo.
echo Saliendo...
timeout /t 2 >nul
popd
exit /b
