<# :
@echo off
setlocal
echo ========================================================
echo Configurador de Secretos de GitHub (CHOCO_API_KEY)
echo ========================================================
echo.

:: Verificar si gh existe
where gh >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] GitHub CLI gh no esta instalado.
    echo Descargalo en: https://cli.github.com/
    pause
    exit /b
)

:: Llamar a la parte de PowerShell del mismo archivo
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([ScriptBlock]::Create([IO.File]::ReadAllText('%~f0')))"

echo.
echo ========================================================
echo Proceso finalizado.
echo ========================================================
exit /b
#>

$ApiKey = Read-Host ">>> Pega tu Chocolatey API Key"

if (-not $ApiKey) {
    Write-Host "[ERROR] No se ingreso ninguna llave. Cancelando." -ForegroundColor Red
    return
}

Write-Host "`n>>> Verificando autenticacion en GitHub..." -ForegroundColor Gray
$user = gh api user --jq .login 2>$null

if (-not $user) {
    Write-Host "[ERROR] No has iniciado sesion en GitHub CLI." -ForegroundColor Red
    Write-Host "Por favor ejecuta primero: gh auth login" -ForegroundColor Cyan
    return
}

Write-Host ">>> Usuario detectado: $user" -ForegroundColor Green
Write-Host ">>> Subiendo secreto CHOCO_API_KEY..." -ForegroundColor Cyan

# Subir secreto usando GH CLI
echo $ApiKey | gh secret set CHOCO_API_KEY

if ($LASTEXITCODE -eq 0) {
    Write-Host "¡EXITO! Secreto guardado en el repositorio." -ForegroundColor Green
} else {
    Write-Host "[ERROR] Hubo un problema al subir el secreto." -ForegroundColor Red
}
