$ErrorActionPreference = 'Stop'

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://get.nicepage.com/Nicepage-9.0.5-full.exe'
  checksum       = '44f30f9111a9bb4419d3db959bb55e28d5b21b7acfc175463fee0f745b3b5ac7'
  checksumType   = 'sha256'
  softwareName   = 'Nicepage*'
  silentArgs     = '/S'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
