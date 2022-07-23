$packageName= 'fenix-web-server-beta'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/coreybutler/fenix/releases/download/3.0.0-rc.13/Fenix.Setup.3.0.0-rc.13.exe'
$FileLocation = Join-Path $toolsDir 'fenix-web-server-beta.exe'
Get-ChocolateyWebFile -PackageName 'fenix-web-server-beta' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '6f2ca055f95a181ea2d9a133a31c1d9b881e894e7c57780a6a3dc529a54e076e' `
                      -ChecksumType 'sha256'
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-Childitem -Path $toolsDir -Filter "*.exe").fullname
  silentArgs    = "/S"
  validExitCodes= @(0)
  softwareName  = 'Fenix*'
}
Install-ChocolateyInstallPackage @packageArgs