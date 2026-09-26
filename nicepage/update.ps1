$ErrorActionPreference = 'Stop'
if (-not (Get-Module Chocolatey-AU, AU)) { Import-Module Chocolatey-AU }

function global:au_SearchReplace {
  @{
    '.\tools\chocolateyinstall.ps1' = @{
      "(?i)(^\s*url\s*=\s*)'.*'"      = "`${1}'$($Latest.URL32)'"
      "(?i)(^\s*checksum\s*=\s*)'.*'" = "`${1}'$($Latest.Checksum32)'"
    }
  }
}

function global:au_GetLatest {
  # The download page is rendered with JavaScript; the desktop app's update manifest is the reliable source
  $manifest = [System.Net.WebClient]::new().DownloadString('https://get.nicepage.com/latest.yml')
  if ($manifest -notmatch '(?m)^version:\s*(?<version>\d+(?:\.\d+)+)\s*$') { throw 'Version not found in latest.yml' }

  @{
    Version = $Matches.version
    URL32   = "https://get.nicepage.com/Nicepage-$($Matches.version)-full.exe"
  }
}

Update-Package -ChecksumFor 32
