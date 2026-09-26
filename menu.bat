@echo off
setlocal
title AU Maestro - Panel de Control
rem Trabajar siempre desde la carpeta del repositorio, se lance desde donde se lance
cd /d "%~dp0"

:main_menu
set "timer=15"

:countdown
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
if %timer% LEQ 0 goto end
echo Saliendo por defecto (opcion 5) en %timer% segundos...

rem "0" es una opcion invisible que se elige sola al pasar 1 segundo: permite mostrar la cuenta atras
choice /c 123450 /t 1 /d 0 /n >nul
set "res=%errorlevel%"
if "%res%"=="6" (
    set /a timer-=1
    goto countdown
)
if "%res%"=="1" goto normal_update
if "%res%"=="2" goto force_all
if "%res%"=="3" goto choose_package
if "%res%"=="4" goto set_secrets
goto end

:normal_update
echo.
echo ^>^>^> Iniciando actualizacion automatica normal...
call "%~dp0update_all.bat"
timeout /t 15
goto main_menu

:force_all
echo.
echo ^>^>^> Iniciando FORZADO de todos los paquetes...
call "%~dp0update_all.bat" -Force
timeout /t 15
goto main_menu

:choose_package
cls
echo ========================================================
echo           SELECCIONAR PAQUETE PARA FORZAR
echo ========================================================
echo.
rem Paquetes activos = carpetas con update.ps1 (la lista se genera sola)
set "count=0"
for /d %%D in (*) do if exist "%%D\update.ps1" (
    set /a count+=1
    call set "pkg_%%count%%=%%D"
    call echo [%%count%%] %%D
)
echo [B] Volver al menu principal
echo.
set "pkg_opt="
set /p "pkg_opt=Seleccione el numero del paquete: "
if not defined pkg_opt goto choose_package
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
call "%~dp0update_all.bat" -Force -Package %pkg%
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
exit /b
