$ErrorActionPreference = 'Stop'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  softwareName   = 'Cloudflare One Client*'
  fileType       = 'msi'
  silentArgs     = '/qn /norestart'
  validExitCodes = @(0, 3010, 1605, 1614, 1641)
}

# Current betas register as "Cloudflare One Client", older ones as "Cloudflare WARP"
[array]$key = Get-UninstallRegistryKey -SoftwareName $packageArgs['softwareName']
if ($key.Count -eq 0) { [array]$key = Get-UninstallRegistryKey -SoftwareName 'Cloudflare WARP*' }

if ($key.Count -eq 1) {
  # Uninstall-ChocolateyPackage runs "msiexec /x <silentArgs>" and ignores 'file' for MSI,
  # so the product code (the registry key name) has to be the first argument
  $packageArgs['silentArgs'] = "$($key[0].PSChildName) $($packageArgs['silentArgs'])"
  $packageArgs['file']       = ''

  Uninstall-ChocolateyPackage @packageArgs
} elseif ($key.Count -eq 0) {
  Write-Warning "$($packageArgs['packageName']) has already been uninstalled by other means."
} else {
  Write-Warning "$($key.Count) matches found!"
  Write-Warning 'To prevent accidental data loss, no programs will be uninstalled.'
  Write-Warning 'Please alert the package maintainer that the following keys were matched:'
  $key | ForEach-Object { Write-Warning "- $($_.DisplayName)" }
}
