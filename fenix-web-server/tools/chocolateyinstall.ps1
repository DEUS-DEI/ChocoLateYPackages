$packageName= 'fenix-web-server'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/coreybutler/fenix/releases/download/v2.0.0/fenix-windows-2.0.0.zip'
$FileLocation = Join-Path $toolsDir 'fenix-web-server.zip'
Get-ChocolateyWebFile -PackageName 'fenix-web-server' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '9b4871180f912464b6683f8bdd843184df58c0e6f970703c304334fd5ddca24e' `
                      -ChecksumType 'sha256'

Get-ChocolateyUnzip -FileFullPath $FileLocation -Destination $toolsDir

$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-Childitem -Path $toolsDir -Filter "*.exe").fullname
  silentArgs    = ""
  validExitCodes= @(0)
  softwareName  = 'Fenix*'
}
Install-ChocolateyInstallPackage @packageArgs