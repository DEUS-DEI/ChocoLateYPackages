$ErrorActionPreference = 'Stop'

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://get.nicepage.com/Nicepage-8.7.6-full.exe'
  checksum       = '55b975c26b359a8dde496d457a4a8307e9340f5eb223fdf55b75838db86d0771'
  checksumType   = 'sha256'
  softwareName   = 'Nicepage*'
  silentArgs     = '/S'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
