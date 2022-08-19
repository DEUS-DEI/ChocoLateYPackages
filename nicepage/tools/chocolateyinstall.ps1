$packageName= 'nicepage'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://get.nicepage.com/Nicepage-4.16.0-full.exe'
$FileLocation = Join-Path $toolsDir 'nicepage.exe'
Get-ChocolateyWebFile -PackageName 'nicepage' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '3dce302ef641418cabcce90cd38814516f16ca7c63fb40c5217aa8e4ced8f2da' `
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