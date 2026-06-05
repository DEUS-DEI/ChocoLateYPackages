$ErrorActionPreference = 'Stop'
$packageName = $env:ChocolateyPackageName
$minimumSupportedOsVersion = [version]'10.0.18363'

if ([System.Environment]::OSVersion.Version -lt $minimumSupportedOsVersion) {
  Write-Warning 'Cloudflare WARP requires Windows 10 1909+ / Windows Server equivalent. Skipping install on unsupported OS.'
  return
}

$packageArgs = @{
  packageName    = $packageName
  fileType       = 'msi'
  softwareName   = 'Cloudflare WARP*'
  url64          = 'https://downloads.cloudflareclient.com/v1/download/windows/beta'
  checksum64     = 'BB0AA32B70724C829110F4B01435FDC10A6C46B42927E4350D86C989D3389DB5'
  checksumType64 = 'sha256'
  silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:ChocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0,3010,1641)
}

Install-ChocolateyPackage @packageArgs
