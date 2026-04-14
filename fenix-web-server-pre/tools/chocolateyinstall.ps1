$packageName= 'fenix-web-server-pre'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/coreybutler/fenix/releases/download/3.0.0-rc.13/Fenix.Setup.3.0.0-rc.13.exe'
$FileLocation = Join-Path $toolsDir "$packageName.exe"

# Step 1: Download the installer with checksum verification
Get-ChocolateyWebFile -PackageName $packageName `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '6f2ca055f95a181ea2d9a133a31c1d9b881e894e7c57780a6a3dc529a54e076e' `
                      -ChecksumType 'sha256'

# Step 2: Run the locally downloaded installer (no secondary download)
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = $FileLocation
  silentArgs    = "/S"
  validExitCodes= @(0)
}
Install-ChocolateyInstallPackage @packageArgs
