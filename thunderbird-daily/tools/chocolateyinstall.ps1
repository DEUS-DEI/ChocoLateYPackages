$packageName = 'thunderbird-daily'
$toolsDir    = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version     = '151.0a1' # This will be updated by AU

# Detect System Language & Architecture
$lang = (Get-Culture).Name
$arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win32" }

$packageParameters = Get-PackageParameters
if ($packageParameters['Language']) { $lang = $packageParameters['Language'] }
if ($packageParameters['Arch']) { $arch = $packageParameters['Arch'] }

$baseUrl = "https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n"
$fileName = "thunderbird-$version.$lang.$arch.installer.exe"
$url = "$baseUrl/$fileName"
$checksumUrl = "$baseUrl/thunderbird-$version.$lang.$arch.checksums"

# Get Checksum from Mozilla on the fly
$checksum = ''
try {
    $checksumsFile = Join-Path $toolsDir "checksums.txt"
    Get-ChocolateyWebFile -PackageName "$packageName-checksum" -Url $checksumUrl -FileFullPath $checksumsFile
    $checksumLine = Get-Content $checksumsFile | Select-String -Pattern "sha256\s+(\w+)\s+$fileName"
    if ($checksumLine) {
        $checksum = $checksumLine.Matches.Groups[1].Value
    }
    Remove-Item $checksumsFile -ErrorAction SilentlyContinue
} catch {
    Write-Warning "No se pudo validar el checksum para el idioma $lang y arquitectura $arch."
}

$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  url           = $url
  checksum      = $checksum
  checksumType  = 'sha256'
  silentArgs    = "-ms"
  validExitCodes= @(0)
  softwareName  = 'Daily*'
}

Install-ChocolateyPackage @packageArgs
