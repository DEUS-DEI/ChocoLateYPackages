$packageName= 'nicepage'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://get.nicepage.com/Nicepage-4.15.8-full.exe'
$FileLocation = Join-Path $toolsDir 'nicepage.exe'
Get-ChocolateyWebFile -PackageName 'nicepage' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum 'c75c552fcc67ddd09208b1a0108d7029b450aded4a306404fb259c1e1a5d2639' `
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