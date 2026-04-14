<# :
@echo off
if "%~1"=="" (
    echo [ERROR] Debes especificar el nombre del paquete.
    echo Uso: force_push.bat nombre-del-paquete
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { [ScriptBlock]::Create([IO.File]::ReadAllText('%~f0')).Invoke($args) }" %*
exit /b
#>

$packageName = $args[0]
$rootDir = $PWD.Path
$packagePath = Join-Path $rootDir $packageName

if (-not (Test-Path $packagePath)) {
    Write-Host "[ERROR] No se encontro la carpeta del paquete: $packageName" -ForegroundColor Red
    return
}

Write-Host "`n>>> Forzando PACK y PUSH para: $packageName" -ForegroundColor Cyan
Push-Location $packagePath

try {
    # Limpiar nupkgs viejos en esta carpeta
    Get-ChildItem -Filter "*.nupkg" | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host ">>> Empaquetando..." -ForegroundColor Gray
    choco pack
    
    $nupkg = Get-ChildItem -Filter "*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($nupkg) {
        Write-Host ">>> Subiendo $($nupkg.Name)..." -ForegroundColor Green
        choco push $nupkg.FullName --source "https://push.chocolatey.org/"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ">>> Exito: $packageName subido correctamente." -ForegroundColor Green
        } else {
            Write-Host ">>> Error al subir el paquete." -ForegroundColor Red
        }
    } else {
        Write-Host ">>> Error: No se pudo generar el archivo .nupkg" -ForegroundColor Red
    }
} finally {
    Pop-Location
}
