$ErrorActionPreference = 'Stop';
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$url64      = 'https://github.com/cloudflare/cloudflare-go/releases/download/v0.45.0/flarectl_0.45.0_windows_amd64.zip' 

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
      FileFullPath  = Join-Path $toolsDir "flarectl.exe"
  url64bit      = $url64
  softwareName  = 'flarectl*' 
  checksum64    = '9f31e7ab673bc70cc897d3d5d29e0301d82b98f6aa8a53259ac2451231550c9b'
  checksumType64= 'sha256' 
 
}

Get-ChocolateyWebFile @packageArgs