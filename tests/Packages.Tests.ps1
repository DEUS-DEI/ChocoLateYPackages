# Pester 5 tests for the package scripts in */tools/ with the REAL Chocolatey helpers
# (chocolateyInstaller.psm1). Installers never run: every helper that installs, uninstalls or downloads
# from the Internet is mocked. flarectl is extracted for real (Get-ChocolateyWebFile + 7-Zip) from a
# small archive built in TestDrive. Uninstallers read fake registry entries through a mock of
# Get-UninstallRegistryKey that behaves like the real one (it returns $null when nothing matches).
# The package scripts run under Set-StrictMode -Version 2 as a rough PowerShell v2 check.
# Skipped when Chocolatey is not installed. See tests\README.md.

BeforeDiscovery {
    $chocolateyRoot = if ($env:ChocolateyInstall) { $env:ChocolateyInstall } else { Join-Path $env:ProgramData 'chocolatey' }
    $script:NoChocolatey = -not (Test-Path -Path (Join-Path $chocolateyRoot 'helpers\chocolateyInstaller.psm1'))
    $script:Uninstallers = @(Get-ChildItem -Path (Join-Path (Split-Path -Parent $PSScriptRoot) '*\tools\chocolateyuninstall.ps1') |
        ForEach-Object { @{ Package = $_.Directory.Parent.Name } })
    $script:Installers = @(Get-ChildItem -Path (Join-Path (Split-Path -Parent $PSScriptRoot) '*\tools\chocolateyinstall.ps1') |
        Where-Object { $_.Directory.Parent.Name -ne 'flarectl' } | ForEach-Object { @{ Package = $_.Directory.Parent.Name } })
}

BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    if (-not $env:ChocolateyInstall) { $env:ChocolateyInstall = Join-Path $env:ProgramData 'chocolatey' }
    $helpers = Join-Path $env:ChocolateyInstall 'helpers\chocolateyInstaller.psm1'
    if (Test-Path -Path $helpers) { Import-Module $helpers -Force -DisableNameChecking }

    # Environment variables that choco sets for a package script
    $script:EnvNames = 'ChocolateyPackageName', 'ChocolateyPackageVersion', 'ChocolateyPackageFolder',
        'chocolateyPackageParameters', 'chocolateyForceX86', 'TEMP', 'TMP'
    $script:SavedEnv = @{}
    foreach ($name in $script:EnvNames) { $script:SavedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }

    function script:Set-PackageEnvironment([string] $Package, [string] $Version, [string] $Parameters = '') {
        $temp = Join-Path $TestDrive 'temp'
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        $env:ChocolateyPackageName = $Package
        $env:ChocolateyPackageVersion = $Version
        $env:ChocolateyPackageFolder = Join-Path $script:RepoRoot $Package
        $env:chocolateyPackageParameters = $Parameters
        $env:chocolateyForceX86 = ''
        $env:TEMP = $temp
        $env:TMP = $temp
    }
    function script:Invoke-PackageScript([string] $Path) {
        # Returns the warnings the script wrote. StrictMode 2 approximates PowerShell v2's property rules.
        & { Set-StrictMode -Version 2; & $Path } 3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] } |
            ForEach-Object { $_.Message }
    }
    function script:Get-NuspecVersion([string] $Package) {
        ([xml](Get-Content -Path (Join-Path $script:RepoRoot "$Package\$Package.nuspec") -Raw)).package.metadata.version
    }
}

AfterAll {
    foreach ($name in $script:EnvNames) { [Environment]::SetEnvironmentVariable($name, $script:SavedEnv[$name], 'Process') }
}

Describe 'Uninstallers' -Skip:$NoChocolatey {
    BeforeAll {
        # Files the fake uninstall entries point to (the scripts check that the uninstaller exists)
        $script:Programs = Join-Path $TestDrive 'Program Files'
        foreach ($file in 'Thunderbird Daily\uninstall\helper.exe', 'Mozilla Thunderbird\uninstall\helper.exe',
                          'GitHubDesktop\Update.exe', 'Nicepage\Uninstall Nicepage.exe', 'Fenix\unins000.exe',
                          'Fenix3\Uninstall Fenix.exe') {
            New-Item -ItemType File -Path (Join-Path $script:Programs $file) -Force | Out-Null
        }
        function script:New-Entry([string] $DisplayName, [string] $UninstallString, [string] $KeyName = $DisplayName, [string] $Version = '1.0') {
            New-Object PSObject -Property @{ DisplayName = $DisplayName; UninstallString = $UninstallString; PSChildName = $KeyName; DisplayVersion = $Version }
        }
        function script:Set-Registry([object[]] $Entries) {
            # The installed programs: $Entries plus other products that the patterns must not pick up
            Set-Variable -Name ChocoLateYPackagesTestRegistry -Value (@($script:Unrelated) + @($Entries)) -Scope Global
        }
        $script:Unrelated = @(
            (New-Entry 'cloudflared' 'MsiExec.exe /X{11111111-1111-1111-1111-111111111111}' '{11111111-1111-1111-1111-111111111111}'),
            (New-Entry 'Firefox Nightly (x64 es-MX)' "`"$script:Programs\Firefox Nightly\uninstall\helper.exe`"")
        )
    }
    BeforeEach {
        Set-Registry @()
        Mock Get-UninstallRegistryKey {
            # A global: the mock runs inside the package script, where $script: is the package script's scope
            $registry = Get-Variable -Name ChocoLateYPackagesTestRegistry -Scope Global -ValueOnly
            $found = @($registry | Where-Object { $_.DisplayName -like $SoftwareName })
            if ($found.Count -eq 0) { return $null }
            $found
        }
        Mock Uninstall-ChocolateyPackage { }
    }
    AfterAll {
        Remove-Variable -Name ChocoLateYPackagesTestRegistry -Scope Global -ErrorAction SilentlyContinue
    }

    It '<Package>: nothing installed, nothing uninstalled' -ForEach $Uninstallers {
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package)
        $warnings = Invoke-PackageScript (Join-Path $script:RepoRoot "$Package\tools\chocolateyuninstall.ps1")
        Should -Invoke Uninstall-ChocolateyPackage -Times 0 -Exactly
        $warnings | Should -Contain "$Package has already been uninstalled by other means."
    }

    It 'thunderbird-nightly: uninstalls Daily registered as "<Name>"' -ForEach @(
        @{ Name = 'Daily (x64 es-MX)' }, @{ Name = 'Thunderbird Daily (x64 en-US)' }) {
        Set-Registry (New-Entry $Name "`"$script:Programs\Thunderbird Daily\uninstall\helper.exe`"")
        Set-PackageEnvironment 'thunderbird-nightly' (Get-NuspecVersion 'thunderbird-nightly')
        Invoke-PackageScript (Join-Path $script:RepoRoot 'thunderbird-nightly\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq "$script:Programs\Thunderbird Daily\uninstall\helper.exe" -and $SilentArgs -eq '/S' }
    }

    It 'thunderbird-nightly: two Daily entries are not uninstalled' {
        Set-Registry @(
            (New-Entry 'Daily (x64 es-MX)' "`"$script:Programs\Thunderbird Daily\uninstall\helper.exe`""),
            (New-Entry 'Thunderbird Daily (x86 en-US)' "`"$script:Programs\Thunderbird Daily\uninstall\helper.exe`""))
        Set-PackageEnvironment 'thunderbird-nightly' (Get-NuspecVersion 'thunderbird-nightly')
        $warnings = Invoke-PackageScript (Join-Path $script:RepoRoot 'thunderbird-nightly\tools\chocolateyuninstall.ps1')
        Should -Invoke Uninstall-ChocolateyPackage -Times 0 -Exactly
        $warnings | Should -Contain '2 matches found!'
    }

    It 'thunderbird-mozilla: quoted path with spaces' {
        Set-Registry (New-Entry 'Mozilla Thunderbird (x64 es-MX)' "`"$script:Programs\Mozilla Thunderbird\uninstall\helper.exe`"")
        Set-PackageEnvironment 'thunderbird-mozilla' (Get-NuspecVersion 'thunderbird-mozilla')
        Invoke-PackageScript (Join-Path $script:RepoRoot 'thunderbird-mozilla\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq "$script:Programs\Mozilla Thunderbird\uninstall\helper.exe" -and $SilentArgs -eq '/S' }
    }

    It 'cloudflare-warp-pre: <Case>' -ForEach @(
        @{ Case = 'current name'; Names = @('Cloudflare One Client'); Expected = '{22222222-2222-2222-2222-222222222222}' },
        @{ Case = 'old name'; Names = @('Cloudflare WARP'); Expected = '{33333333-3333-3333-3333-333333333333}' },
        @{ Case = 'both names, the current one wins'; Names = @('Cloudflare WARP', 'Cloudflare One Client'); Expected = '{22222222-2222-2222-2222-222222222222}' }) {
        $codes = @{ 'Cloudflare One Client' = '{22222222-2222-2222-2222-222222222222}'; 'Cloudflare WARP' = '{33333333-3333-3333-3333-333333333333}' }
        Set-Registry @($Names | ForEach-Object { New-Entry $_ "MsiExec.exe /X$($codes[$_])" $codes[$_] })
        Set-PackageEnvironment 'cloudflare-warp-pre' (Get-NuspecVersion 'cloudflare-warp-pre')
        Invoke-PackageScript (Join-Path $script:RepoRoot 'cloudflare-warp-pre\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $FileType -eq 'msi' -and $SilentArgs -eq "$Expected /qn /norestart" }
    }

    It 'fenix-web-server <Version>: picks the entry of its own major version' -ForEach @(
        @{ Version = '3.0.0-rc13'; Uninstaller = 'Fenix3\Uninstall Fenix.exe'; Arguments = '/currentuser /S' },
        @{ Version = '2.0.0.20260926'; Uninstaller = 'Fenix\unins000.exe'; Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' }) {
        Set-Registry @(
            (New-Entry 'Fenix Web Server 2.0.0' "`"$script:Programs\Fenix\unins000.exe`"" 'Fenix_is1' '2.0.0'),
            (New-Entry 'Fenix 3.0.0-rc.13' "`"$script:Programs\Fenix3\Uninstall Fenix.exe`" /currentuser" 'fenix' '3.0.0-rc.13'))
        Set-PackageEnvironment 'fenix-web-server' $Version
        Invoke-PackageScript (Join-Path $script:RepoRoot 'fenix-web-server\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq (Join-Path $script:Programs $Uninstaller) -and $SilentArgs -eq $Arguments }
    }

    It 'github-desktop-pre: keeps the arguments of the uninstall command' {
        Set-Registry (New-Entry 'GitHub Desktop' "`"$script:Programs\GitHubDesktop\Update.exe`" --uninstall")
        Set-PackageEnvironment 'github-desktop-pre' (Get-NuspecVersion 'github-desktop-pre')
        Invoke-PackageScript (Join-Path $script:RepoRoot 'github-desktop-pre\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq "$script:Programs\GitHubDesktop\Update.exe" -and $SilentArgs -eq '--uninstall -s' }
    }

    It 'nicepage: unquoted path with spaces and arguments' {
        Set-Registry (New-Entry 'Nicepage 8.7.0' "$script:Programs\Nicepage\Uninstall Nicepage.exe /allusers")
        Set-PackageEnvironment 'nicepage' (Get-NuspecVersion 'nicepage')
        Invoke-PackageScript (Join-Path $script:RepoRoot 'nicepage\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq "$script:Programs\Nicepage\Uninstall Nicepage.exe" -and $SilentArgs -eq '/allusers /S' }
    }
}

Describe 'Install scripts' -Skip:$NoChocolatey {
    BeforeEach {
        Mock Install-ChocolateyPackage { }
        Mock Install-ChocolateyInstallPackage { }
        # Fenix 2.x downloads a ZIP with the setup program inside: leave one where the script looks for it
        Mock Install-ChocolateyZipPackage { New-Item -ItemType File -Path (Join-Path $UnzipLocation 'setup.exe') -Force | Out-Null }
    }

    It '<Package>: one download from its embedded https URL, verified with sha256' -ForEach $Installers {
        $script = Join-Path $script:RepoRoot "$Package\tools\chocolateyinstall.ps1"
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) '/Language:es-MX'
        Invoke-PackageScript $script | Out-Null
        # fenix-web-server holds the stream AU updated last: 3.x (setup program) or 2.x (ZIP)
        $command = if ((Get-Content -Path $script -Raw) -match "url\s*=\s*'[^']+\.zip'") { 'Install-ChocolateyZipPackage' } else { 'Install-ChocolateyPackage' }
        Should -Invoke $command -Times 1 -Exactly -ParameterFilter {
            (($Url -like 'https://*' -and $Checksum -match '^[0-9a-fA-F]{64}$' -and $ChecksumType -eq 'sha256') -or
             ($Url64bit -like 'https://*' -and $Checksum64 -match '^[0-9a-fA-F]{64}$' -and $ChecksumType64 -eq 'sha256')) }
    }

    It '<Package> /Arch:<Arch> installs <Expected>' -ForEach @(
        foreach ($package in 'thunderbird-mozilla', 'thunderbird-nightly') {
            foreach ($case in @('win64', 'win64'), @('WIN64', 'win64'), @('x64', 'win64'), @('amd64', 'win64'), @('64', 'win64'),
                              @('win32', 'win32'), @('win', 'win32'), @('x86', 'win32'), @('32', 'win32')) {
                @{ Package = $package; Arch = $case[0]; Expected = $case[1] }
            }
        }) {
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) "/Language:es-MX /Arch:$Arch"
        Invoke-PackageScript (Join-Path $script:RepoRoot "$Package\tools\chocolateyinstall.ps1") | Out-Null
        Should -Invoke Install-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $Url -match "[/.]$Expected[/.]" -and $Url -match 'es-MX' -and $Checksum -match '^[0-9a-fA-F]{64}$' }
    }

    It '<Package> rejects an unknown /Arch' -ForEach @(@{ Package = 'thunderbird-mozilla' }, @{ Package = 'thunderbird-nightly' }) {
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) '/Arch:arm64'
        { Invoke-PackageScript (Join-Path $script:RepoRoot "$Package\tools\chocolateyinstall.ps1") } | Should -Throw "Invalid /Arch 'arm64'*"
        Should -Invoke Install-ChocolateyPackage -Times 0 -Exactly
    }

    It '<Package> warns when the requested language is replaced by a variant' -ForEach @(@{ Package = 'thunderbird-mozilla' }, @{ Package = 'thunderbird-nightly' }) {
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) '/Language:es-CO /Arch:win64'
        $warnings = Invoke-PackageScript (Join-Path $script:RepoRoot "$Package\tools\chocolateyinstall.ps1")
        $warnings | Should -BeLike "Language 'es-CO' is not available*"
        Should -Invoke Install-ChocolateyPackage -Times 1 -Exactly
    }
}

Describe 'flarectl install (real download and extraction)' -Skip:$NoChocolatey {
    BeforeAll {
        # A .tar.gz shaped like the real release: a tar with flarectl.exe, gzip without an embedded file name
        $fixture = Join-Path $TestDrive 'flarectl-fixture'
        New-Item -ItemType Directory -Path $fixture | Out-Null
        Set-Content -Path (Join-Path $fixture 'flarectl.exe') -Value 'not a real program'
        $tar = Join-Path $fixture 'flarectl_0.119.0_windows_amd64.tar'
        & (Join-Path $env:SystemRoot 'System32\tar.exe') -cf $tar -C $fixture flarectl.exe
        $script:Archive = "$tar.gz"
        $in = [System.IO.File]::OpenRead($tar)
        $out = [System.IO.File]::Create($script:Archive)
        $gzip = New-Object System.IO.Compression.GZipStream($out, [System.IO.Compression.CompressionMode]::Compress)
        $in.CopyTo($gzip)
        $gzip.Dispose(); $out.Dispose(); $in.Dispose()
        Remove-Item -Path $tar, (Join-Path $fixture 'flarectl.exe')

        # The package with the install script pointing to the fixture (a file: URL, which Chocolatey
        # downloads without keeping the original file name)
        $script:Tools = Join-Path $TestDrive 'flarectl\tools'
        New-Item -ItemType Directory -Path $script:Tools | Out-Null
        $hash = (Get-FileHash -Path $script:Archive -Algorithm SHA256).Hash.ToLowerInvariant()
        $url = 'file:///' + $script:Archive.Replace('\', '/')
        $text = [System.IO.File]::ReadAllText((Join-Path $script:RepoRoot 'flarectl\tools\chocolateyinstall.ps1'))
        $text = $text -replace "(?m)^(\s*url64bit\s*=\s*)'.*'", "`${1}'$url'" -replace "(?m)^(\s*checksum64\s*=\s*)'.*'", "`${1}'$hash'"
        [System.IO.File]::WriteAllText((Join-Path $script:Tools 'chocolateyinstall.ps1'), $text)
    }

    It 'extracts flarectl.exe into tools and leaves no .tar behind' {
        Set-PackageEnvironment 'flarectl' '0.119.0'
        $env:ChocolateyPackageFolder = Split-Path -Parent $script:Tools
        Invoke-PackageScript (Join-Path $script:Tools 'chocolateyinstall.ps1') | Out-Null
        Join-Path $script:Tools 'flarectl.exe' | Should -Exist
        Get-Content -Path (Join-Path $script:Tools 'flarectl.exe') | Should -Be 'not a real program'
        @(Get-ChildItem -Path $script:Tools -Filter '*.tar').Count | Should -Be 0
        Join-Path $env:TEMP 'flarectl\0.119.0\gz' | Should -Not -Exist
    }
}
