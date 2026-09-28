# Pester 5 tests for the maintenance entry points (push_deprecated.bat, menu.bat, update_all.bat and
# update_all.ps1) on Windows PowerShell 5.1 and the real cmd.exe. Nothing is published: a fake choco.exe
# (tests\fakes\FakeChoco.cs) is first in PATH, Chocolatey-AU is replaced by a stub module and Git only
# pushes to a bare repository inside TestDrive. See tests\README.md.

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:FakeLog = Join-Path $TestDrive 'fake.log'
    $script:FakePath = Install-FakeChoco -Directory (Join-Path $TestDrive 'bin')

    # A repository path with the characters that broke the scripts: "!" (delayed expansion), "^" (CALL
    # doubles it), "&", "(" and ")" (cmd syntax) and spaces
    $script:Special = Join-Path $TestDrive 'a^b (1) & c!'
    New-Item -ItemType Directory -Path $script:Special | Out-Null
    foreach ($file in 'push_deprecated.bat', 'menu.bat', 'update_all.bat') {
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot $file) -Destination $script:Special
    }
    Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'deprecated') -Destination $script:Special -Recurse

    # The caller's folder: its .nupkg and nuspec must never be deleted, packed or pushed
    $script:Caller = Join-Path $TestDrive 'caller'
    New-Item -ItemType Directory -Path $script:Caller | Out-Null

    function script:Reset-Caller {
        Remove-Item -LiteralPath $script:FakeLog -ErrorAction SilentlyContinue
        Get-ChildItem -LiteralPath $script:Caller | Remove-Item -Force
        Set-Content -LiteralPath (Join-Path $script:Caller 'canary.nupkg') -Value 'canary'
        Set-Content -LiteralPath (Join-Path $script:Caller 'other.nuspec') -Value '<package><metadata><id>other</id><version>1.2.3</version></metadata></package>'
    }
    function script:Get-BaseEnvironment {
        @{ PATH = $script:FakePath; FAKE_LOG = $script:FakeLog; CHOCO_API_KEY = $null
           FAKE_CHOCO_PACK_EXIT = $null; FAKE_CHOCO_PUSH_EXIT = $null }
    }
}

Describe 'push_deprecated.bat' {
    BeforeAll {
        $script:Bridges = @(Get-ChildItem -LiteralPath (Join-Path $script:Special 'deprecated') -Directory | ForEach-Object Name)
        $script:PushDeprecated = Join-Path $script:Special 'push_deprecated.bat'
    }

    It 'packs and pushes only the bridges, from any caller folder and repository path' {
        Reset-Caller
        $run = Invoke-TestBatch -Script $script:PushDeprecated -Arguments '--no-pause' -WorkingDirectory $script:Caller -Environment (Get-BaseEnvironment)
        $run.ExitCode | Should -Be 0
        $log = Get-FakeLog $script:FakeLog
        @($log | Where-Object { $_ -match '\[pack\]' }).Count | Should -Be $script:Bridges.Count
        @($log | Where-Object { $_ -match '\[push\]' }).Count | Should -Be $script:Bridges.Count
        foreach ($line in $log) {
            $line | Should -Match ([regex]::Escape("cwd=[$script:Special\deprecated\"))
        }
        foreach ($bridge in $script:Bridges) {
            $log -match "\[push\] \[$([regex]::Escape($bridge))\.999\.0\.0\.nupkg\] \[--source=https://push\.chocolatey\.org/\]" | Should -Not -BeNullOrEmpty
        }
        Join-Path $script:Caller 'canary.nupkg' | Should -Exist
        @(Get-ChildItem -LiteralPath (Join-Path $script:Special 'deprecated') -Recurse -Filter '*.nupkg').Count | Should -Be 0
    }

    It 'passes CHOCO_API_KEY to every push without printing it' {
        Reset-Caller
        $environment = Get-BaseEnvironment
        $environment.CHOCO_API_KEY = 'test-key-0123456789'
        $run = Invoke-TestBatch -Script $script:PushDeprecated -Arguments '--no-pause' -WorkingDirectory $script:Caller -Environment $environment
        $run.ExitCode | Should -Be 0
        $run.Output | Should -Not -Match 'test-key'
        @(Get-FakeLog $script:FakeLog | Where-Object { $_ -match '\[--api-key=<apikey len=19>\]' }).Count | Should -Be $script:Bridges.Count
    }

    It 'exits with 1 when a push fails' {
        Reset-Caller
        $environment = Get-BaseEnvironment
        $environment.FAKE_CHOCO_PUSH_EXIT = '1'
        $run = Invoke-TestBatch -Script $script:PushDeprecated -Arguments '--no-pause' -WorkingDirectory $script:Caller -Environment $environment
        $run.ExitCode | Should -Be 1
        $run.Output | Should -Match 'CON ERRORES'
        $run.Output | Should -Not -Match '\[OK\]'
    }

    It 'exits with 1 and pushes nothing when packing fails' {
        Reset-Caller
        $environment = Get-BaseEnvironment
        $environment.FAKE_CHOCO_PACK_EXIT = '1'
        $run = Invoke-TestBatch -Script $script:PushDeprecated -Arguments '--no-pause' -WorkingDirectory $script:Caller -Environment $environment
        $run.ExitCode | Should -Be 1
        @(Get-FakeLog $script:FakeLog | Where-Object { $_ -match '\[push\]' }).Count | Should -Be 0
        Join-Path $script:Caller 'canary.nupkg' | Should -Exist
    }
}

Describe 'update_all.bat and menu.bat' {
    BeforeAll {
        # update_all.ps1 replaced by a stub that records how its parameters were bound
        $script:StubLog = Join-Path $TestDrive 'stub.log'
        Set-Content -LiteralPath (Join-Path $script:Special 'update_all.ps1') -Encoding Ascii -Value @'
param([string[]] $Package, [switch] $Force, [switch] $NoPush, [switch] $NoGit)
Add-Content -LiteralPath $env:STUB_LOG -Value ('Package=[{0}] Force={1} NoPush={2} NoGit={3} Cwd=[{4}]' -f ($Package -join '|'), [bool]$Force, [bool]$NoPush, [bool]$NoGit, (Get-Location).Path)
exit [int]$env:STUB_EXIT
'@
        foreach ($package in 'pkga', 'pkgb') {
            New-Item -ItemType Directory -Path (Join-Path $script:Special $package) | Out-Null
            Set-Content -LiteralPath (Join-Path $script:Special "$package\update.ps1") -Value '# test package'
        }
        function script:Invoke-Menu([string] $InputText, [int] $TimeoutSeconds = 60) {
            Remove-Item -LiteralPath $script:StubLog -ErrorAction SilentlyContinue
            $environment = Get-BaseEnvironment
            $environment.STUB_LOG = $script:StubLog
            $environment.STUB_EXIT = '0'
            Invoke-TestBatch -Script '.\menu.bat' -WorkingDirectory $script:Special -Environment $environment `
                -InputText $InputText -TimeoutSeconds $TimeoutSeconds
        }
    }

    It 'update_all.bat binds the arguments and returns the exit code of update_all.ps1' {
        Remove-Item -LiteralPath $script:StubLog -ErrorAction SilentlyContinue
        $environment = Get-BaseEnvironment
        $environment.STUB_LOG = $script:StubLog
        $environment.STUB_EXIT = '3'
        $run = Invoke-TestBatch -Script (Join-Path $script:Special 'update_all.bat') -Arguments '-Package a,b -Force -NoPush -NoGit' `
            -WorkingDirectory $script:Caller -Environment $environment
        $run.ExitCode | Should -Be 3
        Get-Content -LiteralPath $script:StubLog | Should -BeLike 'Package=`[a,b`] Force=True NoPush=True NoGit=True*'
    }

    It 'menu options 1 and 2 run update_all from the repository folder' {
        $run = Invoke-Menu "1`r`n2`r`n5"
        $run.TimedOut | Should -BeFalse
        $calls = @(Get-Content -LiteralPath $script:StubLog)
        $calls.Count | Should -Be 2
        $calls[0] | Should -BeLike 'Package=`[`] Force=False NoPush=False NoGit=False*'
        $calls[1] | Should -BeLike 'Package=`[`] Force=True *'
        $calls[0] | Should -BeLike "*Cwd=``[$script:Special``]"
    }

    It 'menu option 3 forces the chosen package and rejects anything that is not a number of the list' {
        $hostile = '1&echo PWNED>pwned.txt', '|', '>x', '%PATH%', '!PATH!', '"', ')', '0', '99', '1^&whoami'
        # choice takes the "3" alone, then each set /p reads one line
        $inputText = '3' + (($hostile + @('2', 'B', '5')) -join "`r`n")
        $run = Invoke-Menu $inputText
        $run.TimedOut | Should -BeFalse
        @(Get-Content -LiteralPath $script:StubLog) | Should -Be @("Package=[pkgb] Force=True NoPush=False NoGit=False Cwd=[$script:Special]")
        ([regex]::Matches($run.Output, 'Seleccion invalida')).Count | Should -Be $hostile.Count
        Join-Path $script:Special 'pwned.txt' | Should -Not -Exist
        Join-Path $script:Special 'x' | Should -Not -Exist
    }

    It 'menu exits on its own when the input ends in the package list (no endless loop)' {
        $started = Get-Date
        $run = Invoke-Menu '3' -TimeoutSeconds 45
        $run.TimedOut | Should -BeFalse
        $run.Output | Should -Match 'Saliendo\.\.\.'
        ((Get-Date) - $started).TotalSeconds | Should -BeLessThan 40
        Test-Path -LiteralPath $script:StubLog | Should -BeFalse
    }
}

Describe 'update_all.ps1' {
    BeforeAll {
        # Chocolatey-AU stub: the package is at 1.0.0 and upstream at $env:STUB_REMOTE_VERSION.
        # With STUB_IN_FEED=1 that version is already in the Chocolatey feed, which real AU reports and
        # skips unless -NoCheckChocoVersion (or its global au_NoCheckChocoVersion) is given.
        $modules = Join-Path $TestDrive 'modules'
        New-Item -ItemType Directory -Path (Join-Path $modules 'Chocolatey-AU') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $modules 'Chocolatey-AU\Chocolatey-AU.psm1') -Encoding Ascii -Value @'
function Update-Package {
    param([switch] $NoCheckChocoVersion)
    Write-Host 'STUB-AU'
    $nuspec = (Get-ChildItem -Filter *.nuspec | Select-Object -First 1).FullName
    $current = ([xml](Get-Content -LiteralPath $nuspec -Raw)).package.metadata.version
    $noCheck = $NoCheckChocoVersion -or (Get-Variable -Name au_NoCheckChocoVersion -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
    $package = [pscustomobject]@{ NuspecVersion = $current; RemoteVersion = $env:STUB_REMOTE_VERSION; Updated = $false; Result = @() }
    if ([version]$env:STUB_REMOTE_VERSION -le [version]$current) { $package.Result += 'No new version found'; return $package }
    if ($env:STUB_IN_FEED -eq '1' -and -not $noCheck) {
        $package.Result += 'New version is available but it already exists in the Chocolatey community feed (disable using $NoCheckChocoVersion):'
        return $package
    }
    $text = [IO.File]::ReadAllText($nuspec).Replace("<version>$current</version>", "<version>$($env:STUB_REMOTE_VERSION)</version>")
    [IO.File]::WriteAllText($nuspec, $text)
    choco pack --limit-output | Out-Null
    $package.Updated = $true
    $package
}
Export-ModuleMember -Function Update-Package
'@
        # Repository with one package ("demo" 1.0.0), cloned from a bare remote
        $seed = Join-Path $TestDrive 'ua-seed'
        New-Item -ItemType Directory -Path (Join-Path $seed 'demo\tools') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'update_all.ps1') -Destination $seed
        Set-Content -LiteralPath (Join-Path $seed 'demo\demo.nuspec') -Encoding Ascii -Value '<?xml version="1.0"?><package><metadata><id>demo</id><version>1.0.0</version></metadata></package>'
        Set-Content -LiteralPath (Join-Path $seed 'demo\update.ps1') -Encoding Ascii -Value 'Update-Package'
        Set-Content -LiteralPath (Join-Path $seed 'demo\tools\chocolateyinstall.ps1') -Encoding Ascii -Value '# test'
        Set-Content -LiteralPath (Join-Path $seed '.gitignore') -Encoding Ascii -Value '*.nupkg'
        $git = @('-c', 'user.name=test', '-c', 'user.email=test@example.invalid', '-c', 'core.autocrlf=false')
        & git init -q $seed
        & git -C $seed @git add -A
        & git -C $seed @git commit -q -m 'seed'
        $script:Remote = Join-Path $TestDrive 'ua-remote.git'
        & git clone -q --bare $seed $script:Remote
        $script:UaRepo = Join-Path $TestDrive 'ua-repo'

        function script:Reset-UaRepo {
            Remove-Item -LiteralPath $script:FakeLog -ErrorAction SilentlyContinue
            if (Test-Path -LiteralPath $script:UaRepo) {
                Clear-ReadOnlyAttribute $script:UaRepo
                Remove-Item -LiteralPath $script:UaRepo -Recurse -Force
            }
            & git clone -q $script:Remote $script:UaRepo
        }
        function script:Invoke-UpdateAll([string] $Arguments, [hashtable] $Extra = @{}, [string] $Script) {
            if (-not $Script) { $Script = Join-Path $script:UaRepo 'update_all.ps1' }
            $environment = Get-BaseEnvironment
            $environment.PSModulePath = "$modules;$env:PSModulePath"
            $environment.GIT_AUTHOR_NAME = 'test'; $environment.GIT_AUTHOR_EMAIL = 'test@example.invalid'
            $environment.GIT_COMMITTER_NAME = 'test'; $environment.GIT_COMMITTER_EMAIL = 'test@example.invalid'
            $environment.STUB_IN_FEED = '0'
            foreach ($key in $Extra.Keys) { $environment[$key] = $Extra[$key] }
            $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
            Invoke-TestProcess -FilePath $powershell -Arguments ('-NoProfile -ExecutionPolicy Bypass -File "{0}" {1}' -f $Script, $Arguments) `
                -WorkingDirectory $TestDrive -Environment $environment -TimeoutSeconds 180
        }
        function script:Get-DemoVersion {
            ([xml](Get-Content -LiteralPath (Join-Path $script:UaRepo 'demo\demo.nuspec') -Raw)).package.metadata.version
        }
    }
    AfterAll {
        Clear-ReadOnlyAttribute $TestDrive
    }

    It 'refuses a repository path with brackets instead of silently finding no package' {
        $bracket = Join-Path $TestDrive 'br[1]'
        New-Item -ItemType Directory -Path $bracket | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'update_all.ps1') -Destination $bracket
        $run = Invoke-UpdateAll -Arguments '-NoPush -NoGit' -Script (Join-Path $bracket 'update_all.ps1')
        $run.ExitCode | Should -Be 1
        "$($run.Output)$($run.Error)" | Should -Match 'corchetes'
    }

    It 'fails when there is no package at all' {
        $empty = Join-Path $TestDrive 'empty'
        New-Item -ItemType Directory -Path $empty | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'update_all.ps1') -Destination $empty
        $run = Invoke-UpdateAll -Arguments '-NoPush -NoGit' -Script (Join-Path $empty 'update_all.ps1')
        $run.ExitCode | Should -Be 1
        "$($run.Output)$($run.Error)" | Should -Match 'No se encontro ningun paquete'
    }

    It '-NoPush with a new version keeps the .nupkg, restores the files and says the next run publishes it' {
        Reset-UaRepo
        $run = Invoke-UpdateAll -Arguments '-NoPush' -Extra @{ STUB_REMOTE_VERSION = '1.1.0' }
        $run.ExitCode | Should -Be 0
        $run.Output | Should -Match 'STUB-AU'
        $run.Output | Should -Match 'la proxima ejecucion lo publicara'
        Get-DemoVersion | Should -Be '1.0.0'
        Join-Path $script:UaRepo 'demo\demo.1.1.0.nupkg' | Should -Exist
        @(Get-FakeLog $script:FakeLog | Where-Object { $_ -match '\[push\]' }).Count | Should -Be 0
    }

    It '-Force -NoPush without a new version does not promise a later publication' {
        Reset-UaRepo
        $run = Invoke-UpdateAll -Arguments '-Force -NoPush' -Extra @{ STUB_REMOTE_VERSION = '1.0.0' }
        $run.ExitCode | Should -Be 0
        $run.Output | Should -Match 'sin publicar'
        $run.Output | Should -Match 'una ejecucion normal no lo publicara'
        $run.Output | Should -Not -Match 'la proxima ejecucion lo publicara'
        Join-Path $script:UaRepo 'demo\demo.1.0.0.nupkg' | Should -Exist
    }

    It 'a failed push restores the files and exits with 1' {
        Reset-UaRepo
        $run = Invoke-UpdateAll -Arguments '-NoGit' -Extra @{ STUB_REMOTE_VERSION = '1.1.0'; FAKE_CHOCO_PUSH_EXIT = '1' }
        $run.ExitCode | Should -Be 1
        $run.Output | Should -Match 'Push fallido'
        Get-DemoVersion | Should -Be '1.0.0'
    }

    It 'records in Git a version already in the Chocolatey feed without pushing it again' {
        Reset-UaRepo
        $run = Invoke-UpdateAll -Arguments '' -Extra @{ STUB_REMOTE_VERSION = '1.1.0'; STUB_IN_FEED = '1' }
        $run.ExitCode | Should -Be 0
        $run.Output | Should -Match 'Registrado'
        @(Get-FakeLog $script:FakeLog | Where-Object { $_ -match '\[push\]' }).Count | Should -Be 0
        Get-DemoVersion | Should -Be '1.1.0'
        & git -C $script:Remote log -1 --format=%s | Should -Be 'chore: automated update of demo v1.1.0'
        & git -C $script:Remote show HEAD:demo/demo.nuspec | Should -Match '<version>1\.1\.0</version>'
        @(Get-ChildItem -LiteralPath (Join-Path $script:UaRepo 'demo') -Filter '*.nupkg').Count | Should -Be 0
    }

    It 'a version that is not in the feed yet is still pushed' {
        Reset-UaRepo
        $run = Invoke-UpdateAll -Arguments '-NoGit' -Extra @{ STUB_REMOTE_VERSION = '1.2.0' }
        $run.ExitCode | Should -Be 0
        $run.Output | Should -Match 'Actualizado'
        @(Get-FakeLog $script:FakeLog | Where-Object { $_ -match '\[push\] \[.*demo\.1\.2\.0\.nupkg\]' }).Count | Should -Be 1
    }
}
