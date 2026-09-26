$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

$nightlyRoot = 'https://ftp.mozilla.org/pub/thunderbird/nightly'

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*[$]version\s*=\s*)'.*'" = "`${1}'$($Latest.AppVersion)'"
      "(?i)(^\s*[$]baseUrl\s*=\s*)'.*'" = "`${1}'$($Latest.BaseUrl)'"
    }
  }
}

function global:au_BeforeUpdate {
  # The "latest-*" folders are overwritten by every nightly build, so the package points to the
  # immutable dated folders of one build: en-US lives in <stamp>-comm-central, other languages in
  # <stamp>-comm-central-l10n. Each installer has its own manifest: "<hash> <algorithm> <size> <file>".
  $client  = [System.Net.WebClient]::new()
  $release = [regex]::Escape($Latest.AppVersion)

  $lines = foreach ($folder in "$($Latest.BuildFolder)-comm-central", "$($Latest.BuildFolder)-comm-central-l10n") {
    $listing   = $client.DownloadString("$($Latest.BaseUrl)/$folder/")
    $manifests = [regex]::Matches($listing, "thunderbird-$release\.[A-Za-z-]+\.win(32|64)\.checksums") | ForEach-Object Value | Sort-Object -Unique

    foreach ($manifest in $manifests) {
      foreach ($line in $client.DownloadString("$($Latest.BaseUrl)/$folder/$manifest") -split '\r?\n') {
        if ($line -match '^(?<hash>[0-9a-f]{64}) sha256 \d+ (?<file>\S+\.installer\.exe)$') {
          '{0}  {1}/{2}' -f $Matches.hash, $folder, $Matches.file
        }
      }
    }
  }
  if (-not ($lines -match '\.en-US\.win64\.installer\.exe$')) { throw "en-US installer not found for build $($Latest.BuildFolder)" }

  Set-Content -Path '.\tools\checksums.txt' -Value $lines -Encoding Ascii
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
