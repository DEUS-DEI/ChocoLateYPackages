$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Since 0.9x flarectl is released as .tar.gz: extract the archive, then the .tar inside it.
# flarectl.exe stays in the package folder, where Chocolatey creates its shim.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  url64bit       = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.45.0/flarectl_0.45.0_windows_amd64.zip'
  checksum64     = '9f31e7ab673bc70cc897d3d5d29e0301d82b98f6aa8a53259ac2451231550c9b'
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

Get-ChildItem -Path $toolsDir -Filter '*.tar' | ForEach-Object {
  Get-ChocolateyUnzip -FileFullPath $_.FullName -Destination $toolsDir
  Remove-Item -Path $_.FullName -Force
}
