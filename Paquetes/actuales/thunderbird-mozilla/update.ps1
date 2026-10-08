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

function Write-InstallScriptBlock([string] $Name, [string[]] $Lines) {
  # Replaces the lines between "# <Name>" and "# </Name>" of the install script
  $path = '.\tools\chocolateyinstall.ps1'
  $text = @(Get-Content -Path $path -Encoding UTF8)
  $from = [array]::IndexOf($text, "# <$Name>")
  $to   = [array]::IndexOf($text, "# </$Name>")
  if ($from -lt 0 -or $to -le $from) { throw "Block <$Name> not found in $path" }
  Set-Content -Path $path -Value ($text[0..$from] + $Lines + $text[$to..($text.Count - 1)]) -Encoding UTF8
}

function Write-InstallerTable([object[]] $Installers) {
  # Writes the installers (Arch, Lang, Hash) into the install script as literals. A checksum looked up at
  # install time (a table, a file in tools\) fails Chocolatey's package validator: rule CPMR0073 only
  # accepts a checksum that it can read in the script, and the version stays held in moderation.
  $Installers = @($Installers | Sort-Object -Property Arch, Lang)
  $repeated   = @($Installers | Group-Object -Property Arch, Lang | Where-Object { $_.Count -gt 1 })
  if ($repeated) { throw "Installers listed more than once: $($repeated.Name -join '; ')" }

  $languages = foreach ($arch in $Installers.Arch | Select-Object -Unique) {
    $names = @($Installers | Where-Object { $_.Arch -eq $arch } | ForEach-Object { "'$($_.Lang)'" })
    "  $arch = @("
    for ($i = 0; $i -lt $names.Count; $i += 12) {
      $last = [Math]::Min($i + 11, $names.Count - 1)
      '    ' + ($names[$i..$last] -join ', ') + $(if ($last -lt $names.Count - 1) { ',' })
    }
    '  )'
  }
  Write-InstallScriptBlock -Name 'languages' -Lines (@('$languages = @{') + $languages + '}')

  $width     = ($Installers | ForEach-Object { "$($_.Arch)/$($_.Lang)".Length } | Measure-Object -Maximum).Maximum + 2
  $checksums = $Installers | ForEach-Object { "  {0,-$width} {{ `$checksum = '{1}' }}" -f "'$($_.Arch)/$($_.Lang)'", $_.Hash }
  $default   = "  {0,-$width} {{ throw `"No Thunderbird `$version installer found for '`$arch/`$language'.`" }}" -f 'default'
  Write-InstallScriptBlock -Name 'checksums' -Lines (@('switch ("$arch/$language") {') + $checksums + $default + '}')
}

function global:au_BeforeUpdate {
  # Only the Windows installers of Mozilla's SHA256SUMS manifest (~1600 lines -> ~130)
  $pattern    = '^(?<hash>[0-9a-f]{64})\s+(?<arch>win32|win64)/(?<lang>[^/]+)/Thunderbird Setup ' + [regex]::Escape($Latest.AppVersion) + '\.exe$'
  $installers = foreach ($line in [System.Net.WebClient]::new().DownloadString($Latest.ChecksumsUrl) -split '\r?\n') {
    if ($line -match $pattern) { [pscustomobject]@{ Arch = $Matches.arch; Lang = $Matches.lang; Hash = $Matches.hash } }
  }
  if (-not ($installers | Where-Object { $_.Arch -eq 'win64' -and $_.Lang -eq 'en-US' })) {
    throw "No Windows installers found in $($Latest.ChecksumsUrl)"
  }

  Write-InstallerTable -Installers $installers
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
