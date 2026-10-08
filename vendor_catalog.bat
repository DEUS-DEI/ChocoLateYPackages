@echo off
rem Lanzador de vendor_catalog.ps1. Sin -Install solo consulta; con -Install instala desde el fabricante.
rem   vendor_catalog.bat [-Vendor Mozilla,GitHub] [-NoDiscover] [-OutFile catalogo.md]
rem   vendor_catalog.bat -Install firefox,kiro [-WhatIf] [-Yes] [-Language es-MX]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0vendor_catalog.ps1" %*
exit /b %errorlevel%
