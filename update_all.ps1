<#
.SYNOPSIS
    Checks, updates, packs and publishes the active Chocolatey packages of this repository.

.DESCRIPTION
    Every folder of Paquetes\actuales that contains an update.ps1 (Chocolatey-AU) is an active package. For
    each one the script runs update.ps1, pushes the resulting .nupkg to the Chocolatey community repository and,
    at the end, commits and pushes to Git only the packages that were published successfully (a
    failed push is retried on the next run instead of being recorded as done).

    If a version was published but its Git commit was lost (e.g. the CI runner failed to push), AU
    skips it because it already exists in the Chocolatey feed. The script detects that case, updates
    the package files without pushing again and commits them (state 'Registrado').

.PARAMETER Package
    Only process these packages (folder names, comma separated). Default: all active packages.

.PARAMETER Force
    Pack and push the packages even when there is no new upstream version.

.PARAMETER NoPush
    Update and pack only: nothing is pushed to Chocolatey or Git. The .nupkg files are kept for review
    and the package files are restored, so when there is a new version the next normal run still
    publishes it (a package packed only because of -Force is not published by a normal run).

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
if ($Force) {
    $forceAction = if ($NoPush) { 'se empaquetan (sin publicar)' } else { 'se empaquetan y suben' }
    Write-Host ">>> MODO FORZADO: $forceAction los paquetes aunque no haya version nueva." -ForegroundColor Yellow
}

# Chocolatey-AU reads the nuspec with Get-Item -Path, which treats [ and ] as wildcards: in such a folder
# every package would fail (or, before this check, no package was found at all and the run "succeeded")
if ($PSScriptRoot -match '[\[\]]') {
    throw "La ruta del repositorio contiene '[' o ']' ($PSScriptRoot): Chocolatey-AU no la soporta. Clona el repositorio en una ruta sin corchetes."
}

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

# Active packages = folders of Paquetes\actuales with an update.ps1 (retired IDs live in Paquetes\descontinuados)
$packagesFolder = 'Paquetes/actuales'  # relative to the repository, with "/": it is also the path given to Git
$packagesRoot = Join-Path $PSScriptRoot $packagesFolder
$packageDirs = @(Get-ChildItem -Path $packagesRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName 'update.ps1') })
if (-not $packageDirs) { throw "No se encontro ningun paquete (carpetas con update.ps1) en $packagesRoot" }
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
    $updated = $false
    # Snapshot of the package folder: if the new version is not published, AU's changes are rolled back
    # so the next run detects the update again (edits made before this run are part of the snapshot)
    $snapshot = Join-Path ([System.IO.Path]::GetTempPath()) "au-snapshot-$name"
    $hasSnapshot = $false
    Push-Location $dir.FullName
    try {
        Remove-Item -Path *.nupkg -ErrorAction SilentlyContinue  # leftovers of a -NoPush run
        Remove-Item -Path $snapshot -Recurse -Force -ErrorAction SilentlyContinue
        Copy-Item -Path $dir.FullName -Destination $snapshot -Recurse -Force  # -Force: hidden files too
        $hasSnapshot = $true

        # AU hooks are global functions: a package must not inherit the hooks of the previous one
        Remove-Item -Path Function:\au_BeforeUpdate, Function:\au_AfterUpdate -ErrorAction SilentlyContinue

        $row.Anterior = ([xml](Get-Content -Path "$name.nuspec" -Raw)).package.metadata.version
        $row.Nueva = $row.Anterior

        # update.ps1 returns the AUPackage object (or 'ignore') as its last output
        $result = & .\update.ps1 | Select-Object -Last 1
        $updated = ($result -isnot [string]) -and $result.Updated

        # The new version is already in the Chocolatey feed but not in this repo: it was published by a run
        # whose Git commit was lost (on CI the runner is discarded). AU skips it on every run, so update the
        # files ignoring the feed and record them in Git without pushing to Chocolatey again.
        $registered = $false
        if (-not ($updated -or $Force) -and $result -isnot [string] -and
            ($result.Result -match 'already exists in the Chocolatey community feed')) {
            Write-Host ">>> $name v$($result.RemoteVersion) ya esta en Chocolatey pero no en el repositorio: se actualizan sus archivos para registrarla en Git (sin volver a publicarla)." -ForegroundColor Yellow
            # Chocolatey-AU takes -NoCheckChocoVersion from this global (update.ps1 calls Update-Package itself)
            Set-Variable -Name au_NoCheckChocoVersion -Value $true -Scope Global
            try {
                $result = & .\update.ps1 | Select-Object -Last 1
            } finally {
                # AU reads au_* globals as parameter defaults: the next package must not inherit it
                Remove-Variable -Name au_NoCheckChocoVersion -Scope Global -ErrorAction SilentlyContinue
            }
            $registered = ($result -isnot [string]) -and $result.Updated
            if (-not $registered) { throw "no se pudieron actualizar los archivos de la version ya publicada ($($result.RemoteVersion))." }
        }

        if ($updated -or $registered) {
            $row.Nueva = $result.RemoteVersion
            Write-Host ">>> Actualizacion detectada: $name v$($row.Anterior) -> v$($row.Nueva)" -ForegroundColor Green
        }

        if ($registered) {
            Remove-Item -Path *.nupkg -ErrorAction SilentlyContinue  # already published: nothing to push
            $row.Estado = 'Registrado'
        } elseif (-not ($updated -or $Force)) {
            $row.Estado = 'Al dia'
        } else {
            # Files that update.ps1 generates and the install script reads from tools\ must exist before packing
            $missing = @(Select-String -Path 'tools\*.ps1' -Pattern "Join-Path \`$toolsDir '([^']+)'" -AllMatches |
                ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } |
                Where-Object { -not (Test-Path (Join-Path 'tools' $_)) } | Sort-Object -Unique)
            if ($missing) { throw "Faltan archivos generados por update.ps1 ($($missing -join ', ')): no se publica un paquete roto." }

            # AU already packed the package when it updated it (one .nupkg per updated stream);
            # otherwise (forced) pack it now
            $nupkgs = @(Get-ChildItem -Path *.nupkg)
            if (-not $nupkgs) {
                if (Test-Path "$name.json") {
                    Write-Host "[AVISO] $name usa streams de AU: -Force solo re-empaqueta el stream que esta ahora en la carpeta ($($row.Anterior))." -ForegroundColor Yellow
                }
                Invoke-Tool choco pack --limit-output
                if ($LASTEXITCODE -ne 0) { throw "choco pack fallo (codigo $LASTEXITCODE)" }
                $nupkgs = @(Get-ChildItem -Path *.nupkg)
            }
            $row.Nueva = ($nupkgs | ForEach-Object { $_.BaseName.Substring($name.Length + 1) }) -join ', '

            if ($NoPush) {
                $row.Estado = 'Empaquetado'
            } else {
                $pushed = @(); $notPushed = @()
                foreach ($nupkg in $nupkgs) {
                    $pushArgs = @('push', $nupkg.FullName, '--source', $pushSource, '--limit-output')
                    if ($env:CHOCO_API_KEY) { $pushArgs += @('--api-key', $env:CHOCO_API_KEY) }
                    Invoke-Tool choco @pushArgs
                    $version = $nupkg.BaseName.Substring($name.Length + 1)
                    if ($LASTEXITCODE -eq 0) { $pushed += $version } else { $notPushed += $version }
                }

                if (-not $notPushed) {
                    $row.Estado = if ($updated) { 'Actualizado' } else { 'Forzado' }
                } elseif (-not $pushed) {
                    $row.Estado = 'Push fallido'
                } else {
                    # Some AU streams were published and others were not: keep the published ones and
                    # roll back the failed streams in the streams file, so only they are retried
                    $row.Estado = 'Push parcial'
                    $row.Nueva = $pushed -join ', '
                    $streamsFile = "$name.json"
                    if (Test-Path $streamsFile) {
                        $before = Get-Content -Path (Join-Path $snapshot $streamsFile) -Raw | ConvertFrom-Json
                        $after = Get-Content -Path $streamsFile -Raw | ConvertFrom-Json
                        foreach ($stream in $after.PSObject.Properties) {
                            if ($notPushed -contains $stream.Value) { $stream.Value = $before.($stream.Name) }
                        }
                        $after | ConvertTo-Json | Set-Content -Path $streamsFile -Encoding UTF8
                    }
                    Write-Host "[ERROR] $name : publicado $($pushed -join ', '); fallo $($notPushed -join ', ') (se reintentara)." -ForegroundColor Red
                }
            }
        }
    } catch {
        Write-Host "[ERROR] $name : $_" -ForegroundColor Red
    } finally {
        if (-not $NoPush) { Remove-Item -Path *.nupkg -ErrorAction SilentlyContinue }
        Pop-Location
        # -NoPush publishes nothing, so its changes are always rolled back (only the .nupkg files are kept
        # for review): otherwise the next run would find the new version in the nuspec and never push it
        if ($hasSnapshot -and ($NoPush -or $row.Estado -in 'Error', 'Push fallido')) {
            Get-ChildItem -Path $dir.FullName -Force | Where-Object Extension -NE '.nupkg' | Remove-Item -Recurse -Force
            Copy-Item -Path (Join-Path $snapshot '*') -Destination $dir.FullName -Recurse -Force
            if ($row.Estado -in 'Error', 'Push fallido') {
                Write-Host "[ERROR] $name no se publico: se restauraron sus archivos para reintentarlo en la proxima ejecucion." -ForegroundColor Red
            } elseif ($row.Estado -eq 'Empaquetado' -and $updated) {
                Write-Host "[INFO] -NoPush: .nupkg de $name listo para revisar; sus archivos se restauraron y la proxima ejecucion lo publicara." -ForegroundColor Gray
            } elseif ($row.Estado -eq 'Empaquetado') {
                Write-Host "[INFO] -NoPush: .nupkg forzado de $name ($($row.Nueva)) listo para revisar; no hay version nueva, asi que una ejecucion normal no lo publicara (usa -Force sin -NoPush)." -ForegroundColor Gray
            } elseif ($row.Estado -eq 'Registrado') {
                Write-Host "[INFO] -NoPush: los archivos de $name se restauraron; una ejecucion sin -NoPush registrara en Git la version ya publicada." -ForegroundColor Gray
            }
        }
        Remove-Item -Path $snapshot -Recurse -Force -ErrorAction SilentlyContinue
        # Installers downloaded by AU to calculate checksums (can be hundreds of MB)
        Remove-Item -Path (Join-Path $env:TEMP "chocolatey\$name") -Recurse -Force -ErrorAction SilentlyContinue
    }
    $report.Add($row)
}

Write-Host "`n========================================================"
Write-Host '                RESUMEN DE ACTUALIZACIONES'
Write-Host '========================================================'
$report | Format-Table -AutoSize | Out-String -Width 200 | Write-Host

# --- GIT SYNC: only packages that reached Chocolatey (unpublished ones were restored above) ---
function Sync-GitRemote([bool] $HasNewCommit) {
    # Pushes every local commit, including one left behind by a previous run whose push failed.
    # If the remote moved on meanwhile (e.g. another run), rebase onto it and retry once.
    $ahead = Invoke-Tool git -C $PSScriptRoot rev-list --count '@{u}..HEAD' 2>$null
    if ($LASTEXITCODE -ne 0) {
        # No upstream branch: publish it only if it carries automated commits (from this run or from a
        # previous one whose push failed) that are not on any remote yet
        $pending = @(Invoke-Tool git -C $PSScriptRoot log HEAD --not --remotes --format=%s) -like 'chore: automated update of*'
        if (-not ($HasNewCommit -or $pending)) { return $true }
        $branch = Invoke-Tool git -C $PSScriptRoot symbolic-ref --short -q HEAD
        if (-not $branch) { Write-Host '[ERROR] HEAD desconectado (detached): no se puede hacer push.' -ForegroundColor Red; return $false }
        Invoke-Tool git -C $PSScriptRoot push --set-upstream origin $branch | Out-Host
        return ($LASTEXITCODE -eq 0)
    }
    if (-not ($ahead -as [int])) { return $true }
    Invoke-Tool git -C $PSScriptRoot push | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Invoke-Tool git -C $PSScriptRoot pull --rebase --autostash | Out-Host
        if ($LASTEXITCODE -eq 0) { Invoke-Tool git -C $PSScriptRoot push | Out-Host }
    }
    return ($LASTEXITCODE -eq 0)
}

if ($NoPush -or $NoGit) {
    Write-Host '>>> Git Sync omitido (-NoPush / -NoGit).' -ForegroundColor Gray
} else {
    # Forced pushes count too (e.g. a fix version edited by hand), but only if their folder has changes
    $published = @($report | Where-Object { $_.Estado -in 'Actualizado', 'Push parcial', 'Registrado' -or
        ($_.Estado -eq 'Forzado' -and (Invoke-Tool git -C $PSScriptRoot status --porcelain "$packagesFolder/$($_.Paquete)")) })
    $gitOk = $true
    if ($published) {
        Write-Host '>>> Sincronizando cambios con Git...' -ForegroundColor Cyan
        $paths = @($published | ForEach-Object { "$packagesFolder/$($_.Paquete)" })
        $message = 'chore: automated update of ' + (($published | ForEach-Object { "$($_.Paquete) v$($_.Nueva)" }) -join ', ')
        # Commit only the published packages ("--only"), never other changes the user had already staged
        Invoke-Tool git -C $PSScriptRoot add @paths
        if ($LASTEXITCODE -eq 0) { Invoke-Tool git -C $PSScriptRoot commit --only -m $message @paths }
        $gitOk = ($LASTEXITCODE -eq 0)
    }
    if ($gitOk) { $gitOk = Sync-GitRemote -HasNewCommit ($published.Count -gt 0) }

    if (-not $gitOk) {
        # A local clone keeps the commit and pushes it next time; on CI the commit is lost with the runner,
        # and the next run records the published version again (state 'Registrado')
        Write-Host '[ERROR] Git Sync fallo: los paquetes ya estan en Chocolatey; revisa el commit/push pendiente (la proxima ejecucion lo reintenta o, si el commit se perdio, registra de nuevo la version publicada).' -ForegroundColor Red
        $report.Add([pscustomobject]@{ Paquete = 'git'; Anterior = ''; Nueva = ''; Estado = 'Error' })
    } elseif ($published) {
        Write-Host '>>> Git Sync completado.' -ForegroundColor Green
    } else {
        Write-Host '>>> No hay cambios que sincronizar en Git.' -ForegroundColor Gray
    }
}

$failed = @($report | Where-Object Estado -In 'Error', 'Push fallido', 'Push parcial')
exit $(if ($failed) { 1 } else { 0 })
