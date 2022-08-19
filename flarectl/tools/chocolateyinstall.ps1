$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url64bit      = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.47.0/flarectl_0.47.0_windows_amd64.zip'
  checksum64    = 'beeb4898eb66bd2d925449c831e661f1eda92c91c2777f668d9d1f403e3ce66d'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs