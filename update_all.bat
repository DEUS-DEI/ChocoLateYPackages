@echo off
echo ========================================================
echo Iniciando proceso de actualizacion automatica (AU)
echo ========================================================
echo.

REM Ejecutar el archivo update_all.ps1 saltandose las restricciones de ejecucion de Windows
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_all.ps1"

echo.
echo ========================================================
echo Todos los paquetes han sido revisados.
echo ========================================================
pause
