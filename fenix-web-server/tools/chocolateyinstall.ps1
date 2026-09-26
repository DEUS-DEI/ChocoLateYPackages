$ErrorActionPreference = 'Stop'

# The ZIP only contains the setup program. It is extracted to a temporary folder instead of the
# package folder, where Chocolatey would create a shim that re-runs the setup.
$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  url           = 'https://github.com/coreybutler/fenix/releases/download/v2.0.0/fenix-windows-2.0.0.zip'
  checksum      = '9b4871180f912464b6683f8bdd843184df58c0e6f970703c304334fd5ddca24e'
  checksumType  = 'sha256'
  unzipLocation = Join-Path $env:TEMP "$($env:ChocolateyPackageName)\$($env:ChocolateyPackageVersion)"
}

Install-ChocolateyZipPackage @packageArgs

try {
  $installer = Get-ChildItem -Path $packageArgs['unzipLocation'] -Filter '*.exe' -Recurse | Select-Object -First 1
  if (-not $installer) { throw 'The setup program was not found inside the downloaded ZIP.' }

  $installArgs = @{
    packageName    = $env:ChocolateyPackageName
    fileType       = 'exe'
    file           = $installer.FullName
    silentArgs     = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
    validExitCodes = @(0)
  }
  Install-ChocolateyInstallPackage @installArgs
} finally {
  Remove-Item -Path $packageArgs['unzipLocation'] -Recurse -Force -ErrorAction SilentlyContinue
}
