$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*url64bit\s*=\s*)'.*'"   = "`${1}'$($Latest.URL64)'"
      "(?i)(^\s*checksum64\s*=\s*)'.*'" = "`${1}'$($Latest.Checksum64)'"
    }
  }
}

function global:au_GetLatest {
  $release = Invoke-RestMethod -Uri 'https://central.github.com/api/deployments/desktop/desktop/latest?env=beta&os=windows&arch=x64'

  # The API points to the Squirrel update ZIP; the setup program is published next to it
  $url64 = $release.url -replace 'GitHubDesktop-x64\.zip$', 'GitHubDesktopSetup-x64.exe'
  if ($url64 -notlike '*/GitHubDesktopSetup-x64.exe') { throw "Unexpected download URL: $($release.url)" }

  @{
    Version = $release.version  # e.g. 3.6.7-beta2
    URL64   = $url64
  }
}

Update-Package -ChecksumFor 64
