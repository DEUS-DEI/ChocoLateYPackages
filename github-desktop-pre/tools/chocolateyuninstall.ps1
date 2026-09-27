$ErrorActionPreference = 'Stop'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = 'GitHub Desktop*'
  fileType       = 'exe'
  silentArgs     = '-s'
  validExitCodes = @(0)
}

[array]$key = Get-UninstallRegistryKey -SoftwareName $packageArgs['softwareName']

if ($key.Count -eq 1) {
  # The uninstall command may be quoted or not, contain spaces ("C:\Program Files\...") and carry
  # arguments the uninstaller needs (e.g. --uninstall, /currentuser): keep them before the silent switches
  if ($key[0].UninstallString -notmatch '^\s*"?(?<file>[^"]+?\.exe)"?\s*(?<arguments>.*)$') {
    throw "Unrecognized uninstall command: $($key[0].UninstallString)"
  }
  if (-not (Test-Path -LiteralPath $Matches.file)) {
    Write-Warning "$($packageArgs['packageName']) has already been uninstalled by other means ($($Matches.file) not found)."
    return
  }
  $packageArgs['file']       = $Matches.file
  $packageArgs['silentArgs'] = ('{0} {1}' -f $Matches.arguments, $packageArgs['silentArgs']).Trim()

  Uninstall-ChocolateyPackage @packageArgs
} elseif ($key.Count -eq 0) {
  Write-Warning "$($packageArgs['packageName']) has already been uninstalled by other means."
} else {
  Write-Warning "$($key.Count) matches found!"
  Write-Warning 'To prevent accidental data loss, no programs will be uninstalled.'
  Write-Warning 'Please alert the package maintainer that the following keys were matched:'
  $key | ForEach-Object { Write-Warning "- $($_.DisplayName)" }
}
