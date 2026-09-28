@echo off
rem Sin expansion retardada: con ella una "!" en la ruta del repositorio rompe el cambio de carpeta
setlocal
rem Trabajar siempre desde la carpeta del repositorio, se lance desde donde se lance. pushd (y no cd /d)
rem tambien funciona desde una ruta UNC. Si falla, se para: nunca empaquetar en la carpeta de quien lo llama.
pushd "%~dp0" || (echo [ERROR] No se pudo entrar en "%~dp0". & pause & exit /b 1)

rem Uso: push_deprecated.bat [--no-pause]   Codigo de salida: 0 si todo se publico, 1 si algo fallo.
set "failed=0"

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
set "bridges=fenix-web-server-beta fenix-web-server-pre github-desktop-beta thunderbird-beta thunderbird-daily"

echo Procesando bridges de transicion...
echo --------------------------------------------------------
for %%p in (%bridges%) do call :bridge %%p

echo.
echo ========================================================
if "%failed%"=="0" (echo   Proceso finalizado.) else (echo   Proceso finalizado CON ERRORES.)
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
if /i not "%~1"=="--no-pause" pause
popd
exit /b %failed%

rem Empaqueta y publica un bridge. Nunca trabaja fuera de deprecated\<id>.
:bridge
echo.
echo --- Bridge: %~1 ---
if not exist "deprecated\%~1\%~1.nuspec" (echo [ERROR] Falta deprecated\%~1\%~1.nuspec & set "failed=1" & exit /b 1)
pushd "deprecated\%~1" || (echo [ERROR] No se pudo entrar en deprecated\%~1 & set "failed=1" & exit /b 1)
del /f /q *.nupkg 2>nul
choco pack --limit-output
rem "if errorlevel 1" solo ve codigos >= 1: un choco que revienta sale con uno negativo (0xE0434352)
if errorlevel 1 (set "rc=1") else if errorlevel 0 (set "rc=0") else set "rc=1"
if "%rc%"=="1" (
    echo [ERROR] Fallo al empaquetar %~1
    set "failed=1"
    del /f /q *.nupkg 2>nul
    popd
    exit /b 1
)
echo Empaquetado con exito. Intentando subir...
for %%n in (*.nupkg) do call :push "%%n" "%~1"
popd
exit /b 0

rem Publica un .nupkg (%1) del bridge %2 y lo borra
:push
rem Si CHOCO_API_KEY esta definida se usa; si no, la clave guardada con "choco apikey add"
if defined CHOCO_API_KEY (
    choco push "%~1" --source="https://push.chocolatey.org/" --api-key="%CHOCO_API_KEY%"
) else (
    choco push "%~1" --source="https://push.chocolatey.org/"
)
if errorlevel 1 (set "rc=1") else if errorlevel 0 (set "rc=0") else set "rc=1"
if "%rc%"=="1" (
    echo [WARN] %~2 fallo el push - puede que la version ya exista o requiera un moderador.
    echo        Contactar: https://community.chocolatey.org/packages/%~2/ContactAdmins
    set "failed=1"
) else (
    echo [OK] %~2 subido correctamente.
)
del /f /q "%~1" 2>nul
exit /b 0
