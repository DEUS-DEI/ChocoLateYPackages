$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

# Package-only fixes of an upstream version that was already published (Chocolatey "fix version"
# notation). Upstream is still at 2.0.0, so the corrected scripts are published as 2.0.0.20260926.
$packageFixes = @{ '2.0.0' = '2.0.0.20260926' }

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
  $releases = @($releases | Where-Object { -not $_.draft })

  # One package ID, two streams: stable releases, and pre-releases (published as prerelease versions,
  # installed with --pre) while they are newer than the latest stable release
  $candidates = [ordered]@{
    pre    = $releases | Where-Object { $_.prerelease -or $_.tag_name -match '-' } | Select-Object -First 1
    stable = $releases | Where-Object { -not $_.prerelease -and $_.tag_name -notmatch '-' } | Select-Object -First 1
  }

  $streams = [ordered]@{}
  foreach ($stream in $candidates.Keys) {
    $release = $candidates[$stream]
    if (-not $release) { continue }

    # Fenix 2.x: ZIP with an Inno Setup installer; Fenix 3.x: NSIS setup program
    $asset = $release.assets | Where-Object { $_.name -match '^(Fenix\.Setup.*\.exe|fenix-windows-.*\.zip)$' } | Select-Object -First 1
    if (-not $asset) { throw "No Windows installer found in release '$($release.tag_name)'" }

    # Chocolatey only accepts SemVer 1 pre-release labels: 3.0.0-rc.13 -> 3.0.0-rc13
    $tag = $release.tag_name.TrimStart('v')
    if ($tag -notmatch '^(?<version>\d+(?:\.\d+)+)(?:-(?<label>.+))?$') { throw "Unexpected tag '$($release.tag_name)'" }
    $version = if ($Matches.label) { '{0}-{1}' -f $Matches.version, ($Matches.label -replace '\.') } else { $Matches.version }
    if ($packageFixes.ContainsKey($version)) { $version = $packageFixes[$version] }

    $streams[$stream] = @{ Version = $version; URL32 = $asset.browser_download_url }
  }

  # A pre-release older than the latest stable release is obsolete
  if ($streams.Contains('pre') -and $streams.Contains('stable') -and
      [version]($streams.pre.Version -replace '-.*') -le [version]($streams.stable.Version -replace '-.*')) {
    $streams.Remove('pre')
  }

  @{ Streams = $streams }
}

Update-Package -ChecksumFor 32
