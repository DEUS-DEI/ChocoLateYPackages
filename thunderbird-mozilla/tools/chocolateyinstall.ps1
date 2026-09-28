$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$version  = '157.0b4'
$baseUrl  = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version"

# Package parameters: /Language:es-MX  /Arch:win32
$pp   = Get-PackageParameters
$arch = if ($pp['Arch']) {
          # Mozilla's names (win64, win32 and the old win) plus the usual aliases (x64, amd64, 64, x86, 32)
          switch -regex ($pp['Arch']) {
            '^(win)?(32|x86|i?386)$|^win$'  { 'win32'; break }
            '^(win)?(64|x64|amd64|x86_64)$' { 'win64'; break }
            default { throw "Invalid /Arch '$($pp['Arch'])'. Use win64 or win32." }
          }
        }
        elseif ((Get-OSArchitectureWidth -Compare 64) -and $env:chocolateyForceX86 -ne 'true') { 'win64' }
        else { 'win32' }

# tools\checksums.txt holds the Windows lines of Mozilla's SHA256SUMS: "<sha256>  <arch>/<lang>/Thunderbird Setup <version>.exe"
$installers = Get-Content -Path (Join-Path $toolsDir 'checksums.txt') | ForEach-Object {
  if ($_ -match '^(?<hash>[0-9a-fA-F]{64})\s+(?<path>(?<arch>win32|win64)/(?<lang>[^/]+)/Thunderbird Setup .+\.exe)$') {
    New-Object PSObject -Property @{ Hash = $Matches.hash; Path = $Matches.path; Arch = $Matches.arch; Lang = $Matches.lang }
  }
} | Where-Object { $_.Arch -eq $arch }

# Preferred language: /Language, then the Windows display and regional languages, then en-US.
# Mozilla uses both full tags (es-MX, pt-BR) and bare languages (de, fr, ja), so for each tag try
# the exact tag, its base language and any variant of that language.
$requested = @($pp['Language'], (Get-UICulture).Name, (Get-Culture).Name, 'en-US') | Where-Object { $_ }
$installer = $null
foreach ($tag in $requested) {
  $base = $tag.Split('-')[0]
  $installer = @($installers | Where-Object { $_.Lang -eq $tag }) + @($installers | Where-Object { $_.Lang -eq $base }) +
               @($installers | Where-Object { $_.Lang -like "$base-*" }) | Select-Object -First 1
  if ($installer) { break }
}
if (-not $installer) { throw "No Thunderbird $version installer found for architecture '$arch'." }
# Also warn when an explicit /Language gets a variant (es-CO -> es-AR); the automatic choice stays quiet
if ($installer.Lang.Split('-')[0] -ne $requested[0].Split('-')[0] -or ($pp['Language'] -and $installer.Lang -ne $pp['Language'])) {
  Write-Warning "Language '$($requested[0])' is not available for Thunderbird $version; installing '$($installer.Lang)'."
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = "$baseUrl/$($installer.Path -replace ' ', '%20')"
  checksum       = $installer.Hash
  checksumType   = 'sha256'
  softwareName   = 'Mozilla Thunderbird*'
  silentArgs     = '-ms'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
