$packageName= 'github-desktop-pre'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://desktop.githubusercontent.com/releases/3.5.7-c5e06544/GitHubDesktopSetup-x64.exe'
$FileLocation = Join-Path $toolsDir "$packageName.exe"

# Step 1: Download the installer with checksum verification
Get-ChocolateyWebFile -PackageName $packageName `
                      -Url $url -FileFullPath $FileLocation `
                      -Checksum '9d03150cc9ce518f9ebe655050761ae06834b3a8959b0c898395abcb22038e11' `
                      -ChecksumType 'sha256'

# Step 2: Run the locally downloaded installer (no secondary download)
$packageArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = $FileLocation
  silentArgs    = "-s"
  validExitCodes= @(0)
}
Install-ChocolateyInstallPackage @packageArgs
