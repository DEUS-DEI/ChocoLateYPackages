$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0.18363') {
  throw 'Cloudflare WARP requires Windows 10 version 1909 (build 18363) or newer.'
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'msi'
  url64bit       = 'https://downloads.cloudflareclient.com/v1/download/windows/version/2026.8.1955.1'
  checksum64     = '90702c379efc015ff19c34caf6d50f1f71c101a4fa868f184bb679cc22a1b7b3'
  checksumType64 = 'sha256'
  softwareName   = 'Cloudflare One Client*'
  silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($env:ChocolateyPackageName).$($env:ChocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs
