$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

$repository = 'https://github.com/cloudflare/cloudflare-go'

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*url64bit\s*=\s*)'.*'"   = "`${1}'$($Latest.URL64)'"
      "(?i)(^\s*checksum64\s*=\s*)'.*'" = "`${1}'$($Latest.Checksum64)'"
    }
  }
}

function global:au_GetLatest {
  # flarectl is only released from the v0 line of cloudflare-go (v1+ are SDK-only releases).
  # git ls-remote lists the tags without GitHub API rate limits.
  $tags = git ls-remote --tags --refs $repository 'refs/tags/v0.*'
  if ($LASTEXITCODE -ne 0) { throw 'git ls-remote failed' }

  $version = $tags | ForEach-Object { if ($_ -match 'refs/tags/v(?<version>0\.\d+\.\d+)$') { [version]$Matches.version } } |
    Sort-Object -Descending | Select-Object -First 1
  if (-not $version) { throw 'No v0.x tag found' }

  @{
    Version = "$version"
    URL64   = "$repository/releases/download/v$version/flarectl_$($version)_windows_amd64.tar.gz"
  }
}

Update-Package -ChecksumFor 64
