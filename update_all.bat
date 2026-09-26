@echo off
rem Lanzador de update_all.ps1. Acepta los mismos parametros:
rem   update_all.bat [-Force] [-Package nicepage,github-desktop-pre] [-NoPush] [-NoGit]
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update_all.ps1" %*
exit /b %errorlevel%
