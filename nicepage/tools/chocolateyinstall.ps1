$packageName= 'nicepage'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://get.nicepage.com/Nicepage-8.4.0-full.exe'
$FileLocation = Join-Path $toolsDir 'nicepage.exe'

# Step 1: Download the installer with checksum verification
Get-ChocolateyWebFile -PackageName $packageName `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum 'D9EB11DEF197D5C6D36EBF9A56302D6891E7A03F02F6D89C5126D9554926E21E' `
                      -ChecksumType 'sha256'

# Step 2: Run the locally downloaded installer
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = $FileLocation
  silentArgs    = '/S'
  validExitCodes= @(0)
}
Install-ChocolateyInstallPackage @packageArgs