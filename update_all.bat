<# :
@echo off
echo ========================================================
echo AU Maestro: Actualizacion, Push y Limpieza Inteligente
echo ========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Command -ScriptBlock ([ScriptBlock]::Create([IO.File]::ReadAllText('%~f0')))"
echo.
echo ========================================================
echo Proceso finalizado.
echo ========================================================
exit /b
#>

$rootDir = $PWD.Path
Import-Module au

# Función de Limpieza de Basura (Archivos no deseados en el repo)
function Cleanup-Trash {
    Write-Host "`n>>> Ejecutando limpieza de archivos no deseados..." -ForegroundColor Gray
    $trashExtensions = @("*.exe", "*.msi", "*.zip", "*.nupkg", "*.tmp", "*.log", "*.mar", "*.pkg")
    foreach ($ext in $trashExtensions) {
        Get-ChildItem -Path $rootDir -Filter $ext -Recurse | Where-Object { $_.FullName -notmatch "node_modules" } | ForEach-Object {
            Write-Host "    Borrando: $($_.FullName)" -ForegroundColor DarkGray
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

$activePackages = @('fenix-web-server', 'fenix-web-server-beta', 'thunderbird-beta', 'thunderbird-daily', 'github-desktop-beta', 'nicepage', 'warp-beta')

foreach ($packageName in $activePackages) {
    Write-Host "`n>>> Procesando: $packageName" -ForegroundColor Cyan
    
    Push-Location (Join-Path $rootDir $packageName)

    $cf = 0
    switch ($packageName) {
        'fenix-web-server'      { $cf = 32; function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://github.com/coreybutler/fenix/releases/download/v$($Latest.Version)/fenix-windows-$($Latest.Version).zip'" } } }; function global:au_GetLatest { $req = Invoke-RestMethod -Uri 'https://api.github.com/repos/coreybutler/fenix/releases'; $latest = $req | Where-Object { $_.prerelease -eq $false -and $_.tag_name -notmatch '-' } | Select-Object -First 1; return @{ Version = $latest.tag_name.Replace('v', ''); URL32 = ($latest.assets | Where-Object name -like "*windows*.zip").browser_download_url } } }
        'fenix-web-server-beta' { $cf = 32; function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://github.com/coreybutler/fenix/releases/download/$($Latest.OriginalVersion)/Fenix.Setup.$($Latest.OriginalVersion).exe'" } } }; function global:au_GetLatest { $req = Invoke-RestMethod -Uri 'https://api.github.com/repos/coreybutler/fenix/releases'; $latest = $req | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1; $urlV = $latest.tag_name.Replace('v', ''); return @{ Version = ($urlV -replace '-rc\.', '.'); OriginalVersion = $urlV; URL32 = ($latest.assets | Where-Object name -like "Fenix.Setup*.exe").browser_download_url } } }
        'thunderbird-beta'      { function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$version\s*=\s*)(''.*'')' = "`$1'$($Latest.OriginalVersion)'" } } }; function global:au_GetLatest { $req = Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json'; $rv = $req.LATEST_THUNDERBIRD_DEVEL_VERSION; return @{ Version = ($rv -replace 'b', '.'); OriginalVersion = $rv; URL64 = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$rv/SHA256SUMS" } } }
        'thunderbird-daily'     { function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$version\s*=\s*)(''.*'')' = "`$1'$($Latest.OriginalVersion)'" } } }; function global:au_GetLatest { $req = Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json'; $rv = $req.LATEST_THUNDERBIRD_NIGHTLY_VERSION; return @{ Version = ($rv -replace 'a', '.'); OriginalVersion = $rv; URL64 = "https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n/thunderbird-$rv.en-US.win64.checksums" } } }
        'github-desktop-beta'   { $cf = 64; function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'$($Latest.URL64)'" } } }; function global:au_GetLatest { $req = Invoke-RestMethod -Uri 'https://central.github.com/api/deployments/desktop/desktop/latest?version=beta&os=windows'; return @{ Version = ($req.version -replace '-beta', ''); URL64 = ($req.url -replace "GitHubDesktop-x64.zip", "GitHubDesktopSetup-x64.exe") } } }
        'nicepage'              { $cf = 32; function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://get.nicepage.com/Nicepage-$($Latest.Version)-full.exe'"; '(?i)(-Checksum\s*)(''.*'')' = "`$1'$($Latest.Checksum32)'" } } }; function global:au_GetLatest { $v = "8.4.0"; $resp = Invoke-WebRequest -Uri "https://nicepage.com/download" -UseBasicParsing -ErrorAction SilentlyContinue; if ($resp.Content -match 'Nicepage-([\d\.]+)-full\.exe') { $v = $Matches[1] }; return @{ Version = $v; URL32 = "https://get.nicepage.com/Nicepage-$v-full.exe" } } }
        'warp-beta'             { $cf = 64; function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(url64\s*=\s*)(''.*'')' = "`$1'https://downloads.cloudflareclient.com/v1/download/windows/beta'"; '(?i)(checksum64\s*=\s*)(''.*'')' = "`$1'$($Latest.Checksum64)'" } } }; function global:au_GetLatest { $resp = Invoke-WebRequest -Uri "https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/download/beta-releases/" -UseBasicParsing; $v = "2026.3.13"; if ($resp.Content -match 'Version\s+([\d\.]+)') { $v = $Matches[1] }; return @{ Version = $v; URL64 = "https://downloads.cloudflareclient.com/v1/download/windows/beta" } } }
    }

    $updatePath = Join-Path (Get-Location) "update.ps1"
    "function au_GetLatest { au_GetLatest }; function au_SearchReplace { au_SearchReplace }" | Out-File -FilePath $updatePath -Force
    
    try {
        $result = if ($cf -gt 0) { Update-Package -ChecksumFor $cf } else { Update-Package }
        
        if ($result.Updated) {
            Write-Host ">>> Actualizacion detectada. Empaquetando..." -ForegroundColor Yellow
            choco pack
            $nupkg = Get-ChildItem -Filter "*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($nupkg) {
                Write-Host ">>> Subiendo $($nupkg.Name)..." -ForegroundColor Green
                choco push $nupkg.FullName --source "https://push.chocolatey.org/"
            }
        }
    } catch {
        Write-Error "Error en $packageName : $_"
    } finally {
        Remove-Item $updatePath -Force -ErrorAction SilentlyContinue
    }
    
    Pop-Location
}

# Ejecutar limpieza al final del proceso global
Cleanup-Trash
