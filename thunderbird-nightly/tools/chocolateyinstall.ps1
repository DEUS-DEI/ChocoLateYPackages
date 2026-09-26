$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$version  = '151.0a1'
$baseUrl  = 'https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central'

# Package parameters: /Language:es-MX  /Arch:win32
$pp   = Get-PackageParameters
$arch = if ($pp['Arch']) { $pp['Arch'] -replace '^win$', 'win32' }
        elseif ((Get-OSArchitectureWidth -Compare 64) -and $env:chocolateyForceX86 -ne 'true') { 'win64' }
        else { 'win32' }

# tools\checksums.txt holds the sha256 of every installer of this nightly build, taken from Mozilla's
# manifests: "<sha256>  <build folder>/thunderbird-<version>.<lang>.<arch>.installer.exe"
$installers = Get-Content -Path (Join-Path $toolsDir 'checksums.txt') | ForEach-Object {
  if ($_ -match '^(?<hash>[0-9a-fA-F]{64})\s+(?<path>\S+/thunderbird-.+?\.(?<lang>[A-Za-z-]+)\.(?<arch>win32|win64)\.installer\.exe)$') {
    [pscustomobject]@{ Hash = $Matches.hash; Path = $Matches.path; Arch = $Matches.arch; Lang = $Matches.lang }
  }
} | Where-Object Arch -EQ $arch

# Preferred language: /Language, then the Windows display and regional languages, then en-US.
# Mozilla uses both full tags (es-MX, pt-BR) and bare languages (de, fr, ja), so for each tag try
# the exact tag, its base language and any variant of that language.
$requested = @($pp['Language'], (Get-UICulture).Name, (Get-Culture).Name, 'en-US') | Where-Object { $_ }
$installer = $null
foreach ($tag in $requested) {
  $base = $tag.Split('-')[0]
  $installer = @($installers | Where-Object Lang -EQ $tag) + @($installers | Where-Object Lang -EQ $base) +
               @($installers | Where-Object Lang -Like "$base-*") | Select-Object -First 1
  if ($installer) { break }
}
if (-not $installer) { throw "No Thunderbird Daily $version installer found for architecture '$arch'." }
if ($installer.Lang.Split('-')[0] -ne $requested[0].Split('-')[0]) {
  Write-Warning "Language '$($requested[0])' is not available for Thunderbird Daily $version; installing '$($installer.Lang)'."
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = "$baseUrl/$($installer.Path)"
  checksum       = $installer.Hash
  checksumType   = 'sha256'
  softwareName   = 'Thunderbird Daily*'
  silentArgs     = '-ms'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
