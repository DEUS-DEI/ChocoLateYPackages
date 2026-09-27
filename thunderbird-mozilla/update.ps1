$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*[$]version\s*=\s*)'.*'" = "`${1}'$($Latest.AppVersion)'"
    }
    '.\thunderbird-mozilla.nuspec' = @{
      '(?i)(<releaseNotes>).*(</releaseNotes>)' = "`${1}$($Latest.ReleaseNotes)`${2}"
    }
  }
}

function global:au_BeforeUpdate {
  # Embed only the Windows installer lines of Mozilla's SHA256SUMS manifest (~1600 lines -> ~130)
  $pattern = '^[0-9a-f]{64}\s+win(32|64)/[^/]+/Thunderbird Setup ' + [regex]::Escape($Latest.AppVersion) + '\.exe$'
  $lines   = [System.Net.WebClient]::new().DownloadString($Latest.ChecksumsUrl) -split '\r?\n' -match $pattern
  if (-not ($lines -match ' win64/en-US/')) { throw "No Windows installers found in $($Latest.ChecksumsUrl)" }

  Set-Content -Path '.\tools\checksums.txt' -Value $lines -Encoding Ascii
}

function global:au_GetLatest {
  $appVersion = (Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json').LATEST_THUNDERBIRD_DEVEL_VERSION

  # 157.0b4 -> 157.0-beta4 (release candidates published on the beta channel keep their plain version)
  if ($appVersion -match '^(?<main>\d+\.\d+)b(?<beta>\d+)$') {
    $version      = '{0}-beta{1}' -f $Matches.main, $Matches.beta
    $releaseNotes = "https://www.thunderbird.net/en-US/thunderbird/$($Matches.main)beta/releasenotes/"
  } elseif ($appVersion -match '^\d+\.\d+(\.\d+)?$') {
    $version      = $appVersion
    $releaseNotes = "https://www.thunderbird.net/en-US/thunderbird/$appVersion/releasenotes/"
  } else {
    throw "Unexpected Thunderbird beta version '$appVersion'"
  }

  @{
    Version      = $version
    AppVersion   = $appVersion
    ChecksumsUrl = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$appVersion/SHA256SUMS"
    ReleaseNotes = $releaseNotes
  }
}

# Checksums come from Mozilla's manifest (one per language/architecture), not from downloading the installers
Update-Package -ChecksumFor none
