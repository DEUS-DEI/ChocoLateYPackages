$ErrorActionPreference = 'Stop'

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://get.nicepage.com/Nicepage-8.7.0-full.exe'
  checksum       = '2041363ae1002b8c30e00d66a09b25129e9bdd4cf5571b84822bffb964935b60'
  checksumType   = 'sha256'
  softwareName   = 'Nicepage*'
  silentArgs     = '/S'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
