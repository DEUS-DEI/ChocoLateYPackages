$ErrorActionPreference = 'Stop'

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://get.nicepage.com/Nicepage-8.8.2-full.exe'
  checksum       = 'fea9b64fd86ff522c9f6c1523ce820e79b96db5da04c26c71cb23c01707f865d'
  checksumType   = 'sha256'
  softwareName   = 'Nicepage*'
  silentArgs     = '/S'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
