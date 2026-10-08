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
  # Official update feed of the beta track; each item has a versioned (immutable) download URL,
  # so the embedded checksum stays valid after Cloudflare publishes a newer beta
  $feed   = Invoke-RestMethod -Uri 'https://downloads.cloudflareclient.com/v1/update/json/windows/beta'
  $latest = $feed.items | Sort-Object { [version]$_.version } -Descending | Select-Object -First 1
  if (-not $latest.packageURL) { throw 'No release found in the WARP beta feed' }

  @{
    Version = "$($latest.version)-pre"
    URL64   = $latest.packageURL
  }
}

Update-Package -ChecksumFor 64
