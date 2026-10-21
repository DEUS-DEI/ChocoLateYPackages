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
  url64bit       = 'https://desktop.githubusercontent.com/releases/3.6.8-beta3-a9cbfe32/GitHubDesktopSetup-x64.exe'
  checksum64     = '17b29dc46012f24f57e6fd14395bcda40358ffab02e6e2cbb1e39350abd885bf'
  checksumType64 = 'sha256'
  softwareName   = 'GitHub Desktop*'
  silentArgs     = '-s'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
