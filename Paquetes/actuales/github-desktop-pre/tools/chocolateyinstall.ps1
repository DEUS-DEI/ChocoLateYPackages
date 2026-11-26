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
  url64bit       = 'https://desktop.githubusercontent.com/releases/3.7.1-beta2-57208311/GitHubDesktopSetup-x64.exe'
  checksum64     = '6cddea9dde3e8e3967287612e8f6cf155f966ef73cba5f0ba1975faaa4beafce'
  checksumType64 = 'sha256'
  softwareName   = 'GitHub Desktop*'
  silentArgs     = '-s'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
