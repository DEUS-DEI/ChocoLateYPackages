<# :
@echo off
echo ========================================================
echo Iniciando proceso de actualizacion automatica (AU)
echo MODO SINCRONO Y ROBUSTO
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

$rootDir = $PWD.Path
Import-Module au

$activePackages = @('fenix-web-server', 'fenix-web-server-beta', 'thunderbird-beta', 'thunderbird-daily', 'github-desktop-beta', 'nicepage', 'warp-beta')

foreach ($packageName in $activePackages) {
    Write-Host "====================================="
    Write-Host "Actualizando: $packageName"
    Write-Host "====================================="
    
    Push-Location (Join-Path $rootDir $packageName)

    # Definir funciones específicas para cada paquete
    switch ($packageName) {
        'fenix-web-server' {
            function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://github.com/coreybutler/fenix/releases/download/v$($Latest.Version)/fenix-windows-$($Latest.Version).zip'" } } }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://api.github.com/repos/coreybutler/fenix/releases'
                $latest = $req | Where-Object { $_.prerelease -eq $false -and $_.tag_name -notmatch '-' } | Select-Object -First 1
                return @{ Version = $latest.tag_name.Replace('v', ''); URL32 = ($latest.assets | Where-Object name -like "*windows*.zip").browser_download_url }
            }
            $cf = 32
        }

        'fenix-web-server-beta' {
            function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://github.com/coreybutler/fenix/releases/download/$($Latest.OriginalVersion)/Fenix.Setup.$($Latest.OriginalVersion).exe'" } } }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://api.github.com/repos/coreybutler/fenix/releases'
                $latest = $req | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1
                $urlV = $latest.tag_name.Replace('v', '')
                return @{ Version = ($urlV -replace '-rc\.', '.'); OriginalVersion = $urlV; URL32 = ($latest.assets | Where-Object name -like "Fenix.Setup*.exe").browser_download_url }
            }
            $cf = 32
        }

        'thunderbird-beta' {
            function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$($Latest.OriginalVersion)/win64/en-US/Thunderbird%20Setup%20$($Latest.OriginalVersion).exe'" } } }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json'
                $rv = $req.LATEST_THUNDERBIRD_DEVEL_VERSION
                return @{ Version = ($rv -replace 'b', '.'); OriginalVersion = $rv; URL64 = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$rv/win64/en-US/Thunderbird%20Setup%20$rv.exe" }
            }
            $cf = 64
        }

        'thunderbird-daily' {
            function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n/thunderbird-$($Latest.OriginalVersion).en-US.win64.installer.exe'" } } }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json'
                $rv = $req.LATEST_THUNDERBIRD_NIGHTLY_VERSION
                return @{ Version = ($rv -replace 'a', '.'); OriginalVersion = $rv; URL64 = "https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n/thunderbird-$rv.en-US.win64.installer.exe" }
            }
            $cf = 64
        }

        'github-desktop-beta' {
            function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'$($Latest.URL64)'" } } }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://central.github.com/api/deployments/desktop/desktop/latest?version=beta&os=windows'
                return @{ Version = ($req.version -replace '-beta', ''); URL64 = ($req.url -replace "GitHubDesktop-x64.zip", "GitHubDesktopSetup-x64.exe") }
            }
            $cf = 64
        }

        'nicepage' {
            function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(\$url\s*=\s*)(''.*'')' = "`$1'https://get.nicepage.com/Nicepage-$($Latest.Version)-full.exe'"; '(?i)(-Checksum\s*)(''.*'')' = "`$1'$($Latest.Checksum32)'" } } }
            function global:au_GetLatest {
                $v = "8.4.0"; $resp = Invoke-WebRequest -Uri "https://nicepage.com/download" -UseBasicParsing -ErrorAction SilentlyContinue
                if ($resp.Content -match 'Nicepage-([\d\.]+)-full\.exe') { $v = $Matches[1] }
                return @{ Version = $v; URL32 = "https://get.nicepage.com/Nicepage-$v-full.exe" }
            }
            $cf = 32
        }

        'warp-beta' {
            function global:au_SearchReplace { @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(url64\s*=\s*)(''.*'')' = "`$1'https://downloads.cloudflareclient.com/v1/download/windows/beta'"; '(?i)(checksum64\s*=\s*)(''.*'')' = "`$1'$($Latest.Checksum64)'" } } }
            function global:au_GetLatest {
                $resp = Invoke-WebRequest -Uri "https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/download/beta-releases/" -UseBasicParsing
                $v = "2026.3.13"
                if ($resp.Content -match 'Version\s+([\d\.]+)') { $v = $Matches[1] }
                return @{ Version = $v; URL64 = "https://downloads.cloudflareclient.com/v1/download/windows/beta" }
            }
            $cf = 64
        }
    }

    $updatePath = Join-Path (Get-Location) "update.ps1"
    "function au_GetLatest { au_GetLatest }; function au_SearchReplace { au_SearchReplace }" | Out-File -FilePath $updatePath -Force
    
    try {
        Update-Package -ChecksumFor $cf
    } catch {
        Write-Error "Error en $packageName : $_"
    } finally {
        Remove-Item $updatePath -Force -ErrorAction SilentlyContinue
    }
    
    Pop-Location
}
