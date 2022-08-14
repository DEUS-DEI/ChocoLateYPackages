$packageName= 'thunderbird-beta'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/104.0b3/win64/en-US/Thunderbird%20Setup%20104.0b3.exe'
$FileLocation = Join-Path $toolsDir 'thunderbird-beta.exe'
Get-ChocolateyWebFile -PackageName 'thunderbird-beta' `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum 'c6a9629f4e6c5297bf22476e5f3ae41ff55b292e90ff1adaa28bf5a73adca8ed' `
                      -ChecksumType 'sha256'
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-Childitem -Path $toolsDir -Filter "*.exe").fullname
  silentArgs    = "-ms"
  validExitCodes= @(0)
  softwareName  = 'Mozilla Thunderbird*'
}
Install-ChocolateyInstallPackage @packageArgs