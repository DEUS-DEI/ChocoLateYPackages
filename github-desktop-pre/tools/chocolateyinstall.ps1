$packageName= 'github-desktop-pre'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://desktop.githubusercontent.com/releases/3.5.7-c5e06544/GitHubDesktopSetup-x64.exe'
$FileLocation = Join-Path $toolsDir 'github-desktop-beta.exe'
Get-ChocolateyWebFile -PackageName 'github-desktop-beta' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '9d03150cc9ce518f9ebe655050761ae06834b3a8959b0c898395abcb22038e11' -ChecksumType 'sha256'
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-Childitem -Path $toolsDir -Filter "*.exe").fullname
  silentArgs    = "-s"
  validExitCodes= @(0)
  softwareName  = 'GitHub Desktop*'
}
Install-ChocolateyPackage @packageArgs
