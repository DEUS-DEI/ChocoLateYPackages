# Pester 5 tests for the scripts in tools/ of the active packages, with the REAL Chocolatey helpers
# (chocolateyInstaller.psm1). Installers never run: every helper that installs, uninstalls or downloads
# from the Internet is mocked. flarectl is extracted for real (Get-ChocolateyWebFile + 7-Zip) from a
# small archive built in TestDrive. Uninstallers read fake registry entries through a mock of
# Get-UninstallRegistryKey that behaves like the real one (it returns $null when nothing matches).
# The package scripts run under Set-StrictMode -Version 2 as a rough PowerShell v2 check.
# Skipped when Chocolatey is not installed. See tests\README.md.

BeforeDiscovery {
    $chocolateyRoot = if ($env:ChocolateyInstall) { $env:ChocolateyInstall } else { Join-Path $env:ProgramData 'chocolatey' }
    $script:NoChocolatey = -not (Test-Path -Path (Join-Path $chocolateyRoot 'helpers\chocolateyInstaller.psm1'))
    $script:Uninstallers = @(Get-ChildItem -Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'Paquetes\actuales\*\tools\chocolateyuninstall.ps1') |
        ForEach-Object { @{ Package = $_.Directory.Parent.Name } })
    $script:Installers = @(Get-ChildItem -Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'Paquetes\actuales\*\tools\chocolateyinstall.ps1') |
        Where-Object { $_.Directory.Parent.Name -ne 'flarectl' } | ForEach-Object { @{ Package = $_.Directory.Parent.Name } })
}

BeforeAll {
    # The active packages (the retired IDs of Paquetes\descontinuados have no scripts)
    $script:PackagesRoot = Join-Path (Split-Path -Parent $PSScriptRoot) 'Paquetes\actuales'
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
        $env:ChocolateyPackageFolder = Join-Path $script:PackagesRoot $Package
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
        ([xml](Get-Content -Path (Join-Path $script:PackagesRoot "$Package\$Package.nuspec") -Raw)).package.metadata.version
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
        $warnings = Invoke-PackageScript (Join-Path $script:PackagesRoot "$Package\tools\chocolateyuninstall.ps1")
        Should -Invoke Uninstall-ChocolateyPackage -Times 0 -Exactly
        $warnings | Should -Contain "$Package has already been uninstalled by other means."
    }

    It 'thunderbird-nightly: uninstalls Daily registered as "<Name>"' -ForEach @(
        @{ Name = 'Daily (x64 es-MX)' }, @{ Name = 'Thunderbird Daily (x64 en-US)' }) {
        Set-Registry (New-Entry $Name "`"$script:Programs\Thunderbird Daily\uninstall\helper.exe`"")
        Set-PackageEnvironment 'thunderbird-nightly' (Get-NuspecVersion 'thunderbird-nightly')
        Invoke-PackageScript (Join-Path $script:PackagesRoot 'thunderbird-nightly\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq "$script:Programs\Thunderbird Daily\uninstall\helper.exe" -and $SilentArgs -eq '/S' }
    }

    It 'thunderbird-nightly: two Daily entries are not uninstalled' {
        Set-Registry @(
            (New-Entry 'Daily (x64 es-MX)' "`"$script:Programs\Thunderbird Daily\uninstall\helper.exe`""),
            (New-Entry 'Thunderbird Daily (x86 en-US)' "`"$script:Programs\Thunderbird Daily\uninstall\helper.exe`""))
        Set-PackageEnvironment 'thunderbird-nightly' (Get-NuspecVersion 'thunderbird-nightly')
        $warnings = Invoke-PackageScript (Join-Path $script:PackagesRoot 'thunderbird-nightly\tools\chocolateyuninstall.ps1')
        Should -Invoke Uninstall-ChocolateyPackage -Times 0 -Exactly
        $warnings | Should -Contain '2 matches found!'
    }

    It 'thunderbird-mozilla: quoted path with spaces' {
        Set-Registry (New-Entry 'Mozilla Thunderbird (x64 es-MX)' "`"$script:Programs\Mozilla Thunderbird\uninstall\helper.exe`"")
        Set-PackageEnvironment 'thunderbird-mozilla' (Get-NuspecVersion 'thunderbird-mozilla')
        Invoke-PackageScript (Join-Path $script:PackagesRoot 'thunderbird-mozilla\tools\chocolateyuninstall.ps1') | Out-Null
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
        Invoke-PackageScript (Join-Path $script:PackagesRoot 'cloudflare-warp-pre\tools\chocolateyuninstall.ps1') | Out-Null
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
        Invoke-PackageScript (Join-Path $script:PackagesRoot 'fenix-web-server\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq (Join-Path $script:Programs $Uninstaller) -and $SilentArgs -eq $Arguments }
    }

    It 'github-desktop-pre: keeps the arguments of the uninstall command' {
        Set-Registry (New-Entry 'GitHub Desktop' "`"$script:Programs\GitHubDesktop\Update.exe`" --uninstall")
        Set-PackageEnvironment 'github-desktop-pre' (Get-NuspecVersion 'github-desktop-pre')
        Invoke-PackageScript (Join-Path $script:PackagesRoot 'github-desktop-pre\tools\chocolateyuninstall.ps1') | Out-Null
        Should -Invoke Uninstall-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $File -eq "$script:Programs\GitHubDesktop\Update.exe" -and $SilentArgs -eq '--uninstall -s' }
    }

    It 'nicepage: unquoted path with spaces and arguments' {
        Set-Registry (New-Entry 'Nicepage 8.7.0' "$script:Programs\Nicepage\Uninstall Nicepage.exe /allusers")
        Set-PackageEnvironment 'nicepage' (Get-NuspecVersion 'nicepage')
        Invoke-PackageScript (Join-Path $script:PackagesRoot 'nicepage\tools\chocolateyuninstall.ps1') | Out-Null
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
        # Fenix 3.x starts a second PowerShell that accepts the notice of its setup program
        Mock Start-Process { }
    }

    It '<Package>: one download from its embedded https URL, verified with sha256' -ForEach $Installers {
        $script = Join-Path $script:PackagesRoot "$Package\tools\chocolateyinstall.ps1"
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) '/Language:es-MX'
        Invoke-PackageScript $script | Out-Null
        # fenix-web-server holds the stream AU updated last: 3.x (setup program) or 2.x (ZIP)
        $command = if ((Get-Content -Path $script -Raw) -match "url\s*=\s*'[^']+\.zip'") { 'Install-ChocolateyZipPackage' } else { 'Install-ChocolateyPackage' }
        Should -Invoke $command -Times 1 -Exactly -ParameterFilter {
            (($Url -like 'https://*' -and $Checksum -match '^[0-9a-fA-F]{64}$' -and $ChecksumType -eq 'sha256') -or
             ($Url64bit -like 'https://*' -and $Checksum64 -match '^[0-9a-fA-F]{64}$' -and $ChecksumType64 -eq 'sha256')) }
    }

    It 'fenix-web-server <Stream>: the helper that accepts the usage statistics notice is started <Times> time(s)' -ForEach @(
        @{ Stream = '3.x (setup program)'; Url = 'https://example.org/Fenix.Setup.3.0.0-rc.13.exe'; Times = 1 },
        @{ Stream = '2.x (ZIP)'; Url = 'https://example.org/fenix-windows-2.0.0.zip'; Times = 0 }) {
        # The repository holds the stream AU updated last: the script of each stream is built from it
        $tools = Join-Path $TestDrive "fenix-stream-$Times\tools"
        New-Item -ItemType Directory -Path $tools -Force | Out-Null
        $text = [System.IO.File]::ReadAllText((Join-Path $script:PackagesRoot 'fenix-web-server\tools\chocolateyinstall.ps1'))
        $text = $text -replace "(?m)^(\s*url\s*=\s*)'.*'", "`${1}'$Url'"
        [System.IO.File]::WriteAllText((Join-Path $tools 'chocolateyinstall.ps1'), $text)
        Set-PackageEnvironment 'fenix-web-server' '3.0.0-rc13'
        Invoke-PackageScript (Join-Path $tools 'chocolateyinstall.ps1') | Out-Null
        Should -Invoke Start-Process -Times $Times -Exactly -ParameterFilter {
            $FilePath -like '*\powershell.exe' -and "$ArgumentList" -like "*$tools\AcceptUsageNotice.ps1*" }
    }

    It '<Package> /Arch:<Arch> installs <Expected>' -ForEach @(
        foreach ($package in 'thunderbird-mozilla', 'thunderbird-nightly') {
            foreach ($case in @('win64', 'win64'), @('WIN64', 'win64'), @('x64', 'win64'), @('amd64', 'win64'), @('64', 'win64'),
                              @('win32', 'win32'), @('win', 'win32'), @('x86', 'win32'), @('32', 'win32')) {
                @{ Package = $package; Arch = $case[0]; Expected = $case[1] }
            }
        }) {
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) "/Language:es-MX /Arch:$Arch"
        Invoke-PackageScript (Join-Path $script:PackagesRoot "$Package\tools\chocolateyinstall.ps1") | Out-Null
        Should -Invoke Install-ChocolateyPackage -Times 1 -Exactly -ParameterFilter {
            $Url -match "[/.]$Expected[/.]" -and $Url -match 'es-MX' -and $Checksum -match '^[0-9a-fA-F]{64}$' }
    }

    It '<Package> rejects an unknown /Arch' -ForEach @(@{ Package = 'thunderbird-mozilla' }, @{ Package = 'thunderbird-nightly' }) {
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) '/Arch:arm64'
        { Invoke-PackageScript (Join-Path $script:PackagesRoot "$Package\tools\chocolateyinstall.ps1") } | Should -Throw "Invalid /Arch 'arm64'*"
        Should -Invoke Install-ChocolateyPackage -Times 0 -Exactly
    }

    It '<Package> warns when the requested language is replaced by a variant' -ForEach @(@{ Package = 'thunderbird-mozilla' }, @{ Package = 'thunderbird-nightly' }) {
        Set-PackageEnvironment $Package (Get-NuspecVersion $Package) '/Language:es-CO /Arch:win64'
        $warnings = Invoke-PackageScript (Join-Path $script:PackagesRoot "$Package\tools\chocolateyinstall.ps1")
        $warnings | Should -BeLike "Language 'es-CO' is not available*"
        Should -Invoke Install-ChocolateyPackage -Times 1 -Exactly
    }
}

Describe 'fenix-web-server: AcceptUsageNotice.ps1 (real message boxes)' {
    # The Fenix 3.x setup program shows a notice that has to be accepted even with /S. The helper is tried
    # against message boxes like that one, shown by another process (they close by themselves in a moment).
    BeforeAll {
        $script:PowerShellExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        $script:NoticeHelper = Join-Path $script:PackagesRoot 'fenix-web-server\tools\AcceptUsageNotice.ps1'
        function script:Show-MessageBox([string] $Text, [string] $AnswerFile) {
            $code = "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('$Text', 'Fenix Setup', 'OKCancel') | Set-Content -Path '$AnswerFile'"
            Start-Process -FilePath $script:PowerShellExe -WindowStyle Hidden -PassThru -ArgumentList "-NoProfile -Command `"$code`""
        }
        function script:Invoke-NoticeHelper([int] $TimeoutSeconds) {
            Start-Process -FilePath $script:PowerShellExe -WindowStyle Hidden -PassThru -Wait -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script:NoticeHelper`" -TimeoutSeconds $TimeoutSeconds"
        }
    }

    It 'answers OK to the usage statistics notice and leaves another dialog of the setup alone' {
        $answer = Join-Path $TestDrive 'notice.txt'
        $other = Show-MessageBox -Text 'Error opening file for writing.' -AnswerFile (Join-Path $TestDrive 'other.txt')
        $notice = Show-MessageBox -Text 'I understand this application collects non-personally identifiable usage statistics from time to time.' -AnswerFile $answer
        try {
            (Invoke-NoticeHelper -TimeoutSeconds 60).ExitCode | Should -Be 0
            $notice.WaitForExit(15000) | Should -BeTrue
            Get-Content -Path $answer | Should -Be 'OK'
            $other.HasExited | Should -BeFalse
        } finally {
            foreach ($process in $other, $notice) { if (-not $process.HasExited) { $process.Kill() } }
        }
    }

    It 'ends with exit code 1 when the notice never shows up' {
        (Invoke-NoticeHelper -TimeoutSeconds 2).ExitCode | Should -Be 1
    }
}

Describe 'Checksums that Chocolatey''s package validator can read (rule CPMR0073)' {
    # The validator reads the scripts without running them. A download whose checksum is decided at install
    # time ($installer.Hash, $table['checksum'], a file in tools\) fails its requirement CPMR0073, the version
    # is held in moderation and Chocolatey answers 403 to every later version of the package. What passes is
    # a quoted checksum, or a plain variable that only ever receives quoted checksums.
    BeforeDiscovery {
        $script:ToolScripts = @(Get-ChildItem -Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'Paquetes\actuales\*\tools\*.ps1') |
            ForEach-Object { @{ Script = "$($_.Directory.Parent.Name)\tools\$($_.Name)" } })
    }

    BeforeAll {
        function script:Get-WrittenString($Ast, $Expression, [int] $Depth = 0) {
            # The strings an argument can be when all of them are written in the script; nothing otherwise
            if ($Expression -is [System.Management.Automation.Language.StringConstantExpressionAst]) { return , @($Expression.Value) }
            if ($Expression -isnot [System.Management.Automation.Language.VariableExpressionAst] -or $Expression.Splatted -or $Depth -gt 5) { return }
            $name = $Expression.VariablePath.UserPath
            $assignments = @($Ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                        $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and $node.Left.VariablePath.UserPath -eq $name }, $true))
            if (-not $assignments) { return }
            $values = foreach ($assignment in $assignments) {
                if ($assignment.Right -isnot [System.Management.Automation.Language.CommandExpressionAst]) { return }
                $written = Get-WrittenString -Ast $Ast -Expression $assignment.Right.Expression -Depth ($Depth + 1)
                if (-not $written) { return }
                $written
            }
            , @($values)
        }

        function script:Get-UnreadableDownload([string] $Text) {
            # One line for every download of the script whose checksum the validator cannot read
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$null, [ref]$null)
            $helpers = 'Install-ChocolateyPackage', 'Install-ChocolateyZipPackage', 'Get-ChocolateyWebFile',
                'Install-ChocolateyPowershellCommand', 'Install-ChocolateyVsixPackage'
            $calls = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true))
            foreach ($call in $calls) {
                $helper = $call.GetCommandName()
                if ($helper -eq 'Get-WebFile' -or $helper -eq 'Get-FtpFile') { "$helper downloads without a checksum" }
                if ($helpers -notcontains $helper) { continue }

                # Arguments by name (hashtable keys are case-insensitive): -Name value, or the table that is splatted
                $arguments = @{}
                $elements = @($call.CommandElements)
                for ($i = 1; $i -lt $elements.Count; $i++) {
                    $element = $elements[$i]
                    if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                        $value = $element.Argument
                        if (-not $value -and $i + 1 -lt $elements.Count -and $elements[$i + 1] -isnot [System.Management.Automation.Language.CommandParameterAst]) { $value = $elements[++$i] }
                        $arguments[$element.ParameterName] = $value
                    } elseif ($element -is [System.Management.Automation.Language.VariableExpressionAst] -and $element.Splatted) {
                        $name = $element.VariablePath.UserPath
                        $tables = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                                    $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and $node.Left.VariablePath.UserPath -eq $name }, $true) |
                                ForEach-Object { $_.Right } | Where-Object { $_ -is [System.Management.Automation.Language.CommandExpressionAst] } |
                                ForEach-Object { $_.Expression } | Where-Object { $_ -is [System.Management.Automation.Language.HashtableAst] })
                        if ($tables.Count -ne 1) { "$helper @$name : the splatted table is not written once in the script"; continue }
                        foreach ($pair in $tables[0].KeyValuePairs) {
                            $statement = $pair.Item2
                            $arguments[[string]$pair.Item1.Value] = if ($statement -is [System.Management.Automation.Language.PipelineAst] -and
                                $statement.PipelineElements.Count -eq 1 -and
                                $statement.PipelineElements[0] -is [System.Management.Automation.Language.CommandExpressionAst]) {
                                $statement.PipelineElements[0].Expression
                            } else { $statement }
                        }
                    }
                }

                $urls = @('Url', 'VsixUrl', 'Url64bit', 'Url64' | Where-Object { $arguments.ContainsKey($_) })
                if (-not $urls) { "$helper : no url argument found (positional arguments are not read)" }
                foreach ($url in $urls) {
                    $checksum = if ($url -like '*64*') { 'Checksum64' } else { 'Checksum' }
                    $written = if ($arguments.ContainsKey($checksum)) { Get-WrittenString -Ast $ast -Expression $arguments[$checksum] }
                    if (-not $written -or @($written | Where-Object { $_ -notmatch '^[0-9a-fA-F]{64}$' })) {
                        "$helper -$url : -$checksum is not a sha256 written in the script"
                    }
                }
            }
        }
    }

    It '<Script>: every download carries a checksum written in the script' -ForEach $ToolScripts {
        $text = [System.IO.File]::ReadAllText((Join-Path $script:PackagesRoot $Script))
        @(Get-UnreadableDownload -Text $text) | Should -BeNullOrEmpty
    }

    It 'accepts <Case>' -ForEach @(
        @{ Case = 'a quoted checksum in the splatted table'
            Text = "`$packageArgs = @{ url64bit = 'https://example.org/a.exe'; checksum64 = '$('a' * 64)' }`nInstall-ChocolateyPackage @packageArgs" },
        @{ Case = 'a variable that only receives quoted checksums'
            Text = "switch (`$arch) { 'win32' { `$checksum = '$('a' * 64)' } 'win64' { `$checksum = '$('b' * 64)' } }`nInstall-ChocolateyPackage -Url `$url -Checksum `$checksum" }) {
        @(Get-UnreadableDownload -Text $Text) | Should -BeNullOrEmpty
    }

    It 'rejects <Case>' -ForEach @(
        @{ Case = 'a checksum taken from an object chosen at install time (thunderbird-mozilla 158.0.0-beta1)'
            Text = "`$packageArgs = @{ url = `"`$baseUrl/`$(`$installer.Path)`"; checksum = `$installer.Hash }`nInstall-ChocolateyPackage @packageArgs" },
        @{ Case = 'a checksum read from a table (fenix-web-server 2.0.0.20260926)'
            Text = "`$download = @{ url = 'https://example.org/a.zip'; checksum = '$('a' * 64)' }`nInstall-ChocolateyZipPackage -Url `$download['url'] -Checksum `$download['checksum']" },
        @{ Case = 'a variable filled at install time'
            Text = "`$checksum = (Get-Content -Path `$file)[0]`nInstall-ChocolateyPackage -Url 'https://example.org/a.exe' -Checksum `$checksum" },
        @{ Case = 'a download without checksum'
            Text = "Get-ChocolateyWebFile -PackageName 'a' -FileFullPath `$file -Url 'https://example.org/a.txt'" }) {
        @(Get-UnreadableDownload -Text $Text) | Should -Not -BeNullOrEmpty
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
        $text = [System.IO.File]::ReadAllText((Join-Path $script:PackagesRoot 'flarectl\tools\chocolateyinstall.ps1'))
        $text = $text -replace "(?m)^(\s*url64bit\s*=\s*)'.*'", "`${1}'$url'" -replace "(?m)^(\s*checksum64\s*=\s*)'.*'", "`${1}'$hash'"
        [System.IO.File]::WriteAllText((Join-Path $script:Tools 'chocolateyinstall.ps1'), $text)
    }

    It 'extracts flarectl.exe into tools and leaves no .tar or download behind' {
        Set-PackageEnvironment 'flarectl' '0.119.0'
        $env:ChocolateyPackageFolder = Split-Path -Parent $script:Tools
        Invoke-PackageScript (Join-Path $script:Tools 'chocolateyinstall.ps1') | Out-Null
        Join-Path $script:Tools 'flarectl.exe' | Should -Exist
        Get-Content -Path (Join-Path $script:Tools 'flarectl.exe') | Should -Be 'not a real program'
        @(Get-ChildItem -Path $script:Tools -Filter '*.tar').Count | Should -Be 0
        Join-Path $env:TEMP 'flarectl\0.119.0' | Should -Not -Exist
    }

    It 'deletes the download when its checksum does not match' {
        $tools = Join-Path $TestDrive 'flarectl-bad\tools'
        New-Item -ItemType Directory -Path $tools | Out-Null
        $text = [System.IO.File]::ReadAllText((Join-Path $script:Tools 'chocolateyinstall.ps1'))
        $text = $text -replace "(?m)^(\s*checksum64\s*=\s*)'.*'", "`${1}'$('0' * 64)'"
        [System.IO.File]::WriteAllText((Join-Path $tools 'chocolateyinstall.ps1'), $text)
        Set-PackageEnvironment 'flarectl' '0.119.0'
        $env:ChocolateyPackageFolder = Split-Path -Parent $tools
        { Invoke-PackageScript (Join-Path $tools 'chocolateyinstall.ps1') *> $null } | Should -Throw '*did not meet*'
        Join-Path $tools 'flarectl.exe' | Should -Not -Exist
        Join-Path $env:TEMP 'flarectl\0.119.0' | Should -Not -Exist
    }
}
