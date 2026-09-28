$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Since 0.9x flarectl is released as .tar.gz: download it, extract the .tar and then flarectl.exe.
# flarectl.exe stays in the package folder, where Chocolatey creates its shim.
# The .gz has no embedded file name, so 7-Zip names the .tar after the downloaded file. The download gets
# a fixed name and its own folder instead of relying on Chocolatey keeping the original name (it does not
# with file: URLs, mirrors or proxies, and then no .tar was found and the install "succeeded" empty).
$tempDir     = Join-Path $env:TEMP "$($env:ChocolateyPackageName)\$($env:ChocolateyPackageVersion)"
$gzDir       = Join-Path $tempDir 'gz'
$archivePath = Join-Path $tempDir 'flarectl.tar.gz'
$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  fileFullPath   = $archivePath
  url64bit       = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.119.0/flarectl_0.119.0_windows_amd64.tar.gz'
  checksum64     = '5fe4acb54556f06e5f6411676ac6cddc0d336e78205086e22b2a855f9a533663'
  checksumType64 = 'sha256'
}

$archive = Get-ChocolateyWebFile @packageArgs
try {
  Get-ChocolateyUnzip -FileFullPath $archive -Destination $gzDir | Out-Null
  $tar = Get-ChildItem -Path $gzDir -Filter '*.tar' | Select-Object -First 1
  if (-not $tar) { throw "No .tar file found inside $archive." }
  Get-ChocolateyUnzip -FileFullPath $tar.FullName -Destination $toolsDir | Out-Null
} finally {
  Remove-Item -Path $gzDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Not built with Join-Path: update_all.ps1 reads every Join-Path on $toolsDir with a quoted file name as a
# file that update.ps1 must generate before packing, and flarectl.exe only exists after the install
if (-not (Test-Path -Path "$toolsDir\flarectl.exe")) {
  throw 'flarectl.exe was not found in the downloaded archive.'
}
