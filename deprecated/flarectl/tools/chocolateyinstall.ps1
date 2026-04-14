$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url64bit      = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.47.1/flarectl_0.47.1_windows_amd64.zip'
  checksum64    = '6c271d52f8a50419bd157a28191a96276285e5fa3c1e639ecdf8378f9669998e'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs