@echo off
rem Lanzador de vendor_catalog.ps1 (solo consulta: no empaqueta ni publica nada). Acepta los mismos parametros:
rem   vendor_catalog.bat [-Vendor Mozilla,GitHub] [-NoDiscover] [-OutFile catalogo.md]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0vendor_catalog.ps1" %*
exit /b %errorlevel%
