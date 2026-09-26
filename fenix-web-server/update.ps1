$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*url\s*=\s*)'.*'"      = "`${1}'$($Latest.URL32)'"
      "(?i)(^\s*checksum\s*=\s*)'.*'" = "`${1}'$($Latest.Checksum32)'"
    }
  }
}

function global:au_GetLatest {
  # Authenticated requests avoid the 60 requests/hour limit of the anonymous GitHub API
  $headers = @{ 'User-Agent' = 'chocolatey-au' }
  if ($env:GITHUB_TOKEN) { $headers.Authorization = "Bearer $env:GITHUB_TOKEN" }
  $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/coreybutler/fenix/releases' -Headers $headers

  $release = $releases | Where-Object { -not $_.prerelease -and -not $_.draft -and $_.tag_name -notmatch '-' } | Select-Object -First 1
  $asset   = $release.assets | Where-Object name -Like 'fenix-windows-*.zip' | Select-Object -First 1
  if (-not $asset) { throw "No Windows ZIP found in release '$($release.tag_name)'" }

  @{
    Version = $release.tag_name.TrimStart('v')
    URL32   = $asset.browser_download_url
  }
}

Update-Package -ChecksumFor 32
