<# :
@echo off
echo ========================================================
echo Iniciando proceso de actualizacion automatica (AU)
echo ========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([ScriptBlock]::Create([IO.File]::ReadAllText('%~f0')))"
echo.
echo ========================================================
echo Todos los paquetes han sido revisados.
echo ========================================================
pause
exit /b
#>

Import-Module au

# Configuración básica para buscar en todas las carpetas y ejecutar sus scripts de actualización.
Get-ChildItem -Directory | ForEach-Object {
    $updateScript = Join-Path $_.FullName "update.ps1"
    if (Test-Path $updateScript) {
        Write-Host "====================================="
        Write-Host "Corriendo actualización para: $($_.Name)"
        Write-Host "====================================="
        Push-Location $_.FullName
        try {
            & .\update.ps1
        } catch {
            Write-Error "Error al actualizar $($_.Name): $_"
        }
        Pop-Location
    }
}
