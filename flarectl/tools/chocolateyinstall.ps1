$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$url64      = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.44.0/flarectl_0.44.0_windows_amd64.zip' 

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
      FileFullPath  = Join-Path $toolsDir "flarectl.exe"
  url64bit      = $url64
  softwareName  = 'flarectl*' 
  checksum64    = '1794c7d0fc9b19512d18e62ae41dcf7ddaa41cca313bf2f6f324a094983ad790'
  checksumType64= 'sha256' 
 
}

Get-ChocolateyWebFile @packageArgs