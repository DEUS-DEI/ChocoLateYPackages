$ErrorActionPreference = 'Stop'

# Install-ChocolateyPackage downloads the installer to Chocolatey's cache (never into the package
# folder, where Chocolatey would create a shim that re-runs the setup), verifies it and runs it.
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileType       = 'exe'
  url            = 'https://get.nicepage.com/Nicepage-8.4.0-full.exe'
  checksum       = 'D9EB11DEF197D5C6D36EBF9A56302D6891E7A03F02F6D89C5126D9554926E21E'
  checksumType   = 'sha256'
  softwareName   = 'Nicepage*'
  silentArgs     = '/S'
  validExitCodes = @(0)
}

Install-ChocolateyPackage @packageArgs
