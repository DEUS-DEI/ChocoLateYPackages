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
  url64bit       = 'https://desktop.githubusercontent.com/releases/3.6.7-beta3-809b4ec0/GitHubDesktopSetup-x64.exe'
  checksum64     = '9123ffe62d6d2a43d239c7014a18095320ff4300bf21ee8017a8c4e53c0b538e'
  checksumType64 = 'sha256'
  softwareName   = 'GitHub Desktop*'
  silentArgs     = '-s'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
