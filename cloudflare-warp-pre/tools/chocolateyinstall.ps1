$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageArgs = @{
  packageName    = 'cloudflare-warp-pre'
  fileType       = 'msi'
  softwareName   = 'Cloudflare WARP*'
  url64          = 'https://downloads.cloudflareclient.com/v1/download/windows/beta'
  checksum64     = 'BB0AA32B70724C829110F4B01435FDC10A6C46B42927E4350D86C989D3389DB5'
  checksumType64 = 'sha256'
  silentArgs     = '/qn /norestart '
  validExitCodes = @(0,3010)
}
Install-ChocolateyPackage @packageArgs