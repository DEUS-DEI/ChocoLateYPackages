$ErrorActionPreference = 'Stop'

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://github.com/coreybutler/fenix/releases/download/3.0.0-rc.13/Fenix.Setup.3.0.0-rc.13.exe'
  checksum       = '6f2ca055f95a181ea2d9a133a31c1d9b881e894e7c57780a6a3dc529a54e076e'
  checksumType   = 'sha256'
  softwareName   = 'Fenix*'
  silentArgs     = '/S'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
