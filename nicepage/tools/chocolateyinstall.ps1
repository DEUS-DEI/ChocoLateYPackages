$packageName= 'nicepage'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://get.nicepage.com/Nicepage-4.14.1-full.exe'
$FileLocation = Join-Path $toolsDir 'nicepage.exe'
Get-ChocolateyWebFile -PackageName 'nicepage' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '8fa57491ad17c4e42e660a6328ae043791a878d4791f11ceed0d85072804d557' `
                      -ChecksumType 'sha256'
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-Childitem -Path $toolsDir -Filter "*.exe").fullname
  silentArgs    = "/S"
  validExitCodes= @(0)
  softwareName  = 'Nicepage*'
}
Install-ChocolateyInstallPackage @packageArgs