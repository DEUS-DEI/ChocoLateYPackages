$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0.18363') {
  throw 'Cloudflare WARP requires Windows 10 version 1909 (build 18363) or newer.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'msi'
  url64bit       = 'https://downloads.cloudflareclient.com/v1/download/windows/beta'
  checksum64     = 'BB0AA32B70724C829110F4B01435FDC10A6C46B42927E4350D86C989D3389DB5'
  checksumType64 = 'sha256'
  softwareName   = 'Cloudflare WARP*'
  silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($env:ChocolateyPackageName).$($env:ChocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs
