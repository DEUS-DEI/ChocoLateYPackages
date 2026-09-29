$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0.18363') {
  throw 'Cloudflare WARP requires Windows 10 version 1909 (build 18363) or newer.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'msi'
  url64bit       = 'https://downloads.cloudflareclient.com/v1/download/windows/version/2026.8.2028.1'
  checksum64     = '7721007767b3cbb1821dc79297e7d7a3076f900b96481bbafacefeffc6e5f6ad'
  checksumType64 = 'sha256'
  softwareName   = 'Cloudflare One Client*'
  silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($env:ChocolateyPackageName).$($env:ChocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs
