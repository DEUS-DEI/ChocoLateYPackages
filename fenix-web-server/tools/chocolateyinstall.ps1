$ErrorActionPreference = 'Stop'

# Updated by Chocolatey-AU. Stable 2.x releases ship a ZIP with an Inno Setup installer inside;
# 3.x pre-releases ship an NSIS setup program.
$download = @{
  url          = 'https://github.com/coreybutler/fenix/releases/download/3.0.0-rc.13/Fenix.Setup.3.0.0-rc.13.exe'
  checksum     = '6f2ca055f95a181ea2d9a133a31c1d9b881e894e7c57780a6a3dc529a54e076e'
  checksumType = 'sha256'
}

if ($download['url'] -like '*.zip') {
  # Extracted to a temporary folder instead of the package folder, where Chocolatey would create a
  # shim that re-runs the setup
  $unzipLocation = Join-Path $env:TEMP "$($env:ChocolateyPackageName)\$($env:ChocolateyPackageVersion)"
  Install-ChocolateyZipPackage -PackageName $env:ChocolateyPackageName -Url $download['url'] -Checksum $download['checksum'] `
                               -ChecksumType $download['checksumType'] -UnzipLocation $unzipLocation
  try {
    $installer = Get-ChildItem -Path $unzipLocation -Filter '*.exe' -Recurse | Select-Object -First 1
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
    Remove-Item -Path $unzipLocation -Recurse -Force -ErrorAction SilentlyContinue
  }
} else {
  # Downloaded to Chocolatey's cache (not the package folder), verified and run
  $packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    fileType       = 'exe'
    url            = $download['url']
    checksum       = $download['checksum']
    checksumType   = $download['checksumType']
    softwareName   = 'Fenix*'
    silentArgs     = '/S'
    validExitCodes = @(0)
  }
  Install-ChocolateyPackage @packageArgs
}
