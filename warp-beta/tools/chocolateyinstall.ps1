$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageArgs = @{
  packageName    = 'warp-beta'
  fileType       = 'msi'
  softwareName   = 'Cloudflare WARP*'
  url64          = 'REPLACE_ME_DURING_AU'
  checksum64     = 'REPLACE_ME_DURING_AU'
  checksumType64 = 'sha256'
  silentArgs     = '/qn /norestart '
  validExitCodes = @(0,3010)
}
Install-ChocolateyPackage @packageArgs