$packageName= 'fenix-web-server'
$toolsDir   = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = 'https://github.com/coreybutler/fenix/releases/download/v2.0.0/fenix-windows-2.0.0.zip'

# Step 1: Download the ZIP and extract it (proper Chocolatey pattern)
Install-ChocolateyZipPackage -PackageName  $packageName `
                             -Url          $url `
                             -UnzipLocation $toolsDir `
                             -Checksum     '9b4871180f912464b6683f8bdd843184df58c0e6f970703c304334fd5ddca24e' `
                             -ChecksumType 'sha256'

# Step 2: Run the EXE extracted from the ZIP (no secondary download)
$installerArgs = @{
  packageName   = $packageName
  fileType      = 'exe'
  file          = (Get-ChildItem -Path $toolsDir -Filter "*.exe" -Recurse | Select-Object -First 1).FullName
  silentArgs    = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes= @(0)
}
Install-ChocolateyInstallPackage @installerArgs