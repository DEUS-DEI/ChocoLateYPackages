$packageName = 'thunderbird-nightly'
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

# Get Checksum from local file (embedded during update/pack)
$checksum = ''
$checksumsFile = Join-Path $toolsDir "checksums.txt"

if (Test-Path $checksumsFile) {
    # El archivo de daily tiene un formato: algunshasum algorithm filename
    # O a veces es una lista de hashes. Buscamos la linea que contenga el nombre del archivo.
    $checksumLine = Get-Content $checksumsFile | Select-String -Pattern "(\w+)\s+sha256\s+$fileName"
    if ($checksumLine) {
        $checksum = $checksumLine.Matches.Groups[1].Value
    } elseif ($checksumLine = Get-Content $checksumsFile | Select-String -Pattern "sha256\s+(\w+)\s+$fileName") {
        $checksum = $checksumLine.Matches.Groups[1].Value
    }
}

if (-not $checksum) {
    Write-Error "No se pudo encontrar el checksum para el idioma $lang y arquitectura $arch en el archivo local."
    throw "Instalacion abortada por falta de integridad."
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

