$packageName= 'thunderbird-daily'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://ftp.mozilla.org/pub/thunderbird/nightly/latest-comm-central-l10n/thunderbird-104.0a1.en-US.win64.installer.exe'
$FileLocation = Join-Path $toolsDir 'thunderbird-daily.exe'
Get-ChocolateyWebFile -PackageName 'thunderbird-daily' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum 'e17cdf4e465169cffb2e16f7efa57ae6a4ab85ebe3f0ed81af34b3102d768d94' `
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