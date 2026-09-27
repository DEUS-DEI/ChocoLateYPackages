$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Since 0.9x flarectl is released as .tar.gz: extract the archive, then the .tar inside it.
# flarectl.exe stays in the package folder, where Chocolatey creates its shim.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  url64bit       = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.119.0/flarectl_0.119.0_windows_amd64.tar.gz'
  checksum64     = '5fe4acb54556f06e5f6411676ac6cddc0d336e78205086e22b2a855f9a533663'
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

Get-ChildItem -Path $toolsDir -Filter '*.tar' | ForEach-Object {
  Get-ChocolateyUnzip -FileFullPath $_.FullName -Destination $toolsDir
  Remove-Item -Path $_.FullName -Force
}
