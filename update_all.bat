<# :
@echo off
echo ========================================================
echo Iniciando proceso de actualizacion automatica (AU)
echo MODO PARALELO Y CENTRALIZADO
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

$jobScriptBlock = {
    param($packageName, $rootDir)
    Import-Module au
    Push-Location (Join-Path $rootDir $packageName)

    switch ($packageName) {
        'fenix-web-server' {
            function global:au_SearchReplace {
                @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(^\s*\$url\s*=\s*)(''.*'')' = "`$1'https://github.com/coreybutler/fenix/releases/download/v$($Latest.Version)/fenix-windows-$($Latest.Version).zip'" } }
            }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://api.github.com/repos/coreybutler/fenix/releases'
                $latest = $req | Where-Object { $_.prerelease -eq $false -and $_.tag_name -notmatch '-' } | Select-Object -First 1
                return @{ Version = $latest.tag_name.Replace('v', ''); URL32 = ($latest.assets | Where-Object name -like "*windows*.zip").browser_download_url }
            }
            $checksumFlag = 32
        }

        'fenix-web-server-beta' {
            function global:au_SearchReplace {
                @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(^\s*\$url\s*=\s*)(''.*'')' = "`$1'https://github.com/coreybutler/fenix/releases/download/$($Latest.OriginalVersion)/Fenix.Setup.$($Latest.OriginalVersion).exe'" } }
            }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://api.github.com/repos/coreybutler/fenix/releases'
                $latest = $req | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1
                $urlVersion = $latest.tag_name.Replace('v', '')
                return @{ Version = ($urlVersion -replace '-rc\.', '-rc'); OriginalVersion = $urlVersion; URL32 = ($latest.assets | Where-Object name -like "Fenix.Setup*.exe").browser_download_url }
            }
            $checksumFlag = 32
        }

        'thunderbird-beta' {
            function global:au_SearchReplace {
                @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(^\s*\$url\s*=\s*)(''.*'')' = "`$1'https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$($Latest.OriginalVersion)/win64/en-US/Thunderbird%20Setup%20$($Latest.OriginalVersion).exe'" } }
            }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json'
                $rawVersion = $req.LATEST_THUNDERBIRD_DEVEL_VERSION
                return @{ Version = ($rawVersion -replace 'b', '-beta'); OriginalVersion = $rawVersion; URL64 = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$rawVersion/win64/en-US/Thunderbird%20Setup%20$rawVersion.exe" }
            }
            $checksumFlag = 64
        }

        'thunderbird-daily' {
            function global:au_SearchReplace {
                @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(^\s*\$url\s*=\s*)(''.*'')' = "`$1'https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n/thunderbird-$($Latest.OriginalVersion).en-US.win64.installer.exe'" } }
            }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json'
                $rawVersion = $req.LATEST_THUNDERBIRD_NIGHTLY_VERSION
                return @{ Version = ($rawVersion -replace 'a', '-alpha'); OriginalVersion = $rawVersion; URL64 = "https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n/thunderbird-$rawVersion.en-US.win64.installer.exe" }
            }
            $checksumFlag = 64
        }

        'github-desktop-beta' {
            function global:au_SearchReplace {
                @{ ".\tools\chocolateyinstall.ps1" = @{ '(?i)(^\s*\$url\s*=\s*)(''.*'')' = "`$1'$($Latest.URL64)'" } }
            }
            function global:au_GetLatest {
                $req = Invoke-RestMethod -Uri 'https://central.github.com/api/deployments/desktop/desktop/latest?version=beta&os=windows'
                return @{ Version = ($req.version -replace '-beta', '-beta'); URL64 = ($req.url -replace "GitHubDesktop-x64.zip", "GitHubDesktopSetup-x64.exe") }
            }
            $checksumFlag = 64
        }
    }

    if ($checksumFlag) {
        try {
            New-Item -ItemType File -Name 'update.ps1' -Value '' -Force | Out-Null
            Update-Package -ChecksumFor $checksumFlag
        } catch {
            Write-Error "Error en $packageName : $_"
        } finally {
            Remove-Item 'update.ps1' -Force -ErrorAction SilentlyContinue
        }
    }
    Pop-Location
}

$activePackages = @('fenix-web-server', 'fenix-web-server-beta', 'thunderbird-beta', 'thunderbird-daily', 'github-desktop-beta')
$jobs = @()

foreach ($pkg in $activePackages) {
    Write-Host "-> Despachando actualización en paralelo para: $pkg"
    $jobs += Start-Job -ScriptBlock $jobScriptBlock -ArgumentList $pkg, $rootDir
}

Write-Host "`nEsperando a que todas las descargas paralelas y revisiones terminen (esto puede tardar debido a los tamaños)..."
Wait-Job -Job $jobs | Out-Null

Write-Host "`nResultados:"
Receive-Job -Job $jobs
Remove-Job -Job $jobs
