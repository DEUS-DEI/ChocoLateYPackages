$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'GitHub Desktop requires Windows 10 or newer.'
}

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url64bit       = 'https://desktop.githubusercontent.com/releases/3.6.8-beta4-288f99ee/GitHubDesktopSetup-x64.exe'
  checksum64     = 'ae9a4e2348683eb03ee09c5a63edc3596de77cc75c4343108191087b769025b1'
  checksumType64 = 'sha256'
  softwareName   = 'GitHub Desktop*'
  silentArgs     = '-s'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
