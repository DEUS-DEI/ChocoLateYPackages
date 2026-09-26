$ErrorActionPreference = 'Stop'

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url64bit       = 'https://desktop.githubusercontent.com/releases/3.5.7-c5e06544/GitHubDesktopSetup-x64.exe'
  checksum64     = '9d03150cc9ce518f9ebe655050761ae06834b3a8959b0c898395abcb22038e11'
  checksumType64 = 'sha256'
  softwareName   = 'GitHub Desktop*'
  silentArgs     = '-s'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
