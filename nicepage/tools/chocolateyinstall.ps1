$packageName= 'nicepage'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://get.nicepage.com/Nicepage-8.4.0-full.exe'
$FileLocation = Join-Path $toolsDir 'nicepage.exe'
Get-ChocolateyWebFile -PackageName 'nicepage' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum 'D9EB11DEF197D5C6D36EBF9A56302D6891E7A03F02F6D89C5126D9554926E21E' `
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