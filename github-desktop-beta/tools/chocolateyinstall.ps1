$packageName= 'github-desktop-beta'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://central.github.com/deployments/desktop/desktop/latest/win32?env=beta'
$FileLocation = Join-Path $toolsDir 'github-desktop-beta.exe'
Get-ChocolateyWebFile -PackageName 'github-desktop-beta' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '1035f6ef8a1a99f21f539d5e9b16ae49f791518647c7e3f4f4ba68cc633612b6' -ChecksumType 'sha256'
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-Childitem -Path $toolsDir -Filter "*.exe").fullname
  silentArgs    = "-s"
  validExitCodes= @(0)
  softwareName  = 'GitHub Desktop*'
}
Install-ChocolateyInstallPackage @packageArgs