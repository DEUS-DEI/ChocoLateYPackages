$packageName = 'thunderbird-beta'
$toolsDir    = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$version     = '150.0b4' # This will be updated by AU

# Detect System Language & Architecture
$lang = (Get-Culture).Name
$arch = if ([Environment]::Is64BitOperatingSystem) { "win64" } else { "win" }

$packageParameters = Get-PackageParameters
if ($packageParameters['Language']) { $lang = $packageParameters['Language'] }
if ($packageParameters['Arch']) { $arch = $packageParameters['Arch'] }

$url = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version/$arch/$lang/Thunderbird%20Setup%20$version.exe"
$checksumUrl = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version/SHA256SUMS"

# Get Checksum from Mozilla on the fly
$checksum = ''
try {
    $checksumsFile = Join-Path $toolsDir "checksums.txt"
    Get-ChocolateyWebFile -PackageName "$packageName-checksum" -Url $checksumUrl -FileFullPath $checksumsFile
    
    $fileNamePattern = "$arch/$lang/Thunderbird Setup $version.exe"
    $checksumLine = Get-Content $checksumsFile | Where-Object { $_ -like "*$fileNamePattern*" } | Select-Object -First 1
    if ($checksumLine -match '^(\w+)\s+') {
        $checksum = $Matches[1]
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
  softwareName  = 'Thunderbird*'
}

Install-ChocolateyPackage @packageArgs
