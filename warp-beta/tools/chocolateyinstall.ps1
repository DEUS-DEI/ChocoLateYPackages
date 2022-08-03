$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$packageArgs = @{
  packageName    = 'warp-beta'
  fileType       = 'msi'
  softwareName   = 'Cloudflare WARP*'
  file           = @(Get-ChildItem $toolsDir -filter Cloudflare_WARP_Release-*.msi)[0].FullName
  silentArgs     = '/qn /norestart '
  validExitCodes = @(0,3010)
}
Install-ChocolateyInstallPackage @packageArgs
Remove-Item $toolsDir\*.msi -ea 0 -force