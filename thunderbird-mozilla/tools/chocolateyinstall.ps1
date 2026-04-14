$packageName = 'thunderbird-mozilla'
$toolsDir    = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version     = '125.0b1' # This will be updated by AU

# Detect System Language & Architecture
$lang = (Get-Culture).Name
$arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win" }

$packageParameters = Get-PackageParameters
if ($packageParameters['Language']) { $lang = $packageParameters['Language'] }
if ($packageParameters['Arch']) { $arch = $packageParameters['Arch'] }

$url = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version/$arch/$lang/Thunderbird%20Setup%20$version.exe"

# Get Checksum from local file (embedded during update/pack)
$checksum = ''
$checksumsFile = Join-Path $toolsDir "checksums.txt"

if (Test-Path $checksumsFile) {
    $fileNamePattern = "$arch/$lang/Thunderbird Setup $version.exe"
    $checksumLine = Get-Content $checksumsFile | Where-Object { $_ -like "*$fileNamePattern*" } | Select-Object -First 1
    
    if ($checksumLine -match '^(\w+)\s+') {
        $checksum = $Matches[1]
    } else {
        Write-Warning ">>> Idioma '$lang' no encontrado en el manifiesto de Mozilla. Reintentando con 'en-US'..."
        $lang = 'en-US'
        $url = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version/$arch/$lang/Thunderbird%20Setup%20$version.exe"
        $fileNamePattern = "$arch/$lang/Thunderbird Setup $version.exe"
        $checksumLine = Get-Content $checksumsFile | Where-Object { $_ -like "*$fileNamePattern*" } | Select-Object -First 1
        if ($checksumLine -match '^(\w+)\s+') {
            $checksum = $Matches[1]
        }
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
  silentArgs    = '-ms'
  validExitCodes= @(0)
}

Install-ChocolateyPackage @packageArgs

