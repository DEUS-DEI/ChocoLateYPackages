$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url64bit      = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.46.0/flarectl_0.46.0_windows_amd64.zip'
  checksum64    = 'eb3e5b2aefb232b72b35c336fd14913d60beba8693707e9b3d11466222423507'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs