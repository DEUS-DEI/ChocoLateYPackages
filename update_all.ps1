<#
.SYNOPSIS
    Checks, updates, packs and publishes the active Chocolatey packages of this repository.

.DESCRIPTION
    Every folder that contains an update.ps1 (Chocolatey-AU) is an active package. For each one the
    script runs update.ps1, pushes the resulting .nupkg to the Chocolatey community repository and,
    at the end, commits and pushes to Git only the packages that were published successfully (a
    failed push is retried on the next run instead of being recorded as done).

.PARAMETER Package
    Only process these packages (folder names, comma separated). Default: all active packages.

.PARAMETER Force
    Pack and push the packages even when there is no new upstream version.

.PARAMETER NoPush
    Update and pack only: nothing is pushed to Chocolatey or Git and the .nupkg files are kept.

.PARAMETER NoGit
    Push to Chocolatey but do not commit/push the changes to Git.

.EXAMPLE
    .\update_all.ps1

.EXAMPLE
    .\update_all.ps1 -Package nicepage -Force
#>
[CmdletBinding()]
param(
    [string[]] $Package,
    [switch] $Force,
    [switch] $NoPush,
    [switch] $NoGit
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Windows PowerShell downloads are much slower with the progress bar
$pushSource = 'https://push.chocolatey.org/'

Write-Host '========================================================'
Write-Host 'AU Maestro: Actualizacion, Push y Git Sync'
Write-Host '========================================================'
if ($Force) { Write-Host '>>> MODO FORZADO: se empaquetan y suben los paquetes aunque no haya version nueva.' -ForegroundColor Yellow }

function Invoke-Tool {
    # choco/git write progress and warnings to stderr; with 'Stop' Windows PowerShell can turn that
    # into a terminating error when the output is redirected (CI). The exit code is checked instead.
    $ErrorActionPreference = 'Continue'
    $command, $arguments = $args
    & $command @arguments
}

# Chocolatey-AU is the maintained successor of the archived AU module (same commands)
if (Get-Module -ListAvailable -Name Chocolatey-AU) {
    Import-Module Chocolatey-AU
} elseif (Get-Module -ListAvailable -Name AU) {
    Import-Module AU
    Write-Warning 'Usando el modulo AU (archivado). Recomendado: choco install chocolatey-au'
} else {
    throw 'Chocolatey-AU no esta instalado. Ejecuta: choco install chocolatey-au'
}

# Active packages = folders with an update.ps1 (deprecated packages live in .\deprecated)
$packageDirs = @(Get-ChildItem -Path $PSScriptRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'update.ps1') })
if ($Package) {
    # powershell -File passes "a,b" as a single string
    $Package = @($Package -split ',' | ForEach-Object Trim | Where-Object { $_ })
    $unknown = @($Package | Where-Object { $_ -notin $packageDirs.Name })
    if ($unknown) { throw "Paquete(s) desconocido(s): $($unknown -join ', '). Disponibles: $($packageDirs.Name -join ', ')" }
    $packageDirs = @($packageDirs | Where-Object Name -In $Package)
}

$report = [System.Collections.Generic.List[object]]::new()

foreach ($dir in $packageDirs) {
    $name = $dir.Name
    Write-Host "`n>>> Procesando: $name" -ForegroundColor Cyan

    $row = [pscustomobject]@{ Paquete = $name; Anterior = '?'; Nueva = '?'; Estado = 'Error' }
    Push-Location $dir.FullName
    try {
        Remove-Item -Path *.nupkg -ErrorAction SilentlyContinue
        # AU hooks are global functions: a package must not inherit the hooks of the previous one
        Remove-Item -Path Function:\au_BeforeUpdate, Function:\au_AfterUpdate -ErrorAction SilentlyContinue

        $row.Anterior = ([xml](Get-Content -Path "$name.nuspec" -Raw)).package.metadata.version
        $row.Nueva = $row.Anterior

        # update.ps1 returns the AUPackage object (or 'ignore') as its last output
        $result = & .\update.ps1 | Select-Object -Last 1
        $updated = ($result -isnot [string]) -and $result.Updated
        if ($updated) {
            $row.Nueva = $result.RemoteVersion
            Write-Host ">>> Actualizacion detectada: $name v$($row.Anterior) -> v$($row.Nueva)" -ForegroundColor Green
        }

        if (-not ($updated -or $Force)) {
            $row.Estado = 'Al dia'
        } else {
            # AU already packed the package when it updated it; otherwise (forced) pack it now
            $nupkg = Get-ChildItem -Path *.nupkg | Select-Object -First 1
            if (-not $nupkg) {
                Invoke-Tool choco pack --limit-output
                if ($LASTEXITCODE -ne 0) { throw "choco pack fallo (codigo $LASTEXITCODE)" }
                $nupkg = Get-ChildItem -Path *.nupkg | Select-Object -First 1
            }

            if ($NoPush) {
                $row.Estado = 'Empaquetado'
            } else {
                $pushArgs = @('push', $nupkg.FullName, '--source', $pushSource, '--limit-output')
                if ($env:CHOCO_API_KEY) { $pushArgs += @('--api-key', $env:CHOCO_API_KEY) }
                Invoke-Tool choco @pushArgs
                $row.Estado = if ($LASTEXITCODE -ne 0) { 'Push fallido' } elseif ($updated) { 'Actualizado' } else { 'Forzado' }
                if ($row.Estado -eq 'Push fallido') {
                    Write-Host "[ERROR] Push fallido: los cambios de $name quedan sin commit. Reintenta con: update_all.bat -Force -Package $name" -ForegroundColor Red
                }
            }
        }
    } catch {
        Write-Host "[ERROR] $name : $_" -ForegroundColor Red
    } finally {
        if (-not $NoPush) { Remove-Item -Path *.nupkg -ErrorAction SilentlyContinue }
        Pop-Location
        # Installers downloaded by AU to calculate checksums (can be hundreds of MB)
        Remove-Item -Path (Join-Path $env:TEMP "chocolatey\$name") -Recurse -Force -ErrorAction SilentlyContinue
    }
    $report.Add($row)
}

Write-Host "`n========================================================"
Write-Host '                RESUMEN DE ACTUALIZACIONES'
Write-Host '========================================================'
$report | Format-Table -AutoSize | Out-String -Width 200 | Write-Host

# --- GIT SYNC: only packages that reached Chocolatey (a failed push is retried on the next run) ---
$published = @($report | Where-Object Estado -EQ 'Actualizado')
if ($NoPush -or $NoGit) {
    Write-Host '>>> Git Sync omitido (-NoPush / -NoGit).' -ForegroundColor Gray
} elseif (-not $published) {
    Write-Host '>>> No hay cambios que sincronizar en Git.' -ForegroundColor Gray
} else {
    Write-Host '>>> Sincronizando cambios con Git...' -ForegroundColor Cyan
    $message = 'chore: automated update of ' + (($published | ForEach-Object { "$($_.Paquete) v$($_.Nueva)" }) -join ', ')
    Invoke-Tool git -C $PSScriptRoot add @($published.Paquete)
    if ($LASTEXITCODE -eq 0) { Invoke-Tool git -C $PSScriptRoot commit -m $message }
    if ($LASTEXITCODE -eq 0) { Invoke-Tool git -C $PSScriptRoot push }
    if ($LASTEXITCODE -eq 0) {
        Write-Host '>>> Git Sync completado.' -ForegroundColor Green
    } else {
        Write-Host '[ERROR] Git Sync fallo.' -ForegroundColor Red
        $report.Add([pscustomobject]@{ Paquete = 'git'; Anterior = ''; Nueva = ''; Estado = 'Error' })
    }
}

$failed = @($report | Where-Object Estado -In 'Error', 'Push fallido')
exit $(if ($failed) { 1 } else { 0 })
