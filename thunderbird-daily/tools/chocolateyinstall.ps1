$packageName= 'thunderbird-daily'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n/thunderbird-105.0a1.en-US.win64.installer.exe'
$FileLocation = Join-Path $toolsDir 'thunderbird-daily.exe'
Get-ChocolateyWebFile -PackageName 'thunderbird-daily' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '2f926db946bf72a9b597da2ebd97c0e8c844b2967f04022c1e360c087ab4c866' `
                      -ChecksumType 'sha256'
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-Childitem -Path $toolsDir -Filter "*.exe").fullname
  silentArgs    = "-ms"
  validExitCodes= @(0)
  softwareName  = 'Daily*'
}
Install-ChocolateyInstallPackage @packageArgs