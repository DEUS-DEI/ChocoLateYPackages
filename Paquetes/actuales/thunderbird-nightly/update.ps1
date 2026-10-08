$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

$nightlyRoot = 'https://ftp.mozilla.org/pub/thunderbird/nightly'

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*[$]version\s*=\s*)'.*'" = "`${1}'$($Latest.AppVersion)'"
      "(?i)(^\s*[$]baseUrl\s*=\s*)'.*'" = "`${1}'$($Latest.BaseUrl)'"
      "(?i)(^\s*[$]build\s*=\s*)'.*'"   = "`${1}'$($Latest.BuildFolder)'"
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
  $default   = "  {0,-$width} {{ throw `"No Thunderbird Daily `$version installer found for '`$arch/`$language'.`" }}" -f 'default'
  Write-InstallScriptBlock -Name 'checksums' -Lines (@('switch ("$arch/$language") {') + $checksums + $default + '}')
}

function global:au_BeforeUpdate {
  # The "latest-*" folders are overwritten by every nightly build, so the package points to the
  # immutable dated folders of one build: en-US lives in <stamp>-comm-central, other languages in
  # <stamp>-comm-central-l10n. Each installer has its own manifest: "<hash> <algorithm> <size> <file>".
  $client  = [System.Net.WebClient]::new()
  $release = [regex]::Escape($Latest.AppVersion)

  $installers = foreach ($suffix in 'comm-central', 'comm-central-l10n') {
    $folder    = "$($Latest.BaseUrl)/$($Latest.BuildFolder)-$suffix"
    $listing   = $client.DownloadString("$folder/")
    $manifests = [regex]::Matches($listing, "thunderbird-$release\.[A-Za-z-]+\.win(32|64)\.checksums") | ForEach-Object Value | Sort-Object -Unique

    foreach ($manifest in $manifests) {
      foreach ($line in $client.DownloadString("$folder/$manifest") -split '\r?\n') {
        # The install script builds the URL from these three values (see its $folder), so anything
        # published under another name or in the other folder is left out
        if ($line -match "^(?<hash>[0-9a-f]{64}) sha256 \d+ thunderbird-$release\.(?<lang>[A-Za-z-]+)\.(?<arch>win32|win64)\.installer\.exe$" -and
            ($Matches.lang -eq 'en-US') -eq ($suffix -eq 'comm-central')) {
          [pscustomobject]@{ Arch = $Matches.arch; Lang = $Matches.lang; Hash = $Matches.hash }
        }
      }
    }
  }
  if (-not ($installers | Where-Object { $_.Arch -eq 'win64' -and $_.Lang -eq 'en-US' })) {
    throw "en-US installer not found for build $($Latest.BuildFolder)"
  }

  Write-InstallerTable -Installers $installers
}

function global:au_GetLatest {
  $appVersion = (Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/thunderbird_versions.json').LATEST_THUNDERBIRD_NIGHTLY_VERSION
  $buildInfo  = Invoke-RestMethod -Uri "$nightlyRoot/latest-comm-central/thunderbird-$appVersion.en-US.win64.json"
  $buildTime  = [datetime]::ParseExact([string]$buildInfo.buildid, 'yyyyMMddHHmmss', [cultureinfo]::InvariantCulture)

  # Publish at most one nightly per week (or as soon as the version number changes), so the
  # moderation queue is not flooded with a new package version every day
  $current = ([xml](Get-Content -Path '.\thunderbird-nightly.nuspec' -Raw)).package.metadata.version
  if ($current -match '^(?<main>\d+\.\d+)\.1\.(?<stamp>\d{10})-alpha$' -and $Matches.main -eq ($appVersion -replace 'a\d+$') -and
      [datetime]::ParseExact($Matches.stamp, 'yyyyMMddHH', [cultureinfo]::InvariantCulture) -gt $buildTime.AddDays(-7)) {
    Write-Host "Thunderbird Daily $current is less than a week older than build $($buildInfo.buildid): skipped"
    return 'ignore'
  }

  @{
    # 159.0a1 built 2026-09-25 10:19 -> 159.0.1.2026092510-alpha: every nightly build gets its own version
    Version     = '{0}.1.{1:yyyyMMddHH}-alpha' -f ($appVersion -replace 'a\d+$'), $buildTime
    AppVersion  = $appVersion
    BaseUrl     = '{0}/{1:yyyy}/{1:MM}' -f $nightlyRoot, $buildTime
    BuildFolder = $buildTime.ToString('yyyy-MM-dd-HH-mm-ss')
  }
}

# Checksums come from Mozilla's manifests (one per language/architecture), not from downloading the installers
Update-Package -ChecksumFor none
