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

  $release = $releases | Where-Object { $_.prerelease -and -not $_.draft } | Select-Object -First 1
  $asset   = $release.assets | Where-Object name -Like 'Fenix.Setup*.exe' | Select-Object -First 1
  if (-not $asset) { throw "No Windows installer found in release '$($release.tag_name)'" }

  # Chocolatey only accepts SemVer 1 pre-release labels: 3.0.0-rc.13 -> 3.0.0-rc13
  $tag = $release.tag_name.TrimStart('v')
  if ($tag -notmatch '^(?<version>\d+(?:\.\d+)+)-(?<label>.+)$') { throw "Unexpected pre-release tag '$tag'" }

  @{
    Version = '{0}-{1}' -f $Matches.version, ($Matches.label -replace '\.')
    URL32   = $asset.browser_download_url
  }
}

Update-Package -ChecksumFor 32
