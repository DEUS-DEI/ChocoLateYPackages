$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '161.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/11'
$build   = '2026-11-01-09-08-50'

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

# Languages of the installers of this build, from Mozilla's manifests (block written by update.ps1)
# <languages>
$languages = @{
  win32 = @(
    'en-US'
  )
  win64 = @(
    'en-US'
  )
}
# </languages>

# Preferred language: /Language, then the Windows display and regional languages, then en-US.
# Mozilla uses both full tags (es-MX, pt-BR) and bare languages (de, fr, ja), so for each tag try
# the exact tag, its base language and any variant of that language.
$requested = @($pp['Language'], (Get-UICulture).Name, (Get-Culture).Name, 'en-US') | Where-Object { $_ }
$available = @($languages[$arch])
$language  = $null
foreach ($tag in $requested) {
  $base = $tag.Split('-')[0]
  $language = @($available | Where-Object { $_ -eq $tag }) + @($available | Where-Object { $_ -eq $base }) +
              @($available | Where-Object { $_ -like "$base-*" }) | Select-Object -First 1
  if ($language) { break }
}
if (-not $language) { throw "No Thunderbird Daily $version installer found for architecture '$arch'." }
# Also warn when an explicit /Language gets a variant (es-CO -> es-AR); the automatic choice stays quiet
if ($language.Split('-')[0] -ne $requested[0].Split('-')[0] -or ($pp['Language'] -and $language -ne $pp['Language'])) {
  Write-Warning "Language '$($requested[0])' is not available for Thunderbird Daily $version; installing '$language'."
}

# sha256 of that installer, from the same manifests (block written by update.ps1). Every checksum is a
# literal: Chocolatey's package validator (rule CPMR0073) rejects a download whose checksum it cannot read here.
# <checksums>
switch ("$arch/$language") {
  'win32/en-US' { $checksum = 'ec56d34ceb97ca075e5c03ef6c219e6af19e727ba6d4b36f961552b5a6781dc1' }
  'win64/en-US' { $checksum = '87f080a458ac32c2ab393dfe1dc3f77dc662f1915aa05dc642d877c820680b30' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
