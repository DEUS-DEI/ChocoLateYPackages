$ErrorActionPreference = 'Stop'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = 'Fenix*'
  fileType       = 'exe'
  validExitCodes = @(0)
}

[array]$key = Get-UninstallRegistryKey -SoftwareName $packageArgs['softwareName']

# Fenix 2.x (stable) and 3.x (pre-release) can be installed side by side: keep the entry of the
# major version this package installed
if ($key.Count -gt 1) {
  $major = ($env:ChocolateyPackageVersion -split '[.-]')[0]
  $sameMajor = @($key | Where-Object { "$($_.DisplayVersion)" -like "$major.*" })
  if ($sameMajor.Count -eq 1) { $key = $sameMajor }
}

if ($key.Count -eq 1) {
  # The uninstall command may be quoted or not, contain spaces ("C:\Program Files\...") and carry
  # arguments the uninstaller needs (e.g. /currentuser): keep them before the silent switches
  if ($key[0].UninstallString -notmatch '^\s*"?(?<file>[^"]+?\.exe)"?\s*(?<arguments>.*)$') {
    throw "Unrecognized uninstall command: $($key[0].UninstallString)"
  }
  $file, $arguments = $Matches.file, $Matches.arguments
  if (-not (Test-Path -LiteralPath $file)) {
    Write-Warning "$($packageArgs['packageName']) has already been uninstalled by other means ($file not found)."
    return
  }
  # Inno Setup (Fenix 2.x, unins000.exe) or NSIS (Fenix 3.x)
  $silentArgs = if ((Split-Path -Leaf $file) -match '^unins\d{3}\.exe$') { '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' } else { '/S' }
  $packageArgs['file']       = $file
  $packageArgs['silentArgs'] = ('{0} {1}' -f $arguments, $silentArgs).Trim()

  Uninstall-ChocolateyPackage @packageArgs
} elseif ($key.Count -eq 0) {
  Write-Warning "$($packageArgs['packageName']) has already been uninstalled by other means."
} else {
  Write-Warning "$($key.Count) matches found!"
  Write-Warning 'To prevent accidental data loss, no programs will be uninstalled.'
  Write-Warning 'Please alert the package maintainer that the following keys were matched:'
  $key | ForEach-Object { Write-Warning "- $($_.DisplayName)" }
}
