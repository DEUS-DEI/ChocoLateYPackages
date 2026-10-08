# Pester 5 tests for vendor_catalog.ps1 and vendor_catalog.psd1 on Windows PowerShell 5.1. Nothing goes out to
# the network: the script runs from a copy in TestDrive with a small catalog of invented vendors, and every
# request (GitHub, Chocolatey, the vendors) is answered by a mock that fails on any address it does not know.
# The GitHub token is a fake one and the real "gh" is never called. See tests\README.md.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:CatalogScript = Join-Path $script:RepoRoot 'vendor_catalog.ps1'

    function script:Import-CatalogCode([string[]] $Function, [string[]] $Variable = @()) {
        # Defines here some functions of vendor_catalog.ps1, and the script variables they read, without
        # running the script
        $tokens = $null; $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:CatalogScript, [ref] $tokens, [ref] $errors)
        foreach ($statement in $ast.EndBlock.Statements) {
            if ($statement -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $Function -contains $statement.Name) {
                . ([scriptblock]::Create(($statement.Extent.Text -replace '^function ', 'function script:')))
            } elseif ($statement -is [System.Management.Automation.Language.AssignmentStatementAst] -and $Variable -contains $statement.Left.Extent.Text) {
                . ([scriptblock]::Create($statement.Extent.Text))
            }
        }
    }

    # A release and a repository as GitHub's GraphQL API returns them
    function script:Get-FakeRelease([string] $Tag, [string] $Date, [string[]] $Asset = @(), [bool] $Prerelease = $false) {
        [pscustomobject]@{
            tagName = $Tag; publishedAt = $Date; isPrerelease = $Prerelease
            releaseAssets = [pscustomobject]@{ nodes = @($Asset | ForEach-Object { [pscustomobject]@{ name = $_ } }) }
        }
    }
    function script:Get-FakeRepository([string] $Name, $Latest, [object[]] $Recent = @(), [bool] $Archived = $false) {
        [pscustomobject]@{
            nameWithOwner = $Name; isArchived = $Archived; latestRelease = $Latest
            releases = [pscustomobject]@{ nodes = @($Recent) }
        }
    }
}

Describe 'vendor_catalog.psd1' {
    BeforeAll {
        $script:Data = Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'vendor_catalog.psd1')
        # What each source needs to find the latest version
        $script:SourceFields = @{
            Mozilla = 'File', 'Key'; GitHub = @('Repo'); GitHubTag = 'Repo', 'TagPrefix'; Warp = @('Track')
            GitHubDesktop = @('Track'); Npm = @('Package'); Listing = 'Url', 'Pattern'; Chrome = @('Track')
            Json = 'Url', 'VersionPath'; Head = @()
        }
    }

    It 'lists every vendor once, with its GitHub owners and at least one product' {
        @($script:Data.Vendors | Sort-Object -Unique).Count | Should -Be $script:Data.Vendors.Count
        foreach ($vendor in $script:Data.Vendors) {
            @($script:Data.Owners[$vendor] | Where-Object { $_ }).Count | Should -BeGreaterThan 0 -Because "$vendor needs its entry in Owners"
            @($script:Data.Products | Where-Object { $_.Vendor -eq $vendor }).Count | Should -BeGreaterThan 0 -Because "$vendor has no product"
        }
        @($script:Data.Owners.Keys | Where-Object { $script:Data.Vendors -notcontains $_ }) | Should -BeNullOrEmpty
    }

    It 'gives every product a vendor, a name, a channel and a known source with its fields' {
        foreach ($product in $script:Data.Products) {
            $name = "$($product.Product) ($($product.Channel))"
            $product.Product | Should -Not -BeNullOrEmpty
            $product.Channel | Should -Not -BeNullOrEmpty -Because $name
            $script:Data.Vendors | Should -Contain $product.Vendor -Because $name
            $script:SourceFields.Keys | Should -Contain $product.Source -Because $name
            foreach ($field in $script:SourceFields[$product.Source]) {
                $product[$field] | Should -Not -BeNullOrEmpty -Because "$name needs $field"
            }
        }
    }

    It 'lists no product and channel twice' {
        @($script:Data.Products | Group-Object -Property { "$($_.Vendor) / $($_.Product) / $($_.Channel)" } |
            Where-Object Count -GT 1 | ForEach-Object Name) | Should -BeNullOrEmpty
    }

    It 'writes repositories as owner/name and Chocolatey IDs in lower case' {
        foreach ($product in $script:Data.Products) {
            if ($product.Repo) { $product.Repo | Should -Match '^[\w.-]+/[\w.-]+$' }
            if ($product.Choco) { $product.Choco | Should -MatchExactly '^[a-z0-9][a-z0-9.-]*$' }
        }
    }

    It 'only uses Status for a product that is descontinuado, and says why' {
        foreach ($product in $script:Data.Products | Where-Object { $_.ContainsKey('Status') }) {
            $product.Status | Should -BeExactly 'descontinuado' -Because $product.Product
            $product.Note | Should -Not -BeNullOrEmpty -Because $product.Product
        }
    }

    It 'gives every product that can be installed a name of its own and an https download' {
        $installable = @($script:Data.Products | Where-Object { $_.ContainsKey('Id') -or $_.ContainsKey('Installer') })
        $installable.Count | Should -BeGreaterThan 0
        @($installable | Group-Object -Property { $_.Id } | Where-Object Count -GT 1 | ForEach-Object Name) | Should -BeNullOrEmpty
        foreach ($product in $installable) {
            $name = "$($product.Product) ($($product.Channel))"
            $product.Id | Should -MatchExactly '^[a-z0-9][a-z0-9-]*$' -Because $name
            $installer = $product.Installer
            $installer | Should -BeOfType [hashtable] -Because "$name has an Id"
            @($installer.Keys | Where-Object { 'Url', 'Asset', 'Type', 'Arguments', 'Scope', 'Signer' -notcontains $_ }) | Should -BeNullOrEmpty -Because $name
            if ($installer.Url) { $installer.Url | Should -Match '^https://' -Because $name }
            if ($installer.Asset) {
                $product.Source | Should -BeExactly 'GitHub' -Because "$name takes a file of a GitHub release"
                { [regex] $installer.Asset } | Should -Not -Throw -Because $name
            }
            if (-not $installer.Url -and -not $installer.Asset) {
                # Then the source of the version has to point to the installer
                ($product.Source -in 'Warp', 'GitHubDesktop' -or ($product.Source -eq 'Json' -and $product.DownloadPath)) | Should -BeTrue -Because "$name has no Url and no Asset"
            }
            $installer.Signer | Should -Not -BeNullOrEmpty -Because "$name is only run when its vendor signed the installer"
            if ($installer.ContainsKey('Type')) { $installer.Type | Should -BeIn 'msi', 'exe' -Because $name }
            if ($installer.ContainsKey('Scope')) { $installer.Scope | Should -BeExactly 'user' -Because $name }
        }
    }

    It 'gives every Head source a download to look at' {
        foreach ($product in $script:Data.Products | Where-Object { $_.Source -eq 'Head' }) {
            "$($product.Url)$($product.Installer.Url)" | Should -Match '^https://' -Because $product.Product
        }
    }

    It 'has valid regular expressions in Ignore, and a version group in every Listing pattern' {
        foreach ($pattern in $script:Data.Ignore) { { [regex] $pattern } | Should -Not -Throw -Because $pattern }
        foreach ($product in $script:Data.Products | Where-Object { $_.Source -eq 'Listing' }) {
            ([regex] $product.Pattern).GetGroupNumbers().Count | Should -BeGreaterThan 1 -Because "$($product.Product): the first group is the version"
        }
    }
}

Describe 'vendor_catalog.ps1: is the Chocolatey package behind' {
    BeforeAll {
        Import-CatalogCode -Function 'ConvertTo-VersionPart', 'Test-UpToDate'
    }

    It '<Vendor> against the package <Chocolatey> gives "<Expected>"' -ForEach @(
        # Plain versions, however the tag is written
        @{ Vendor = 'v2.102.0'; Chocolatey = '2.102.0'; Expected = 'si' }
        @{ Vendor = 'codeql-bundle-v2.27.2'; Chocolatey = '2.27.2'; Expected = 'si' }
        @{ Vendor = '140.17.0esr'; Chocolatey = '140.17.0'; Expected = 'si' }
        @{ Vendor = '2026.8.2100.0'; Chocolatey = '2026.7.1376'; Expected = 'no' }
        @{ Vendor = 'v0.18.0'; Chocolatey = '0.17.0'; Expected = 'no' }
        @{ Vendor = '4.10'; Chocolatey = '4.2.1'; Expected = 'no' }
        # A fix version of the package is the same upstream version
        @{ Vendor = 'v2.0.0'; Chocolatey = '2.0.0.20260926'; Expected = 'si' }
        @{ Vendor = 'v2.0.1'; Chocolatey = '1.2.2.20251229'; Expected = 'no' }
        # The -pre that a package of pre-releases adds to the vendor's version
        @{ Vendor = '2026.8.2033.1'; Chocolatey = '2026.8.2033.1-pre'; Expected = 'si' }
        @{ Vendor = '2026.8.2050.1'; Chocolatey = '2026.8.2033.1-pre'; Expected = 'no' }
        # Mozilla's betas against the two ways of packaging them
        @{ Vendor = '158.0b5'; Chocolatey = '158.0.0-beta3'; Expected = 'no' }
        @{ Vendor = '158.0b5'; Chocolatey = '158.0.0-beta5'; Expected = 'si' }
        @{ Vendor = '158.0b5'; Chocolatey = '158.0-beta5'; Expected = 'si' }
        @{ Vendor = '158.0b5'; Chocolatey = '153.0.5-beta'; Expected = 'no' }
        # Labels with a number
        @{ Vendor = '3.6.7-beta3'; Chocolatey = '3.6.7-beta2'; Expected = 'no' }
        @{ Vendor = '3.6.7-beta3'; Chocolatey = '3.6.7-beta3'; Expected = 'si' }
        @{ Vendor = '3.6.8-beta1'; Chocolatey = '3.6.7-beta2'; Expected = 'no' }
        @{ Vendor = '3.0.0-rc.13'; Chocolatey = '3.0.0-rc13-20261004'; Expected = 'si' }
        @{ Vendor = '3.0.0-rc.14'; Chocolatey = '3.0.0-rc13-20261004'; Expected = 'no' }
        @{ Vendor = 'v0.2.0-rc1'; Chocolatey = '0.2.0'; Expected = 'si' }
        @{ Vendor = '159.0a1'; Chocolatey = '158.0.1.2026090110-alpha'; Expected = 'no' }
        # What cannot be ordered safely stays unmarked instead of risking a false "atrasado"
        @{ Vendor = '158.0b5'; Chocolatey = '158.0.4-beta'; Expected = '' }
        @{ Vendor = '159.0a1'; Chocolatey = '159.0.1.2026100709-alpha'; Expected = '' }
        @{ Vendor = '1.60.0'; Chocolatey = '1.60.0-beta0'; Expected = '' }
        @{ Vendor = '3.6.7-beta3'; Chocolatey = '3.6.7-rc1'; Expected = '' }
        @{ Vendor = 'neovim-nightlies'; Chocolatey = '1.0.0'; Expected = '' }
        @{ Vendor = '?'; Chocolatey = '1.0.0'; Expected = '' }
        @{ Vendor = ''; Chocolatey = '1.0.0'; Expected = '' }
        @{ Vendor = 'v1.0.0'; Chocolatey = ''; Expected = '' }
    ) {
        "$(Test-UpToDate -Vendor $Vendor -Chocolatey $Chocolatey)" | Should -BeExactly $Expected
    }
}

Describe 'vendor_catalog.ps1: which release and which downloads count' {
    BeforeAll {
        Import-CatalogCode -Function 'Get-Release', 'Get-WindowsAsset' -Variable '$script:WindowsAsset', '$script:NotSoftware'
    }

    It 'a download called <Name> is a program for Windows' -ForEach @(
        @{ Name = 'GitHubDesktopSetup-x64.exe' }, @{ Name = 'MozillaVPN-aarch64.msi' }, @{ Name = 'App_1.0_x64.msix' }
        @{ Name = 'codeql-win64.zip' }, @{ Name = 'tool-win32-x64.zip' }, @{ Name = 'actions-runner-win-x64-2.338.0.zip' }
        @{ Name = 'github-mcp-server_Windows_x86_64.zip' }, @{ Name = 'workerd-windows-64.gz' }
        @{ Name = 'grcov-aarch64-pc-windows-msvc.zip' }, @{ Name = 'tapfmt-win.tar.gz' }, @{ Name = 'logshare.windows.amd64.exe' }
    ) {
        Get-WindowsAsset -Release (Get-FakeRelease -Tag 'v1' -Date '2026-01-01T00:00:00Z' -Asset 'notes.txt', $Name) | Should -BeExactly $Name
    }

    It 'a download called <Name> is not' -ForEach @(
        @{ Name = 'tool-darwin-amd64.tar.gz' }, @{ Name = 'tool_1.0_Darwin_x86_64.tar.gz' }, @{ Name = 'tool-linux-amd64.tar.gz' }
        @{ Name = 'twine-1.0.tar.gz' }, @{ Name = 'pylib-1.0-cp310-cp310-win_amd64.whl' }
        @{ Name = 'addon-v1.0.0-napi-v3-win32-x64.tar.gz' }, @{ Name = 'sbom.windows-11.json' }
        @{ Name = 'setup.exe.sig' }, @{ Name = 'checksums-windows.txt' }, @{ Name = 'install-windows.ps1' }
    ) {
        Get-WindowsAsset -Release (Get-FakeRelease -Tag 'v1' -Date '2026-01-01T00:00:00Z' -Asset $Name) | Should -BeNullOrEmpty
    }

    It 'takes the stable release, and for a channel of pre-releases the newest pre-release' {
        $repository = Get-FakeRepository -Name 'o/r' -Latest (Get-FakeRelease -Tag '3.0.0' -Date '2027-01-10T18:00:00Z') -Recent @(
            (Get-FakeRelease -Tag '3.0.0' -Date '2027-01-10T18:00:00Z')
            (Get-FakeRelease -Tag '3.0.0-rc.14' -Date '2027-01-10T09:00:00Z' -Prerelease $true)
            (Get-FakeRelease -Tag '3.0.0-rc.13' -Date '2019-09-17T23:43:47Z' -Prerelease $true))
        (Get-Release -Repository $repository -Prerelease $false).tagName | Should -Be '3.0.0'
        (Get-Release -Repository $repository -Prerelease $true).tagName | Should -Be '3.0.0-rc.14'
    }

    It 'takes a pre-release for its tag even when GitHub does not mark it as one' {
        $repository = Get-FakeRepository -Name 'o/r' -Latest (Get-FakeRelease -Tag 'v2.0.0' -Date '2026-05-01T00:00:00Z') -Recent @(
            (Get-FakeRelease -Tag 'v2.0.0' -Date '2026-05-01T00:00:00Z'), (Get-FakeRelease -Tag '2.1.0-beta.1' -Date '2026-04-01T00:00:00Z'))
        (Get-Release -Repository $repository -Prerelease $true).tagName | Should -Be '2.1.0-beta.1'
    }

    It 'falls back to the stable release when a channel of pre-releases has none' {
        $repository = Get-FakeRepository -Name 'o/r' -Latest (Get-FakeRelease -Tag 'release-5.0.0' -Date '2027-01-10T00:00:00Z') -Recent @(
            (Get-FakeRelease -Tag 'release-5.0.0' -Date '2027-01-10T00:00:00Z'), (Get-FakeRelease -Tag 'release-4.9.0' -Date '2026-12-10T00:00:00Z'))
        (Get-Release -Repository $repository -Prerelease $true).tagName | Should -Be 'release-5.0.0'
    }

    It 'takes the newest release of a repository that only publishes pre-releases, and nothing when there is none' {
        $onlyPrereleases = Get-FakeRepository -Name 'o/r' -Latest $null -Recent @((Get-FakeRelease -Tag 'v1.63.0-nightly1' -Date '2022-04-13T00:00:00Z' -Prerelease $true))
        (Get-Release -Repository $onlyPrereleases -Prerelease $false).tagName | Should -Be 'v1.63.0-nightly1'
        Get-Release -Repository (Get-FakeRepository -Name 'o/empty' -Latest $null) -Prerelease $false | Should -BeNullOrEmpty
        Get-Release -Repository ([pscustomobject]@{ latestRelease = $null; releases = $null }) -Prerelease $true | Should -BeNullOrEmpty
    }
}

Describe 'vendor_catalog.ps1: versions and installers of the winget index' {
    BeforeAll {
        Import-CatalogCode -Function 'ConvertTo-SortKey', 'ConvertFrom-WingetManifest'
        $script:Hash = 'C' * 64
        function script:Get-Manifest([string[]] $Installer) {
            # A manifest with these installers, each "architecture" or "architecture/language"
            $lines = @('PackageIdentifier: Acme.Sample', 'InstallerType: wix', 'Installers:')
            foreach ($item in $Installer) {
                $architecture, $locale = $item -split '/'
                $lines += "- Architecture: $architecture"
                if ($locale) { $lines += "  InstallerLocale: $locale" }
                $lines += "  InstallerUrl: https://downloads.example.invalid/sample-$($item -replace '/', '-').msi", "  InstallerSha256: $script:Hash"
            }
            $lines -join "`n"
        }
    }

    It '<Older> is older than <Newer>' -ForEach @(
        @{ Older = '99.0.1'; Newer = '157.0.1' }, @{ Older = '1.9.0'; Newer = '1.10.0' }, @{ Older = '21.0.12.7'; Newer = '21.0.12.12' }
        @{ Older = '1.2.0-beta.1'; Newer = '1.2.0' }, @{ Older = '1.2.0-beta.1'; Newer = '1.2.0-beta.2' }, @{ Older = '1.2.0-rc.3'; Newer = '1.2.1-beta.1' }
        @{ Older = '158.0b5'; Newer = '158.0' }, @{ Older = '158.0b5'; Newer = '158.0b12' }, @{ Older = 'v1.0.78-3'; Newer = 'v1.0.93' }
        @{ Older = '1.2'; Newer = '1.2.1' }, @{ Older = '2026.2.1.7'; Newer = '2026.2.1.8' }
    ) {
        $sorted = @($Newer, $Older | Sort-Object { ConvertTo-SortKey -Version $_ })
        $sorted | Should -Be $Older, $Newer
        # And '1.2' is the same version as '1.2.0'
        (ConvertTo-SortKey -Version '1.2') | Should -BeExactly (ConvertTo-SortKey -Version '1.2.0')
    }

    It 'on <Bits>-bit Windows takes <Expected> of <Installers>' -ForEach @(
        @{ Bits = 64; Installers = 'arm64', 'x86', 'x64'; Expected = 'x64' }
        @{ Bits = 64; Installers = 'x86', 'neutral'; Expected = 'neutral' }
        @{ Bits = 64; Installers = 'arm64', 'x86'; Expected = 'x86' }
        @{ Bits = 32; Installers = 'x64', 'x86'; Expected = 'x86' }
        @{ Bits = 32; Installers = 'x64', 'neutral'; Expected = 'neutral' }
    ) {
        $spec = ConvertFrom-WingetManifest -Text (Get-Manifest -Installer $Installers) -Language 'es-MX' -Is64Bit ($Bits -eq 64)
        $spec.Url | Should -BeExactly "https://downloads.example.invalid/sample-$Expected.msi"
        $spec.Sha256 | Should -BeExactly $script:Hash
        $spec.Identifier | Should -BeExactly 'Acme.Sample'
    }

    It 'has no installer for <Bits>-bit Windows among <Installers>' -ForEach @(
        @{ Bits = 32; Installers = 'x64', 'arm64' }, @{ Bits = 64; Installers = 'arm64', 'arm' }
    ) {
        { ConvertFrom-WingetManifest -Text (Get-Manifest -Installer $Installers) -Language 'es-MX' -Is64Bit ($Bits -eq 64) } | Should -Throw '*arquitectura*'
    }

    It 'asked for <Language> takes the installer in "<Expected>" of <Installers>' -ForEach @(
        @{ Language = 'es-MX'; Installers = 'x64/en-US', 'x64/es-MX', 'x64/fr-FR'; Expected = 'es-MX' }
        @{ Language = 'es-MX'; Installers = 'x64/fr-FR', 'x64'; Expected = '' }
        @{ Language = 'es-MX'; Installers = 'x64/fr-FR', 'x64/en-US'; Expected = 'en-US' }
        # Nothing closer: another language, and the caller is told which
        @{ Language = 'es-MX'; Installers = 'x64/fr-FR', 'x64/de-DE'; Expected = 'fr-FR' }
        # The architecture counts more than the language
        @{ Language = 'es-MX'; Installers = 'x86/es-MX', 'x64/fr-FR'; Expected = 'fr-FR' }
    ) {
        (ConvertFrom-WingetManifest -Text (Get-Manifest -Installer $Installers) -Language $Language -Is64Bit $true).Locale | Should -BeExactly $Expected
    }

    It 'refuses a download at <Address>' -ForEach @(
        @{ Address = 'http://downloads.example.invalid/setup.msi' }, @{ Address = 'https://10.0.0.5/setup.msi' }, @{ Address = 'https://[::1]/setup.msi' }
        @{ Address = 'https://fileserver/setup.msi' }, @{ Address = 'https://build.corp/setup.msi' }, @{ Address = 'https://nas.local/setup.msi' }
        @{ Address = 'https://localhost/setup.msi' }, @{ Address = 'ftp://downloads.example.invalid/setup.msi' }, @{ Address = 'setup.msi' }
    ) {
        $manifest = "InstallerType: wix`nInstallers:`n- Architecture: x64`n  InstallerUrl: $Address`n  InstallerSha256: $script:Hash"
        { ConvertFrom-WingetManifest -Text $manifest -Language 'es-MX' -Is64Bit $true } | Should -Throw
    }
}

Describe 'vendor_catalog.ps1: the report' {
    BeforeAll {
        # --- A repository with the script, an invented catalog and packages of its own ---
        $script:Work = Join-Path $TestDrive 'catalog-repo'
        New-Item -ItemType Directory -Path $script:Work | Out-Null
        Copy-Item -LiteralPath $script:CatalogScript -Destination $script:Work
        Set-Content -LiteralPath (Join-Path $script:Work 'vendor_catalog.psd1') -Encoding Ascii -Value @'
@{
    Vendors  = @('Acme', 'Beta Works (Someone)')
    Owners   = @{ 'Acme' = @('acme'); 'Beta Works (Someone)' = @('betaworks') }
    Ignore   = @('^acme/ignored-tool$')
    Products = @(
        @{ Vendor = 'Acme'; Product = 'Browser'; Channel = 'estable'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_VERSION'; Choco = 'browser' }
        @{ Vendor = 'Acme'; Product = 'Browser Beta'; Channel = 'beta'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_DEVEDITION'; Choco = 'browser-beta'; Pre = $true }
        @{ Vendor = 'Acme'; Product = 'Tunnel'; Channel = 'estable'; Source = 'GitHub'; Repo = 'acme/tunnel'; Choco = 'tunnel' }
        @{ Vendor = 'Acme'; Product = 'Old Editor'; Channel = 'estable'; Source = 'GitHub'; Repo = 'acme/old-editor'; Choco = 'old-editor' }
        @{ Vendor = 'Acme'; Product = 'Dropped'; Channel = 'estable'; Source = 'GitHub'; Repo = 'acme/dropped'; Status = 'descontinuado'; Note = 'sustituido por Tunnel' }
        @{ Vendor = 'Acme'; Product = 'Stale Tool'; Channel = 'estable'; Source = 'GitHub'; Repo = 'acme/stale-tool' }
        @{ Vendor = 'Acme'; Product = 'Missing'; Channel = 'estable'; Source = 'GitHub'; Repo = 'acme/missing' }
        @{ Vendor = 'Acme'; Product = 'Client'; Channel = 'estable'; Source = 'Warp'; Track = 'ga'; Choco = 'client' }
        @{ Vendor = 'Acme'; Product = 'Client'; Channel = 'beta'; Source = 'Warp'; Track = 'beta'; Choco = 'client-pre'; Pre = $true }
        @{ Vendor = 'Acme'; Product = 'ctl'; Channel = 'estable'; Source = 'GitHubTag'; Repo = 'acme/sdk'; TagPrefix = 'v0.'; Choco = 'ctl' }
        @{ Vendor = 'Acme'; Product = 'Deployer'; Channel = 'estable'; Source = 'Npm'; Package = 'deployer' }
        @{ Vendor = 'Acme'; Product = 'Build Kit'; Channel = 'estable'; Source = 'Listing'; Url = 'https://downloads.example.invalid/kit/'; Pattern = 'KitSetup-(\d+(?:\.\d+)+)\.exe'; Choco = 'buildkit' }
        @{ Vendor = 'Acme'; Product = 'Desktop'; Channel = 'estable'; Source = 'GitHubDesktop'; Track = 'production'; Repo = 'acme/desktop'; Choco = 'desktop-app' }
        @{ Vendor = 'Beta Works (Someone)'; Product = 'Server'; Channel = 'estable'; Source = 'GitHub'; Repo = 'betaworks/server'; Choco = 'server' }
        @{ Vendor = 'Beta Works (Someone)'; Product = 'Server'; Channel = 'pre'; Source = 'GitHub'; Repo = 'betaworks/server'; Choco = 'server'; Pre = $true }
    )
}
'@
        foreach ($id in 'client-pre', 'server') {
            New-Item -ItemType Directory -Path (Join-Path $script:Work "Paquetes\actuales\$id") -Force | Out-Null
        }
        $bridges = [ordered]@{ 'client-beta' = 'client-pre'; 'server-beta' = 'server'; 'server-pre' = 'server' }
        foreach ($id in $bridges.Keys) {
            $folder = Join-Path $script:Work "Paquetes\descontinuados\$id"
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            $nuspec = '<?xml version="1.0"?><package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd"><metadata><id>{0}</id>' +
                '<version>999.0.1-deprecated</version><dependencies><dependency id="{1}" version="1.0.0" /></dependencies></metadata><files /></package>'
            Set-Content -LiteralPath (Join-Path $folder "$id.nuspec") -Encoding Ascii -Value ($nuspec -f $id, $bridges[$id])
        }

        # --- What the vendors, GitHub and Chocolatey answer ---
        # The mocks run inside the scopes of vendor_catalog.ps1, where $script: is that file's scope and not
        # this one's. They read this one object as plain $Fake, which PowerShell finds up the call stack.
        $script:Fake = @{}
        $recent = (Get-Date).ToUniversalTime().AddDays(-30)
        $script:RecentDay = $recent.ToString('yyyy-MM-dd')
        $recentDate = $recent.ToString('yyyy-MM-ddTHH:mm:ssZ')

        # The products of the catalog, asked by name
        $tunnel = Get-FakeRepository -Name 'acme/tunnel' -Latest (Get-FakeRelease -Tag 'v2.5.0' -Date $recentDate -Asset 'tunnel-windows-amd64.msi')
        $server = Get-FakeRepository -Name 'betaworks/server' -Latest (Get-FakeRelease -Tag 'v2.0.0' -Date '2014-04-08T13:27:54Z' -Asset 'server-windows-2.0.0.zip') -Recent @(
            (Get-FakeRelease -Tag '3.0.0-rc.13' -Date '2019-09-17T23:43:47Z' -Prerelease $true), (Get-FakeRelease -Tag 'v2.0.0' -Date '2014-04-08T13:27:54Z'))
        $desktop = Get-FakeRepository -Name 'acme/desktop' -Latest (Get-FakeRelease -Tag 'release-3.6.6' -Date $recentDate -Asset 'DesktopSetup-x64.exe')
        $script:Fake.Repositories = @{
            'acme/tunnel'      = $tunnel
            'acme/old-editor'  = Get-FakeRepository -Name 'acme/old-editor' -Latest (Get-FakeRelease -Tag 'v1.60.0' -Date '2022-03-08T00:00:00Z') -Archived $true
            'acme/dropped'     = Get-FakeRepository -Name 'acme/dropped' -Latest (Get-FakeRelease -Tag 'v2.14.2' -Date '2020-03-05T00:00:00Z')
            'acme/stale-tool'  = Get-FakeRepository -Name 'acme/stale-tool' -Latest (Get-FakeRelease -Tag 'v1.5.0' -Date '2019-11-16T00:00:00Z')
            'betaworks/server' = $server
        }
        # Every repository of each owner, page by page. Only cli-tool, legacy-app, gui and helper are new
        # programs for Windows: the others are in the catalog, ignored by it, or have nothing to install.
        $script:Fake.Owners = @{
            'acme'      = @(
                , @(
                    $tunnel, $desktop
                    (Get-FakeRepository -Name 'acme/ignored-tool' -Latest (Get-FakeRelease -Tag 'v1.0.0' -Date $recentDate -Asset 'ignored-tool.exe'))
                    (Get-FakeRepository -Name 'acme/cli-tool' -Latest (Get-FakeRelease -Tag 'v1.2.0' -Date $recentDate -Asset 'cli-tool_1.2.0_darwin_amd64.tar.gz', 'cli-tool_1.2.0_windows_amd64.zip'))
                    (Get-FakeRepository -Name 'acme/mac-only' -Latest (Get-FakeRelease -Tag 'v1.0.0' -Date $recentDate -Asset 'mac-only-darwin-amd64.tar.gz', 'mac-only-linux-amd64.tar.gz'))
                    (Get-FakeRepository -Name 'acme/pylib' -Latest (Get-FakeRelease -Tag 'v1.0.0' -Date $recentDate -Asset 'pylib-1.0-cp310-cp310-win_amd64.whl'))
                    (Get-FakeRepository -Name 'acme/addon' -Latest (Get-FakeRelease -Tag 'v1.0.0' -Date $recentDate -Asset 'addon-v1.0.0-napi-v3-win32-x64.tar.gz'))
                    (Get-FakeRepository -Name 'acme/no-release' -Latest $null)
                )
                , @(
                    (Get-FakeRepository -Name 'acme/legacy-app' -Latest (Get-FakeRelease -Tag 'v0.9.2' -Date '2018-04-19T00:00:00Z' -Asset 'legacy-setup.exe') -Archived $true)
                    (Get-FakeRepository -Name 'acme/gui' -Latest (Get-FakeRelease -Tag 'v0.0.2' -Date '2021-07-26T00:00:00Z' -Asset 'Gui_0.0.2_x64.msi'))
                )
            )
            'betaworks' = @(
                , @($server, (Get-FakeRepository -Name 'betaworks/helper' -Latest (Get-FakeRelease -Tag '1.0.1' -Date $recentDate -Asset 'helper-x86_64-pc-windows-msvc.zip')))
            )
        }
        # Listed versions of each Chocolatey ID: the stable one and the newest of any kind
        $script:Fake.Feed = @{
            'browser'      = @{ IsLatestVersion = '157.0.1'; IsAbsoluteLatestVersion = '157.0.1' }
            'browser-beta' = @{ IsAbsoluteLatestVersion = '158.0.0-beta3' }
            'tunnel'       = @{ IsLatestVersion = '2.4.0'; IsAbsoluteLatestVersion = '2.4.0' }
            'old-editor'   = @{ IsLatestVersion = '1.60.0'; IsAbsoluteLatestVersion = '1.61.0-beta0' }
            'client'       = @{ IsLatestVersion = '2026.7.1376'; IsAbsoluteLatestVersion = '2026.7.1376' }
            'client-pre'   = @{ IsAbsoluteLatestVersion = '2026.8.2033.1-pre' }
            'ctl'          = @{ IsLatestVersion = '0.119.0'; IsAbsoluteLatestVersion = '0.119.0' }
            'buildkit'     = @{ IsLatestVersion = '4.2.1'; IsAbsoluteLatestVersion = '4.2.1' }
            'server'       = @{ IsLatestVersion = '2.0.0.20260926'; IsAbsoluteLatestVersion = '3.0.0-rc13-20261004' }
            'cli-tool'     = @{ IsAbsoluteLatestVersion = '9.9.9' }
        }
        $script:Fake.GraphQLFailures = 0
        $script:Fake.Requests = New-Object System.Collections.Generic.List[object]

        Mock Start-Sleep { }

        Mock Invoke-RestMethod {
            $address = $Uri.OriginalString
            $request = [pscustomobject]@{ Uri = $address; Authorization = $(if ($Headers) { $Headers['Authorization'] }); Login = $null; Cursor = $null }
            $Fake.Requests.Add($request)
            if ($address -eq 'https://api.github.com/graphql') {
                if ($Fake.GraphQLFailures -gt 0) { $Fake.GraphQLFailures--; throw '502 Bad Gateway' }
                $query = [System.Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
                if ($query.query -match 'repositoryOwner') {
                    $request.Login = $query.variables.login
                    $request.Cursor = $query.variables.cursor
                    $pages = $Fake.Owners[$query.variables.login]
                    if (-not $pages) { return [pscustomobject]@{ data = [pscustomobject]@{ repositoryOwner = $null } } }
                    $index = if ($query.variables.cursor) { [int] $query.variables.cursor } else { 0 }
                    $pageInfo = [pscustomobject]@{ hasNextPage = ($index -lt $pages.Count - 1); endCursor = "$($index + 1)" }
                    $repositories = [pscustomobject]@{ pageInfo = $pageInfo; nodes = @($pages[$index]) }
                    return [pscustomobject]@{ data = [pscustomobject]@{ repositoryOwner = [pscustomobject]@{ repositories = $repositories } } }
                }
                # r0: repository(owner: "o", name: "n") { ... } r1: ...  A repository GitHub does not know is null
                $data = New-Object psobject
                foreach ($alias in [regex]::Matches($query.query, 'r(\d+): repository\(owner: "([^"]+)", name: "([^"]+)"\)')) {
                    $data | Add-Member -NotePropertyName "r$($alias.Groups[1].Value)" -NotePropertyValue $Fake.Repositories["$($alias.Groups[2].Value)/$($alias.Groups[3].Value)"]
                }
                return [pscustomobject]@{ data = $data }
            }
            switch ($address) {
                'https://product-details.mozilla.org/1.0/firefox_versions.json' {
                    return [pscustomobject]@{ LATEST_FIREFOX_VERSION = '157.0.1'; FIREFOX_DEVEDITION = '158.0b5' }
                }
                'https://downloads.cloudflareclient.com/v1/update/json/windows/ga' {
                    return [pscustomobject]@{ items = @(
                            [pscustomobject]@{ version = '2026.7.1376.0'; releaseDate = '2026-08-28T10:00:00.000Z' }
                            [pscustomobject]@{ version = '2026.8.2100.0'; releaseDate = '2026-10-07T10:00:00.000Z' }
                            [pscustomobject]@{ version = '2026.6.905.0'; releaseDate = '2026-07-01T10:00:00.000Z' }) }
                }
                'https://downloads.cloudflareclient.com/v1/update/json/windows/beta' {
                    return [pscustomobject]@{ items = @([pscustomobject]@{ version = '2026.8.2033.1'; releaseDate = '2026-09-30T02:01:09.224Z' }) }
                }
                'https://central.github.com/api/deployments/desktop/desktop/latest?env=production&os=windows&arch=x64' {
                    return [pscustomobject]@{ version = '3.6.6'; pub_date = '2026-09-15T18:23:45Z' }
                }
                'https://registry.npmjs.org/deployer/latest' {
                    return [pscustomobject]@{ name = 'deployer'; version = '4.148.0' }
                }
                'https://api.github.com/repos/acme/sdk/git/matching-refs/tags/v0.' {
                    # 0.119.0 is the highest as a version, not as text; a tag with a label is not a release of ctl
                    return 'v0.9.0', 'v0.119.0', 'v0.118.0', 'v0.120.0-beta', 'v0.20.1' | ForEach-Object { [pscustomobject]@{ ref = "refs/tags/$_" } }
                }
            }
            throw "Peticion no simulada: $address"
        }

        Mock Invoke-WebRequest {
            $address = $Uri.OriginalString
            $Fake.Requests.Add([pscustomobject]@{ Uri = $address; Authorization = $(if ($Headers) { $Headers['Authorization'] }); Login = $null; Cursor = $null })
            if ($address -eq 'https://downloads.example.invalid/kit/') {
                return [pscustomobject]@{ Content = '<a href="KitSetup-4.2.1.exe">KitSetup-4.2.1.exe</a> <a href="KitSetup-4.10.exe">KitSetup-4.10.exe</a> <a href="KitSetup-4.9.exe">KitSetup-4.9.exe</a>' }
            }
            # The only form of the query that the community feed answers: quotes as they are, tolower and one flag
            if ($address -match "^https://community\.chocolatey\.org/api/v2/Packages\(\)\?[$]filter=tolower\(Id\)%20eq%20'(?<id>[a-z0-9.-]+)'%20and%20(?<flag>IsLatestVersion|IsAbsoluteLatestVersion)$") {
                $version = if ($Fake.Feed.ContainsKey($Matches.id)) { $Fake.Feed[$Matches.id][$Matches.flag] }
                $entry = if ($version) { "<entry><title type=`"text`">$($Matches.id)</title><m:properties><d:Version>$version</d:Version></m:properties></entry>" }
                return [pscustomobject]@{ Content = '<?xml version="1.0" encoding="utf-8"?><feed xmlns:d="http://schemas.microsoft.com/ado/2007/08/dataservices" ' +
                    'xmlns:m="http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" xmlns="http://www.w3.org/2005/Atom"><title type="text">Packages</title>' + $entry + '</feed>' }
            }
            throw "Peticion no simulada: $address"
        }

        function script:Invoke-Catalog([hashtable] $Parameters = @{}) {
            # Runs the copy of the script and returns its rows, what it printed and the requests it made
            $script:Fake.Requests = New-Object System.Collections.Generic.List[object]
            $catalog = Join-Path $script:Work 'vendor_catalog.ps1'
            $output = @(& $catalog @Parameters 6>&1 3>&1)
            [pscustomobject]@{
                Rows     = @($output | Where-Object { $_ -isnot [System.Management.Automation.InformationRecord] -and $_ -isnot [System.Management.Automation.WarningRecord] })
                Text     = @($output | Where-Object { $_ -is [System.Management.Automation.InformationRecord] } | ForEach-Object { "$_" }) -join "`n"
                # ToArray and not @(): Windows PowerShell 5.1 fails to unwrap a List[T] made with New-Object
                # ("argument types do not match")
                Requests = $script:Fake.Requests.ToArray()
            }
        }
        function script:Get-Row($Run, [string] $Product, [string] $Channel = '') {
            @($Run.Rows | Where-Object { $_.Producto -eq $Product -and (-not $Channel -or $_.Canal -eq $Channel) })
        }
        function script:Get-FeedRequest($Run, [string] $Id) {
            # The flags asked to Chocolatey for an ID, in order
            @($Run.Requests | Where-Object { $_.Uri -like "*community.chocolatey.org*'$Id'*" } | ForEach-Object { $_.Uri -replace '^.*%20and%20' })
        }

        # A fake token: the real one of this machine or of the CI is never read
        $script:SavedTokens = @{ GITHUB_TOKEN = $env:GITHUB_TOKEN; GH_TOKEN = $env:GH_TOKEN }
        $env:GITHUB_TOKEN = 'test-token'
        $env:GH_TOKEN = $null
    }
    AfterAll {
        $env:GITHUB_TOKEN = $script:SavedTokens.GITHUB_TOKEN
        $env:GH_TOKEN = $script:SavedTokens.GH_TOKEN
    }
    BeforeEach {
        $script:Fake.GraphQLFailures = 0
    }

    Context 'a full run' {
        BeforeAll {
            $script:FilesBefore = @(Get-ChildItem -LiteralPath $script:Work -Recurse -File | ForEach-Object { "$($_.FullName) $((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)" })
            $script:Full = Invoke-Catalog -Parameters @{ PassThru = $true }
        }

        It 'returns a row per product and per repository found, vendors in catalog order and named products first' {
            $script:Full.Rows.Count | Should -Be 19
            @($script:Full.Rows[0].PSObject.Properties.Name) | Should -Be @(
                'Fabricante', 'Producto', 'Canal', 'Estado', 'Version', 'Fecha', 'Chocolatey', 'AlDia', 'EnRepo', 'Instalar', 'Nota', 'Origen', 'Fuente')
            @($script:Full.Rows | ForEach-Object { "$($_.Fabricante): $($_.Producto) $($_.Canal)".Trim() }) | Should -Be @(
                'Acme: Browser estable', 'Acme: Browser Beta beta', 'Acme: Build Kit estable', 'Acme: Client beta', 'Acme: Client estable'
                'Acme: ctl estable', 'Acme: Deployer estable', 'Acme: Desktop estable', 'Acme: Dropped estable', 'Acme: Missing estable'
                'Acme: Old Editor estable', 'Acme: Stale Tool estable', 'Acme: Tunnel estable'
                'Acme: acme/cli-tool', 'Acme: acme/gui', 'Acme: acme/legacy-app'
                'Beta Works (Someone): Server estable', 'Beta Works (Someone): Server pre', 'Beta Works (Someone): betaworks/helper')
            @($script:Full.Rows | Where-Object { $_.Producto -like '*/*' } | ForEach-Object Origen | Sort-Object -Unique) | Should -Be 'GitHub'
            @($script:Full.Rows | Where-Object { $_.Producto -notlike '*/*' } | ForEach-Object Origen | Sort-Object -Unique) | Should -Be 'catalogo'
        }

        It 'reads the latest version of <Product> (<Channel>) from <Source>' -ForEach @(
            @{ Product = 'Browser'; Channel = 'estable'; Version = '157.0.1'; Date = ''; Source = 'product-details.mozilla.org (LATEST_FIREFOX_VERSION)' }
            @{ Product = 'Browser Beta'; Channel = 'beta'; Version = '158.0b5'; Date = ''; Source = 'product-details.mozilla.org (FIREFOX_DEVEDITION)' }
            @{ Product = 'Client'; Channel = 'estable'; Version = '2026.8.2100.0'; Date = '2026-10-07'; Source = 'downloads.cloudflareclient.com (ga)' }
            @{ Product = 'Client'; Channel = 'beta'; Version = '2026.8.2033.1'; Date = '2026-09-30'; Source = 'downloads.cloudflareclient.com (beta)' }
            @{ Product = 'ctl'; Channel = 'estable'; Version = 'v0.119.0'; Date = ''; Source = 'github.com/acme/sdk (tags v0.*)' }
            @{ Product = 'Deployer'; Channel = 'estable'; Version = '4.148.0'; Date = ''; Source = 'registry.npmjs.org/deployer' }
            @{ Product = 'Build Kit'; Channel = 'estable'; Version = '4.10'; Date = ''; Source = 'https://downloads.example.invalid/kit/' }
            @{ Product = 'Desktop'; Channel = 'estable'; Version = '3.6.6'; Date = '2026-09-15'; Source = 'central.github.com (production)' }
            @{ Product = 'Server'; Channel = 'estable'; Version = 'v2.0.0'; Date = '2014-04-08'; Source = 'github.com/betaworks/server' }
            @{ Product = 'Server'; Channel = 'pre'; Version = '3.0.0-rc.13'; Date = '2019-09-17'; Source = 'github.com/betaworks/server' }
        ) {
            $row = @(Get-Row -Run $script:Full -Product $Product -Channel $Channel)
            $row.Count | Should -Be 1
            $row[0].Version | Should -BeExactly $Version
            $row[0].Fecha | Should -BeExactly $Date
            $row[0].Fuente | Should -BeExactly $Source
        }

        It 'takes the version and the date of a GitHub product from its latest release' {
            $row = Get-Row -Run $script:Full -Product 'Tunnel'
            $row[0].Version | Should -BeExactly 'v2.5.0'
            $row[0].Fecha | Should -BeExactly $script:RecentDay
            $row[0].Nota | Should -BeNullOrEmpty
        }

        It 'asks Mozilla for each file once and GitHub for all the products of the catalog in one request' {
            @($script:Full.Requests | Where-Object { $_.Uri -like 'https://product-details.mozilla.org/*' }).Count | Should -Be 1
            @($script:Full.Requests | Where-Object { $_.Uri -eq 'https://api.github.com/graphql' -and -not $_.Login }).Count | Should -Be 1
        }

        It 'compares <Product> (<Channel>) with its Chocolatey package: <Chocolatey>, up to date "<UpToDate>"' -ForEach @(
            @{ Product = 'Browser'; Channel = 'estable'; Chocolatey = 'browser 157.0.1'; UpToDate = 'si' }
            @{ Product = 'Browser Beta'; Channel = 'beta'; Chocolatey = 'browser-beta 158.0.0-beta3'; UpToDate = 'no' }
            @{ Product = 'Tunnel'; Channel = 'estable'; Chocolatey = 'tunnel 2.4.0'; UpToDate = 'no' }
            @{ Product = 'Old Editor'; Channel = 'estable'; Chocolatey = 'old-editor 1.60.0'; UpToDate = 'si' }
            @{ Product = 'Client'; Channel = 'estable'; Chocolatey = 'client 2026.7.1376'; UpToDate = 'no' }
            @{ Product = 'Client'; Channel = 'beta'; Chocolatey = 'client-pre 2026.8.2033.1-pre'; UpToDate = 'si' }
            @{ Product = 'ctl'; Channel = 'estable'; Chocolatey = 'ctl 0.119.0'; UpToDate = 'si' }
            @{ Product = 'Build Kit'; Channel = 'estable'; Chocolatey = 'buildkit 4.2.1'; UpToDate = 'no' }
            @{ Product = 'Server'; Channel = 'estable'; Chocolatey = 'server 2.0.0.20260926'; UpToDate = 'si' }
            @{ Product = 'Server'; Channel = 'pre'; Chocolatey = 'server 3.0.0-rc13-20261004'; UpToDate = 'si' }
            @{ Product = 'Desktop'; Channel = 'estable'; Chocolatey = 'desktop-app: sin version listada'; UpToDate = '' }
            @{ Product = 'Deployer'; Channel = 'estable'; Chocolatey = ''; UpToDate = '' }
        ) {
            $row = Get-Row -Run $script:Full -Product $Product -Channel $Channel
            $row[0].Chocolatey | Should -BeExactly $Chocolatey
            $row[0].AlDia | Should -BeExactly $UpToDate
        }

        It 'asks Chocolatey for the stable version first, and for the newest of any kind only when it has to' {
            Get-FeedRequest -Run $script:Full -Id 'browser' | Should -Be 'IsLatestVersion'
            Get-FeedRequest -Run $script:Full -Id 'desktop-app' | Should -Be 'IsLatestVersion', 'IsAbsoluteLatestVersion'
            Get-FeedRequest -Run $script:Full -Id 'browser-beta' | Should -Be 'IsAbsoluteLatestVersion'
            # The two channels of Server share the ID and want different versions
            Get-FeedRequest -Run $script:Full -Id 'server' | Should -Be 'IsLatestVersion', 'IsAbsoluteLatestVersion'
            # No ID in the catalog: nothing to ask
            @($script:Full.Requests | Where-Object { $_.Uri -like '*deployer*' -and $_.Uri -like '*chocolatey*' }) | Should -BeNullOrEmpty
        }

        It 'marks as descontinuado an archived repository and what the catalog says' {
            $archived = (Get-Row -Run $script:Full -Product 'Old Editor')[0]
            $archived.Estado | Should -BeExactly 'descontinuado'
            $archived.Nota | Should -BeExactly 'repositorio archivado'
            $declared = (Get-Row -Run $script:Full -Product 'Dropped')[0]
            $declared.Estado | Should -BeExactly 'descontinuado'
            $declared.Nota | Should -BeExactly 'sustituido por Tunnel; sin versiones desde 2020'
            @($script:Full.Rows | Where-Object { $_.Estado -eq 'descontinuado' } | ForEach-Object Producto) | Should -Be 'Dropped', 'Old Editor', 'acme/legacy-app'
            @($script:Full.Rows | ForEach-Object Estado | Sort-Object -Unique) | Should -Be 'actual', 'descontinuado'
        }

        It 'keeps as actual a product with no release for three years, with a note' {
            foreach ($case in @{ Product = 'Stale Tool'; Year = '2019' }, @{ Product = 'acme/gui'; Year = '2021' }, @{ Product = 'Server'; Year = '2014' }) {
                $row = (Get-Row -Run $script:Full -Product $case.Product)[0]
                $row.Estado | Should -BeExactly 'actual' -Because $case.Product
                $row.Nota | Should -BeExactly "sin versiones desde $($case.Year)" -Because $case.Product
            }
        }

        It 'keeps the row of a product whose repository GitHub does not find' {
            $row = (Get-Row -Run $script:Full -Product 'Missing')[0]
            $row.Version | Should -BeExactly '?'
            $row.Estado | Should -BeExactly 'actual'
            $row.Nota | Should -BeExactly 'no se pudo consultar: GitHub no encuentra el repositorio'
        }

        It 'tells which products this repository packages and which retired IDs they replace' {
            (Get-Row -Run $script:Full -Product 'Client' -Channel 'beta')[0].EnRepo | Should -BeExactly 'actual; sustituye a client-beta'
            (Get-Row -Run $script:Full -Product 'Server' -Channel 'estable')[0].EnRepo | Should -BeExactly 'actual; sustituye a server-beta, server-pre'
            (Get-Row -Run $script:Full -Product 'Server' -Channel 'pre')[0].EnRepo | Should -BeExactly 'actual; sustituye a server-beta, server-pre'
            @($script:Full.Rows | Where-Object { $_.EnRepo }).Count | Should -Be 3
        }

        It 'finds the other repositories with a program for Windows, page after page of every owner' {
            @($script:Full.Rows | Where-Object { $_.Origen -eq 'GitHub' } | ForEach-Object Producto) | Should -Be 'acme/cli-tool', 'acme/gui', 'acme/legacy-app', 'betaworks/helper'
            @($script:Full.Requests | Where-Object { $_.Login } | ForEach-Object { "$($_.Login) $($_.Cursor)".Trim() }) | Should -Be 'acme', 'acme 1', 'betaworks'
            $found = (Get-Row -Run $script:Full -Product 'acme/cli-tool')[0]
            $found.Version | Should -BeExactly 'v1.2.0'
            $found.Fecha | Should -BeExactly $script:RecentDay
            $found.Fuente | Should -BeExactly 'github.com/acme/cli-tool'
            $found.Canal | Should -BeNullOrEmpty
        }

        It 'only tries the name of a repository found as its Chocolatey ID, flags it as a guess and skips archived ones' {
            $guess = (Get-Row -Run $script:Full -Product 'acme/cli-tool')[0]
            $guess.Chocolatey | Should -BeExactly 'cli-tool 9.9.9 (?)'
            $guess.AlDia | Should -BeNullOrEmpty
            Get-FeedRequest -Run $script:Full -Id 'cli-tool' | Should -Be 'IsAbsoluteLatestVersion'
            (Get-Row -Run $script:Full -Product 'acme/gui')[0].Chocolatey | Should -BeNullOrEmpty
            Get-FeedRequest -Run $script:Full -Id 'gui' | Should -Be 'IsAbsoluteLatestVersion'
            $archived = (Get-Row -Run $script:Full -Product 'acme/legacy-app')[0]
            $archived.Nota | Should -BeExactly 'repositorio archivado'
            $archived.Chocolatey | Should -BeNullOrEmpty
            Get-FeedRequest -Run $script:Full -Id 'legacy-app' | Should -BeNullOrEmpty
        }

        It 'sends the GitHub token to api.github.com and nowhere else' {
            $withToken = @($script:Full.Requests | Where-Object { $_.Authorization })
            @($withToken | ForEach-Object { ([uri] $_.Uri).Host } | Sort-Object -Unique) | Should -Be 'api.github.com'
            @($withToken | ForEach-Object Authorization | Sort-Object -Unique) | Should -Be 'Bearer test-token'
            @($script:Full.Requests | Where-Object { $_.Uri -eq 'https://api.github.com/graphql' -and -not $_.Authorization }) | Should -BeNullOrEmpty
        }

        It 'writes nothing in the repository' {
            @(Get-ChildItem -LiteralPath $script:Work -Recurse -File | ForEach-Object { "$($_.FullName) $((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)" }) | Should -Be $script:FilesBefore
        }
    }

    Context 'the printed report' {
        It 'prints the two tables, the mark of the packages that are behind and the totals' {
            $run = Invoke-Catalog
            $run.Rows | Should -BeNullOrEmpty
            $run.Text | Should -Match '(?m)^  ACTUALES \(16\)$'
            $run.Text | Should -Match '(?m)^  DESCONTINUADOS \(3\)$'
            $run.Text | Should -Match '(?m)^Acme\s+Tunnel\s+estable\s+v2\.5\.0\s+\d{4}-\d{2}-\d{2}\s+tunnel 2\.4\.0 \(atrasado\)\s*$'
            $run.Text | Should -Match '(?m)^Acme\s+Deployer\s+estable\s+4\.148\.0\s+-\s*$'
            # The discontinued products come after the heading of their table
            $run.Text.IndexOf('Old Editor') | Should -BeGreaterThan $run.Text.IndexOf('DESCONTINUADOS (3)')
            [regex]::Match($run.Text, '(?m)^Acme\s+Tunnel').Index | Should -BeLessThan $run.Text.IndexOf('DESCONTINUADOS (3)')
            $run.Text | Should -Match ([regex]::Escape('Actuales: 16 (10 con paquete en Chocolatey, 4 de ellos atrasados; 3 en este repositorio). Descontinuados: 3.'))
        }

        It '-PassThru returns the rows instead of the tables' {
            $run = Invoke-Catalog -Parameters @{ PassThru = $true; NoDiscover = $true }
            $run.Rows.Count | Should -Be 15
            $run.Text | Should -Not -Match 'ACTUALES \('
            $run.Text | Should -Not -Match 'Actuales: '
        }

        It '-OutFile also writes the two tables as Markdown' {
            $report = Join-Path $TestDrive 'informe.md'
            $run = Invoke-Catalog -Parameters @{ OutFile = $report; NoDiscover = $true }
            $run.Text | Should -Match '(?m)^  ACTUALES \(13\)$'
            $lines = @(Get-Content -LiteralPath $report)
            $lines[0] | Should -BeExactly '# Catalogo de fabricantes'
            $current = [array]::IndexOf($lines, '## Actuales')
            $discontinued = [array]::IndexOf($lines, '## Descontinuados')
            $current | Should -BeGreaterThan 0
            $discontinued | Should -BeGreaterThan $current
            @($lines | Where-Object { $_ -eq '| Fabricante | Producto | Canal | Version | Fecha | Chocolatey | En este repo | Instalar | Nota |' }).Count | Should -Be 2
            $tunnel = [array]::IndexOf($lines, "| Acme | Tunnel | estable | v2.5.0 | $script:RecentDay | tunnel 2.4.0 (atrasado) |  |  |  |")
            $tunnel | Should -BeGreaterThan $current
            $tunnel | Should -BeLessThan $discontinued
            [array]::IndexOf($lines, '| Acme | Old Editor | estable | v1.60.0 | 2022-03-08 | old-editor 1.60.0 |  |  | repositorio archivado |') | Should -BeGreaterThan $discontinued
            [array]::IndexOf($lines, '| Acme | Deployer | estable | 4.148.0 |  | - |  |  |  |') | Should -BeGreaterThan $current
        }
    }

    Context 'parameters' {
        It '-Vendor takes the beginning of a name, in any case' {
            $run = Invoke-Catalog -Parameters @{ Vendor = 'beta'; PassThru = $true }
            @($run.Rows | ForEach-Object Fabricante | Sort-Object -Unique) | Should -Be 'Beta Works (Someone)'
            $run.Rows.Count | Should -Be 3
            @($run.Requests | Where-Object { $_.Login } | ForEach-Object Login) | Should -Be 'betaworks'
            @($run.Requests | Where-Object { $_.Uri -notlike 'https://api.github.com/*' -and $_.Uri -notlike 'https://community.chocolatey.org/*' }) | Should -BeNullOrEmpty
        }

        It '-Vendor takes several names in one string, as powershell -File passes them' {
            $run = Invoke-Catalog -Parameters @{ Vendor = 'beta, Acme'; PassThru = $true; NoDiscover = $true }
            @($run.Rows | ForEach-Object Fabricante | Sort-Object -Unique) | Should -Be 'Acme', 'Beta Works (Someone)'
            $run.Rows.Count | Should -Be 15
        }

        It 'fails for a vendor that is not in the catalog, before asking anything' {
            { Invoke-Catalog -Parameters @{ Vendor = 'Acme,Nobody' } } | Should -Throw '*desconocido*Nobody*Disponibles: Acme, Beta Works (Someone)*'
            $script:Fake.Requests.Count | Should -Be 0
        }

        It '-NoDiscover only reports the products of the catalog' {
            $run = Invoke-Catalog -Parameters @{ NoDiscover = $true; PassThru = $true }
            $run.Rows.Count | Should -Be 15
            @($run.Rows | ForEach-Object Origen | Sort-Object -Unique) | Should -Be 'catalogo'
            @($run.Requests | Where-Object { $_.Login }) | Should -BeNullOrEmpty
        }

        It 'without a GitHub token warns, leaves the GitHub products without a version and does not search' {
            # No token in the environment and no gh in the PATH: the script cannot get one
            $path = $env:PATH
            $env:GITHUB_TOKEN = $null
            $env:PATH = Join-Path $env:SystemRoot 'System32'
            try {
                Get-Command -Name gh -ErrorAction SilentlyContinue | Should -BeNullOrEmpty -Because 'this test must not reach the real GitHub CLI'
                $run = Invoke-Catalog -Parameters @{ PassThru = $true }
            } finally {
                $env:PATH = $path
                $env:GITHUB_TOKEN = 'test-token'
            }
            $run.Text | Should -Match '\[AVISO\] Sin token de GitHub'
            $run.Rows.Count | Should -Be 15
            $github = (Get-Row -Run $run -Product 'Tunnel')[0]
            $github.Version | Should -BeExactly '?'
            $github.Nota | Should -BeExactly 'no se pudo consultar: sin token de GitHub'
            $github.Chocolatey | Should -BeExactly 'tunnel 2.4.0'
            $github.AlDia | Should -BeNullOrEmpty
            # What the catalog itself says does not need GitHub
            (Get-Row -Run $run -Product 'Dropped')[0].Estado | Should -BeExactly 'descontinuado'
            # The other sources still answer, the tags of a repository included (public, no token)
            (Get-Row -Run $run -Product 'Browser')[0].Version | Should -BeExactly '157.0.1'
            (Get-Row -Run $run -Product 'ctl')[0].Version | Should -BeExactly 'v0.119.0'
            @($run.Requests | Where-Object { $_.Uri -eq 'https://api.github.com/graphql' }) | Should -BeNullOrEmpty
            @($run.Requests | Where-Object { $_.Authorization }) | Should -BeNullOrEmpty
        }

        It 'asks GitHub again when a request fails, up to three times' {
            $script:Fake.GraphQLFailures = 2
            $run = Invoke-Catalog -Parameters @{ Vendor = 'Beta'; NoDiscover = $true; PassThru = $true }
            (Get-Row -Run $run -Product 'Server' -Channel 'estable')[0].Version | Should -BeExactly 'v2.0.0'
            @($run.Requests | Where-Object { $_.Uri -eq 'https://api.github.com/graphql' }).Count | Should -Be 3
            Should -Invoke Start-Sleep -Times 2 -Exactly
        }

        It 'gives up when GitHub fails three times in a row, and only the GitHub products go without an answer' {
            $script:Fake.GraphQLFailures = 3
            $run = Invoke-Catalog -Parameters @{ NoDiscover = $true; PassThru = $true }
            @($run.Requests | Where-Object { $_.Uri -eq 'https://api.github.com/graphql' }).Count | Should -Be 3
            $run.Rows.Count | Should -Be 15
            $github = (Get-Row -Run $run -Product 'Tunnel')[0]
            $github.Version | Should -BeExactly '?'
            $github.Nota | Should -BeExactly 'no se pudo consultar: GitHub no responde (502 Bad Gateway)'
            (Get-Row -Run $run -Product 'Browser')[0].Version | Should -BeExactly '157.0.1'
            (Get-Row -Run $run -Product 'Client' -Channel 'estable')[0].Version | Should -BeExactly '2026.8.2100.0'
        }
    }
}

Describe 'vendor_catalog.ps1: installing from the vendor' {
    # Nothing is downloaded or run: Invoke-WebRequest writes an empty file, Get-AuthenticodeSignature answers
    # what each test says and Start-Process only records how it was called.
    BeforeAll {
        $script:InstallRepo = Join-Path $TestDrive 'install-repo'
        New-Item -ItemType Directory -Path $script:InstallRepo | Out-Null
        Copy-Item -LiteralPath $script:CatalogScript -Destination $script:InstallRepo
        Set-Content -LiteralPath (Join-Path $script:InstallRepo 'vendor_catalog.psd1') -Encoding Ascii -Value @'
@{
    Vendors  = @('Acme')
    Owners   = @{ 'Acme' = @('acme') }
    Winget   = @{ 'Acme' = @('Acme') }
    Ignore   = @()
    Products = @(
        @{ Vendor = 'Acme'; Product = 'Browser'; Channel = 'estable'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_VERSION'
            Id = 'browser'; Installer = @{ Url = 'https://downloads.example.invalid/?product=browser-latest&lang={lang}'; Arguments = '/S'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'Tunnel'; Channel = 'estable'; Source = 'GitHub'; Repo = 'acme/tunnel'
            Id = 'tunnel'; Installer = @{ Asset = '^tunnel-windows-amd64\.msi$'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'Client'; Channel = 'estable'; Source = 'Warp'; Track = 'ga'
            Id = 'client'; Installer = @{ Type = 'msi'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'Desktop'; Channel = 'beta'; Source = 'GitHubDesktop'; Track = 'beta'
            Id = 'desktop'; Installer = @{ Arguments = '-s'; Scope = 'user'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'Editor'; Channel = 'estable'; Source = 'Json'; Url = 'https://updates.example.invalid/editor.json'
            VersionPath = 'currentRelease'; DatePath = 'releases.0.updateTo.pub_date'; DownloadPath = 'releases.0.updateTo.url'
            Id = 'editor'; Installer = @{ Arguments = '/VERYSILENT /MERGETASKS=!runcode'; Scope = 'user'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'SDK'; Channel = 'estable'; Source = 'Json'; Url = 'https://sdk.example.invalid/dl/?mode=json'; VersionPath = '0.version'
            Id = 'sdk'; Installer = @{ Url = 'https://sdk.example.invalid/dl/{version}.windows-amd64.msi'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'Sync'; Channel = 'estable'; Source = 'Head'; Pattern = 'sync-(\d+(?:\.\d+)+)-windows'
            Id = 'sync'; Installer = @{ Url = 'https://downloads.example.invalid/sync/latest.msi'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'Plain'; Channel = 'estable'; Source = 'Npm'; Package = 'plain'
            Id = 'plain'; Installer = @{ Url = 'http://downloads.example.invalid/plain-setup.exe'; Signer = 'Acme Corporation' } }
        @{ Vendor = 'Acme'; Product = 'Loose'; Channel = 'estable'; Source = 'Npm'; Package = 'plain'
            Id = 'loose'; Installer = @{ Url = 'https://downloads.example.invalid/loose-setup.exe'; Arguments = '/S' } }
        @{ Vendor = 'Acme'; Product = 'Navigator'; Channel = 'estable'; Source = 'Chrome'; Track = 'stable' }
    )
}
'@
        # $Fake is read by the mocks from inside the scopes of the script (see the report tests)
        $script:Fake = @{}
        $recentDate = (Get-Date).ToUniversalTime().AddDays(-30).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $script:Fake.Repositories = @{
            'acme/tunnel' = Get-FakeRepository -Name 'acme/tunnel' -Latest (Get-FakeRelease -Tag 'v2.5.0' -Date $recentDate -Asset 'tunnel-windows-386.msi', 'tunnel-windows-amd64.msi', 'tunnel-darwin-amd64.tgz')
        }

        Mock Invoke-RestMethod {
            $address = $Uri.OriginalString
            $Fake.Requests.Add($address)
            if ($address -eq 'https://api.github.com/graphql') {
                $query = [System.Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
                if ($query.query -match 'repositoryOwner') {
                    # The search of the report finds no repository here; installing must never get this far
                    $Fake.Searches++
                    $empty = [pscustomobject]@{ pageInfo = [pscustomobject]@{ hasNextPage = $false; endCursor = $null }; nodes = @() }
                    return [pscustomobject]@{ data = [pscustomobject]@{ repositoryOwner = [pscustomobject]@{ repositories = $empty } } }
                }
                if ($query.query -match 'winget-pkgs') {
                    # p0: object(expression: "HEAD:manifests/a/Acme") { ... }  A folder that is not there is null
                    $repository = New-Object psobject
                    foreach ($alias in [regex]::Matches($query.query, 'p(\d+): object\(expression: "HEAD:([^"]+)"\)')) {
                        $folder = $alias.Groups[2].Value
                        $Fake.Folders.Add($folder)
                        $node = if ($Fake.Tree.ContainsKey($folder)) { [pscustomobject]@{ entries = @($Fake.Tree[$folder]) } }
                        $repository | Add-Member -NotePropertyName "p$($alias.Groups[1].Value)" -NotePropertyValue $node
                    }
                    return [pscustomobject]@{ data = [pscustomobject]@{ repository = $repository } }
                }
                if ($Fake.GraphQLFailures -gt 0) { $Fake.GraphQLFailures--; throw '502 Bad Gateway' }
                $data = New-Object psobject
                foreach ($alias in [regex]::Matches($query.query, 'r(\d+): repository\(owner: "([^"]+)", name: "([^"]+)"\)')) {
                    $data | Add-Member -NotePropertyName "r$($alias.Groups[1].Value)" -NotePropertyValue $Fake.Repositories["$($alias.Groups[2].Value)/$($alias.Groups[3].Value)"]
                }
                return [pscustomobject]@{ data = $data }
            }
            switch ($address) {
                'https://product-details.mozilla.org/1.0/firefox_versions.json' { return [pscustomobject]@{ LATEST_FIREFOX_VERSION = '157.0.1' } }
                'https://downloads.cloudflareclient.com/v1/update/json/windows/ga' {
                    return [pscustomobject]@{ items = @(
                            [pscustomobject]@{ version = '2026.7.1376.0'; releaseDate = '2026-08-28T10:00:00.000Z'; packageURL = 'https://downloads.cloudflareclient.com/v1/download/windows/version/2026.7.1376.0' }
                            [pscustomobject]@{ version = '2026.8.2100.0'; releaseDate = '2026-10-07T10:00:00.000Z'; packageURL = 'https://downloads.cloudflareclient.com/v1/download/windows/version/2026.8.2100.0' }) }
                }
                'https://central.github.com/api/deployments/desktop/desktop/latest?env=beta&os=windows&arch=x64' {
                    return [pscustomobject]@{ version = '3.6.7-beta3'; pub_date = '2026-10-07T15:39:08Z'; url = 'https://desktop.example.invalid/releases/3.6.7-beta3-809b4ec0/GitHubDesktop-x64.zip' }
                }
                'https://updates.example.invalid/editor.json' {
                    $update = [pscustomobject]@{ version = '1.2.37'; pub_date = '2026-10-05'; url = 'https://download.example.invalid/releases/1.2.37/editor-1.2.37-win32-x64.exe' }
                    return [pscustomobject]@{ currentRelease = '1.2.37'; releases = @([pscustomobject]@{ version = '1.2.37'; updateTo = $update }) }
                }
                'https://sdk.example.invalid/dl/?mode=json' {
                    # An array at the top, newest first
                    return [pscustomobject]@{ version = 'go1.27.1'; stable = $true }, [pscustomobject]@{ version = 'go1.26.8'; stable = $true }
                }
                'https://registry.npmjs.org/plain/latest' { return [pscustomobject]@{ version = '1.0.0' } }
                'https://versionhistory.googleapis.com/v1/chrome/platforms/win64/channels/stable/versions?pageSize=1&order_by=version%20desc' {
                    return [pscustomobject]@{ versions = @([pscustomobject]@{ name = 'chrome/platforms/win64/channels/stable/versions/156.0.8078.12'; version = '156.0.8078.12' }) }
                }
            }
            throw "Peticion no simulada: $address"
        }

        Mock Invoke-WebRequest {
            $address = $Uri.OriginalString
            $Fake.Requests.Add($address)
            if ("$Method" -eq 'Head') {
                if ($address -ne 'https://downloads.example.invalid/sync/latest.msi') { throw "Peticion no simulada: HEAD $address" }
                return [pscustomobject]@{
                    StatusCode = 200; Headers = @{ 'Last-Modified' = 'Thu, 01 Oct 2026 22:51:01 GMT' }
                    BaseResponse = [pscustomobject]@{ ResponseUri = [uri] 'https://downloads.example.invalid/sync/resources/4.2.0.1/sync-4.2.0.1-windows-x64.msi' }
                }
            }
            if (-not $OutFile -and $Fake.Manifests.ContainsKey($address)) {
                return [pscustomobject]@{ Content = $(if ($Fake.WrongHash) { $Fake.Manifests[$address].Replace($Fake.Hash, ('0' * 64)) } else { $Fake.Manifests[$address] }) }
            }
            if (-not $OutFile) { throw "Peticion no simulada: $address" }
            if ($Fake.Unreachable | Where-Object { $address -like $_ }) { throw 'No se puede resolver el nombre remoto' }
            if ($Fake.Missing | Where-Object { $address -like $_ }) {
                # As Invoke-WebRequest does: an exception that carries the answer of the server
                $notFound = New-Object CatalogTestHttpException 'Error en el servidor remoto: (404) No se encontro.'
                $notFound.Response = [pscustomobject]@{ StatusCode = 404 }
                throw $notFound
            }
            # A download: an empty file where the script asked for it
            Set-Content -LiteralPath $OutFile -Value 'not a real installer'
            $Fake.Downloads.Add([pscustomobject]@{ Uri = $address; File = $OutFile })
            # -PassThru: the answer says where the file really came from, after any redirection
            [pscustomobject]@{ StatusCode = 200; BaseResponse = [pscustomobject]@{ ResponseUri = [uri] $(if ($Fake.RedirectedTo) { $Fake.RedirectedTo } else { $address }) } }
        }

        Mock Start-Sleep { }

        if (-not ('CatalogTestHttpException' -as [type])) {
            Add-Type -TypeDefinition 'public class CatalogTestHttpException : System.Exception { public object Response { get; set; } public CatalogTestHttpException(string message) : base(message) { } }'
        }

        Mock Get-AuthenticodeSignature {
            $Fake.Checked.Add($LiteralPath)
            $certificate = [pscustomobject]@{ Name = $Fake.Publisher }
            $certificate | Add-Member -MemberType ScriptMethod -Name GetNameInfo -Value { $this.Name }
            [pscustomobject]@{ Status = $Fake.SignatureStatus; SignerCertificate = $certificate }
        }

        Mock Start-Process {
            $Fake.Started.Add([pscustomobject]@{
                    FilePath = $FilePath; Arguments = "$ArgumentList"; Verb = "$Verb"; Wait = [bool] $Wait
                    Existed  = (Test-Path -LiteralPath $(if ($FilePath -like '*msiexec.exe') { "$ArgumentList" -replace '^/i "([^"]+)".*$', '$1' } else { $FilePath }))
                })
            [pscustomobject]@{ ExitCode = $Fake.ExitCode }
        }

        function script:Invoke-Install([hashtable] $Parameters) {
            # Runs the copy of the script with -Install and returns its rows and what it printed
            foreach ($list in 'Requests', 'Downloads', 'Checked', 'Started', 'Folders') { $script:Fake[$list] = New-Object System.Collections.Generic.List[object] }
            $script:Fake.Searches = 0
            $catalog = Join-Path $script:InstallRepo 'vendor_catalog.ps1'
            $output = @(& $catalog @Parameters -PassThru 6>&1 3>&1)
            [pscustomobject]@{
                Rows = @($output | Where-Object { $_ -isnot [System.Management.Automation.InformationRecord] -and $_ -isnot [System.Management.Automation.WarningRecord] })
                Text = @($output | Where-Object { $_ -is [System.Management.Automation.InformationRecord] } | ForEach-Object { "$_" }) -join "`n"
            }
        }

        # Downloads go to the temporary folder of the tests, and the token is a fake one
        $script:Saved = @{ TEMP = $env:TEMP; TMP = $env:TMP; GITHUB_TOKEN = $env:GITHUB_TOKEN; GH_TOKEN = $env:GH_TOKEN }
        $script:Temp = Join-Path $TestDrive 'temp'
        New-Item -ItemType Directory -Path $script:Temp | Out-Null
        $env:TEMP = $script:Temp
        $env:TMP = $script:Temp
        $env:GITHUB_TOKEN = 'test-token'
        $env:GH_TOKEN = $null
        $script:Downloaded = Join-Path $script:Temp 'vendor_catalog'

        # An installer for all users asks for elevation unless the tests already run elevated (as on the CI)
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $elevated = (New-Object System.Security.Principal.WindowsPrincipal $identity).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        $script:MachineVerb = if ($elevated) { '' } else { 'RunAs' }
        $script:MsiExec = Join-Path $env:SystemRoot 'System32\msiexec.exe'

        # --- The winget community repository: folders (trees) and manifests (blobs) ---
        function script:Get-FakeEntry([string[]] $Tree = @(), [string[]] $Blob = @()) {
            @($Tree | ForEach-Object { [pscustomobject]@{ name = $_; type = 'tree' } }) + @($Blob | ForEach-Object { [pscustomobject]@{ name = $_; type = 'blob' } })
        }
        $root = 'manifests/a/Acme'
        $tree = @{
            $root                           = Get-FakeEntry -Tree 'Tool', 'Suite', 'Kit', 'Bundle', 'Portable', 'Old', 'Wrong', 'Inner' -Blob 'README.md'
            # Versions sort as numbers (1.10.0 is newer than 1.9.0) and a pre-release goes before its version
            # (1.10.0-rc.2 is older than 1.10.0); Beta is another package and es-MX a language
            "$root/Tool"                    = Get-FakeEntry -Tree '1.9.0', '1.10.0-rc.2', '1.10.0', 'Beta', 'es-MX'
            "$root/Old"                     = Get-FakeEntry -Tree '3.1', '3.0'
            "$root/Old/3.1"                 = Get-FakeEntry -Blob 'Acme.Old.yaml'
            "$root/Wrong"                   = Get-FakeEntry -Tree '1.0'
            "$root/Wrong/1.0"               = Get-FakeEntry -Blob 'Acme.Wrong.installer.yaml'
            "$root/Inner"                   = Get-FakeEntry -Tree '1.0'
            "$root/Inner/1.0"               = Get-FakeEntry -Blob 'Acme.Inner.installer.yaml'
            "$root/Tool/1.10.0"             = Get-FakeEntry -Blob 'Acme.Tool.installer.yaml', 'Acme.Tool.locale.en-US.yaml', 'Acme.Tool.yaml'
            "$root/Tool/Beta"               = Get-FakeEntry -Tree '1.11.0', 'EXE'
            "$root/Tool/Beta/1.11.0"        = Get-FakeEntry -Blob 'Acme.Tool.Beta.installer.yaml'
            "$root/Tool/Beta/EXE"           = Get-FakeEntry -Tree '1.11.0'
            "$root/Tool/Beta/EXE/1.11.0"    = Get-FakeEntry -Blob 'Acme.Tool.Beta.EXE.installer.yaml'
            # Numbered folders that are packages and not versions: what they hold is more folders
            "$root/Suite"                   = Get-FakeEntry -Tree '21', '25'
            "$root/Suite/21"                = Get-FakeEntry -Tree 'JDK'
            "$root/Suite/25"                = Get-FakeEntry -Tree 'JDK'
            "$root/Suite/21/JDK"            = Get-FakeEntry -Tree '21.0.12.7', '21.0.12.12'
            "$root/Suite/21/JDK/21.0.12.12" = Get-FakeEntry -Blob 'Acme.Suite.21.JDK.installer.yaml'
            "$root/Suite/25/JDK"            = Get-FakeEntry -Tree '25.0.4.10', '25.0.1.8'
            "$root/Suite/25/JDK/25.0.4.10"  = Get-FakeEntry -Blob 'Acme.Suite.25.JDK.installer.yaml'
            "$root/Kit"                     = Get-FakeEntry -Tree '0.9'
            "$root/Kit/0.9"                 = Get-FakeEntry -Blob 'Acme.Kit.installer.yaml'
            "$root/Bundle"                  = Get-FakeEntry -Tree '2.0'
            "$root/Bundle/2.0"              = Get-FakeEntry -Blob 'Acme.Bundle.installer.yaml'
            "$root/Portable"                = Get-FakeEntry -Tree '1.0'
            "$root/Portable/1.0"            = Get-FakeEntry -Blob 'Acme.Portable.installer.yaml'
        }
        # As on GitHub, the names of the folders are case-sensitive
        $script:Fake.Tree = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
        foreach ($folder in $tree.Keys) { $script:Fake.Tree[$folder] = $tree[$folder] }
        # The SHA256 of what the download mock writes, as the manifests of the index give it
        $sample = Join-Path $TestDrive 'sample-installer'
        Set-Content -LiteralPath $sample -Value 'not a real installer'
        $script:Fake.Hash = (Get-FileHash -LiteralPath $sample -Algorithm SHA256).Hash
        $raw = 'https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/a/Acme'
        $script:Fake.Manifests = @{
            # One installer per architecture, what is shared written once at the top
            "$raw/Tool/1.10.0/Acme.Tool.installer.yaml"          = @"
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.6.0.schema.json

PackageIdentifier: Acme.Tool
PackageVersion: 1.10.0
InstallerType: wix
Scope: machine
InstallerSwitches:
  InstallLocation: INSTALLDIR="<INSTALLPATH>"
  Custom: ADDLOCAL=ALL
AppsAndFeaturesEntries:
- ProductCode: '{DA6F3C20-298A-43EE-AA8D-6BABFC0458B0}'
Installers:
- Architecture: arm64
  InstallerUrl: https://downloads.example.invalid/tool/1.10.0/tool-arm64.msi
  InstallerSha256: $('A' * 64)
- Architecture: x86
  InstallerUrl: https://downloads.example.invalid/tool/1.10.0/tool-x86.msi
  InstallerSha256: $('B' * 64)
- Architecture: x64
  InstallerUrl: https://downloads.example.invalid/tool/1.10.0/tool-x64.msi
  InstallerSha256: $($script:Fake.Hash)
  ProductCode: '{DA6F3C20-298A-43EE-AA8D-6BABFC0458B0}'
ManifestType: installer
ManifestVersion: 1.6.0
"@
            # A setup program that needs its own switch, one per language
            "$raw/Tool/Beta/1.11.0/Acme.Tool.Beta.installer.yaml" = @"
PackageIdentifier: Acme.Tool.Beta
PackageVersion: 1.11.0
InstallerType: exe
InstallerSwitches:
  Silent: --silent
  SilentWithProgress: --passive
Installers:
- Architecture: x64
  InstallerLocale: en-US
  InstallerUrl: https://downloads.example.invalid/tool-beta/en-US/setup.exe
  InstallerSha256: $($script:Fake.Hash)
- Architecture: x64
  InstallerLocale: es-MX
  InstallerUrl: https://downloads.example.invalid/tool-beta/es-MX/setup.exe
  InstallerSha256: $($script:Fake.Hash)
ManifestType: installer
"@
            # Inno Setup, for the current user first; quoted values and a hash in lower case
            "$raw/Kit/0.9/Acme.Kit.installer.yaml"               = @"
PackageIdentifier: Acme.Kit
PackageVersion: '0.9'
InstallerType: inno
InstallerSwitches:
  Custom: '/mergetasks=!runcode'
Installers:
- Architecture: x64
  Scope: user
  InstallerUrl: "https://downloads.example.invalid/kit/kit-user-0.9.exe"
  InstallerSha256: $($script:Fake.Hash.ToLowerInvariant())
- Architecture: x64
  Scope: machine
  InstallerUrl: https://downloads.example.invalid/kit/kit-0.9.exe
  InstallerSha256: $($script:Fake.Hash)
ManifestType: installer
"@
            # A setup program and no word on how to run it silently
            "$raw/Bundle/2.0/Acme.Bundle.installer.yaml"         = @"
PackageIdentifier: Acme.Bundle
InstallerType: exe
Installers:
- Architecture: x64
  InstallerUrl: https://downloads.example.invalid/bundle/setup.exe
  InstallerSha256: $($script:Fake.Hash)
"@
            # The old layout: one file for everything, and the items of the list indented
            "$raw/Old/3.1/Acme.Old.yaml"                         = @"
PackageIdentifier: Acme.Old
PackageVersion: 3.1
InstallerType: nullsoft
Installers:
  - Architecture: x86
    InstallerUrl: https://downloads.example.invalid/old/old-3.1-x86.exe
    InstallerSha256: $($script:Fake.Hash)
  - Architecture: x64
    InstallerUrl: https://downloads.example.invalid/old/old-3.1-x64.exe
    InstallerSha256: $($script:Fake.Hash)
    InstallerSwitches:
      Custom: /NCRC
    AppsAndFeaturesEntries:
      - DisplayName: Acme Old
ManifestType: singleton
"@
            # A manifest that is of another package
            "$raw/Wrong/1.0/Acme.Wrong.installer.yaml"           = @"
PackageIdentifier: Acme.Other
InstallerType: wix
Installers:
- Architecture: x64
  InstallerUrl: https://downloads.example.invalid/other/other.msi
  InstallerSha256: $($script:Fake.Hash)
"@
            # A download that is not on the Internet
            "$raw/Inner/1.0/Acme.Inner.installer.yaml"           = @"
PackageIdentifier: Acme.Inner
InstallerType: wix
Installers:
- Architecture: x64
  InstallerUrl: https://10.0.0.5/inner.msi
  InstallerSha256: $($script:Fake.Hash)
"@
            # An archive with a program inside: winget's own business
            "$raw/Portable/1.0/Acme.Portable.installer.yaml"     = @"
PackageIdentifier: Acme.Portable
InstallerType: zip
NestedInstallerType: portable
NestedInstallerFiles:
- RelativeFilePath: portable.exe
Installers:
- Architecture: x64
  InstallerUrl: https://downloads.example.invalid/portable/portable-1.0.zip
  InstallerSha256: $($script:Fake.Hash)
"@
        }
    }
    AfterAll {
        foreach ($name in $script:Saved.Keys) { [Environment]::SetEnvironmentVariable($name, $script:Saved[$name], 'Process') }
    }
    BeforeEach {
        $script:Fake.Publisher = 'Acme Corporation'
        $script:Fake.SignatureStatus = 'Valid'
        $script:Fake.ExitCode = 0
        $script:Fake.Missing = @()
        $script:Fake.Unreachable = @()
        $script:Fake.RedirectedTo = ''
        $script:Fake.GraphQLFailures = 0
        $script:Fake.WrongHash = $false
    }

    It 'downloads the installer in the language asked, checks who signed it and runs it silently' {
        $run = Invoke-Install -Parameters @{ Install = 'browser'; Language = 'es-MX'; Yes = $true }
        $file = Join-Path $script:Downloaded 'browser.exe'
        $script:Fake.Downloads.Count | Should -Be 1
        $script:Fake.Downloads[0].Uri | Should -BeExactly 'https://downloads.example.invalid/?product=browser-latest&lang=es-MX'
        $script:Fake.Downloads[0].File | Should -BeExactly $file
        $script:Fake.Checked.ToArray() | Should -Be $file
        $script:Fake.Started.Count | Should -Be 1
        $script:Fake.Started[0].FilePath | Should -BeExactly $file
        $script:Fake.Started[0].Arguments | Should -BeExactly '/S'
        $script:Fake.Started[0].Verb | Should -BeExactly $script:MachineVerb
        $script:Fake.Started[0].Wait | Should -BeTrue
        $script:Fake.Started[0].Existed | Should -BeTrue -Because 'the installer must still be there while it runs'
        $run.Rows.Count | Should -Be 1
        $run.Rows[0].Id | Should -BeExactly 'browser'
        $run.Rows[0].Version | Should -BeExactly '157.0.1'
        $run.Rows[0].Resultado | Should -BeExactly 'instalado'
        $run.Text | Should -Match 'Firmado por: Acme Corporation'
        $file | Should -Not -Exist -Because 'the download is deleted after installing'
    }

    It 'falls back to the English installer when the vendor has none in that language' {
        $script:Fake.Missing = @('*lang=es-CO')
        $run = Invoke-Install -Parameters @{ Install = 'browser'; Language = 'es-CO'; Yes = $true }
        $run.Text | Should -Match '\[AVISO\] No hay instalador en es-CO'
        @($script:Fake.Downloads | ForEach-Object Uri) | Should -Be 'https://downloads.example.invalid/?product=browser-latest&lang=en-US'
        $run.Rows[0].Descarga | Should -BeExactly 'https://downloads.example.invalid/?product=browser-latest&lang=en-US'
        $run.Rows[0].Resultado | Should -BeExactly 'instalado'
    }

    It 'takes <Id> from <Url> and runs it as <Kind>' -ForEach @(
        @{ Id = 'tunnel'; Kind = 'msi'; PerUser = $false; Arguments = ''; Version = 'v2.5.0'; Url = 'https://github.com/acme/tunnel/releases/download/v2.5.0/tunnel-windows-amd64.msi' }
        @{ Id = 'client'; Kind = 'msi'; PerUser = $false; Arguments = ''; Version = '2026.8.2100.0'; Url = 'https://downloads.cloudflareclient.com/v1/download/windows/version/2026.8.2100.0' }
        @{ Id = 'sdk'; Kind = 'msi'; PerUser = $false; Arguments = ''; Version = 'go1.27.1'; Url = 'https://sdk.example.invalid/dl/go1.27.1.windows-amd64.msi' }
        @{ Id = 'sync'; Kind = 'msi'; PerUser = $false; Arguments = ''; Version = '4.2.0.1'; Url = 'https://downloads.example.invalid/sync/latest.msi' }
        @{ Id = 'desktop'; Kind = 'exe'; PerUser = $true; Arguments = '-s'; Version = '3.6.7-beta3'; Url = 'https://desktop.example.invalid/releases/3.6.7-beta3-809b4ec0/GitHubDesktopSetup-x64.exe' }
        @{ Id = 'editor'; Kind = 'exe'; PerUser = $true; Arguments = '/VERYSILENT /MERGETASKS=!runcode'; Version = '1.2.37'; Url = 'https://download.example.invalid/releases/1.2.37/editor-1.2.37-win32-x64.exe' }
    ) {
        $run = Invoke-Install -Parameters @{ Install = $Id; Yes = $true }
        $file = Join-Path $script:Downloaded "$Id.$Kind"
        $run.Rows[0].Resultado | Should -BeExactly 'instalado'
        $run.Rows[0].Version | Should -BeExactly $Version
        @($script:Fake.Downloads | ForEach-Object Uri) | Should -Be $Url
        $script:Fake.Downloads[0].File | Should -BeExactly $file
        $started = $script:Fake.Started[0]
        if ($Kind -eq 'msi') {
            $started.FilePath | Should -BeExactly $script:MsiExec
            $started.Arguments | Should -BeExactly "/i `"$file`" /qn /norestart"
        } else {
            $started.FilePath | Should -BeExactly $file
            $started.Arguments | Should -BeExactly $Arguments
        }
        # An installer for the current user never asks for elevation
        $started.Verb | Should -BeExactly $(if ($PerUser) { '' } else { $script:MachineVerb })
        $started.Existed | Should -BeTrue
    }

    It 'does not install a product of the catalog that names no signer, whoever signed the file' {
        { Invoke-Install -Parameters @{ Install = 'loose'; Yes = $true } } | Should -Throw '*No se pudo instalar: loose*'
        $script:Fake.Downloads.Count | Should -Be 0
        $script:Fake.Started.Count | Should -Be 0
    }

    It 'does not run an installer whose signature is <Status>' -ForEach @(@{ Status = 'NotSigned' }, @{ Status = 'HashMismatch' }, @{ Status = 'UnknownError' }) {
        $script:Fake.SignatureStatus = $Status
        { Invoke-Install -Parameters @{ Install = 'tunnel'; Yes = $true } } | Should -Throw '*No se pudo instalar: tunnel*'
        $script:Fake.Downloads.Count | Should -Be 1
        $script:Fake.Started.Count | Should -Be 0
        Join-Path $script:Downloaded 'tunnel.msi' | Should -Not -Exist
    }

    It 'does not run an installer signed by someone other than the publisher of the catalog' {
        $script:Fake.Publisher = 'Somebody Else LLC'
        $failure = $null
        try { Invoke-Install -Parameters @{ Install = 'browser,tunnel'; Language = 'en-US'; Yes = $true } } catch { $failure = $_ }
        "$failure" | Should -BeExactly 'No se pudo instalar: browser, tunnel'
        $script:Fake.Downloads.Count | Should -Be 2
        $script:Fake.Started.Count | Should -Be 0
        Join-Path $script:Downloaded 'browser.exe' | Should -Not -Exist
        Join-Path $script:Downloaded 'tunnel.msi' | Should -Not -Exist
    }

    It 'reports the exit code <Code> of the installer as "<Result>"' -ForEach @(
        @{ Code = 0; Result = 'instalado'; Fails = $false }
        @{ Code = 3010; Result = 'instalado (falta reiniciar Windows)'; Fails = $false }
        @{ Code = 1641; Result = 'instalado (Windows se esta reiniciando)'; Fails = $false }
        @{ Code = 1603; Result = 'error: el instalador termino con el codigo 1603'; Fails = $true }
    ) {
        $script:Fake.ExitCode = $Code
        $rows = @()
        $failure = $null
        try { $rows = (Invoke-Install -Parameters @{ Install = 'tunnel'; Yes = $true }).Rows } catch { $failure = $_ }
        if ($Fails) { "$failure" | Should -BeExactly 'No se pudo instalar: tunnel' } else { $rows[0].Resultado | Should -BeExactly $Result }
    }

    It '-WhatIf tells what would be installed and downloads nothing' {
        $run = Invoke-Install -Parameters @{ Install = 'browser,editor'; Language = 'es-MX'; WhatIf = $true; Yes = $true }
        $run.Rows.Count | Should -Be 2
        @($run.Rows | ForEach-Object Resultado | Sort-Object -Unique) | Should -Be 'simulado (-WhatIf)'
        $run.Rows[0].Descarga | Should -BeExactly 'https://downloads.example.invalid/?product=browser-latest&lang=es-MX'
        $run.Rows[1].Descarga | Should -BeExactly 'https://download.example.invalid/releases/1.2.37/editor-1.2.37-win32-x64.exe'
        $script:Fake.Downloads.Count | Should -Be 0
        $script:Fake.Started.Count | Should -Be 0
        @(Get-ChildItem -LiteralPath $script:Downloaded -ErrorAction SilentlyContinue).Count | Should -Be 0
    }

    It 'asks before installing unless -Yes is given: -Confirm:$false answers yes' {
        $run = Invoke-Install -Parameters @{ Install = 'tunnel'; Confirm = $false }
        $run.Rows[0].Resultado | Should -BeExactly 'instalado'
        $script:Fake.Started.Count | Should -Be 1
    }

    It 'installs each product once, in the order given, also when the names come in one string' {
        $run = Invoke-Install -Parameters @{ Install = 'tunnel, client ,tunnel'; Yes = $true }
        @($run.Rows | ForEach-Object Id) | Should -Be 'tunnel', 'client'
        $script:Fake.Started.Count | Should -Be 2
    }

    It 'refuses a product that is not in the catalog or has no installer, before asking anything' {
        { Invoke-Install -Parameters @{ Install = 'tunnel,navigator,nothing'; Yes = $true } } |
            Should -Throw '*Sin instalador en el catalogo: navigator, nothing. Se puede instalar: browser, client, desktop, editor, loose, plain, sdk, sync, tunnel*'
        $script:Fake.Requests.Count | Should -Be 0
    }

    It 'does not run a download that was redirected away from https' {
        $script:Fake.RedirectedTo = 'http://mirror.example.invalid/tunnel-windows-amd64.msi'
        $failure = $null
        try { Invoke-Install -Parameters @{ Install = 'tunnel'; Yes = $true } } catch { $failure = $_ }
        "$failure" | Should -BeExactly 'No se pudo instalar: tunnel'
        $script:Fake.Downloads.Count | Should -Be 1
        $script:Fake.Checked.Count | Should -Be 0 -Because 'a file that travelled in the open is not even looked at'
        $script:Fake.Started.Count | Should -Be 0
        Join-Path $script:Downloaded 'tunnel.msi' | Should -Not -Exist
    }

    It 'does not take a download refused for leaving https for a missing language' {
        $script:Fake.RedirectedTo = 'http://mirror.example.invalid/browser-setup.exe'
        $failure = $null
        $text = ''
        try { $text = (Invoke-Install -Parameters @{ Install = 'browser'; Language = 'es-MX'; Yes = $true }).Text } catch { $failure = $_ }
        "$failure" | Should -BeExactly 'No se pudo instalar: browser'
        @($script:Fake.Downloads | ForEach-Object Uri) | Should -Be 'https://downloads.example.invalid/?product=browser-latest&lang=es-MX'
        $text | Should -Not -Match 'No hay instalador en'
        $script:Fake.Started.Count | Should -Be 0
    }

    It 'does not take a network failure for a missing language' {
        $script:Fake.Unreachable = @('*lang=es-MX')
        $failure = $null
        $text = ''
        try { $text = (Invoke-Install -Parameters @{ Install = 'browser'; Language = 'es-MX'; Yes = $true }).Text } catch { $failure = $_ }
        "$failure" | Should -BeExactly 'No se pudo instalar: browser'
        $script:Fake.Downloads.Count | Should -Be 0
        $text | Should -Not -Match 'No hay instalador en'
        @($script:Fake.Requests | Where-Object { $_ -like '*lang=en-US' }) | Should -BeNullOrEmpty
    }

    It 'still installs the products of other vendors when GitHub does not answer' {
        $script:Fake.GraphQLFailures = 3
        $failure = $null
        try { Invoke-Install -Parameters @{ Install = 'tunnel,browser'; Language = 'en-US'; Yes = $true } } catch { $failure = $_ }
        "$failure" | Should -BeExactly 'No se pudo instalar: tunnel'
        @($script:Fake.Started | ForEach-Object FilePath) | Should -Be (Join-Path $script:Downloaded 'browser.exe')
    }

    It 'refuses a download that is not https' {
        { Invoke-Install -Parameters @{ Install = 'plain'; Yes = $true } } | Should -Throw '*No se pudo instalar: plain*'
        $script:Fake.Downloads.Count | Should -Be 0
        $script:Fake.Started.Count | Should -Be 0
    }

    It 'only asks the vendor of what it installs: no search on GitHub and nothing from Chocolatey' {
        Invoke-Install -Parameters @{ Install = 'editor'; Yes = $true } | Out-Null
        $script:Fake.Requests.ToArray() | Should -Be 'https://updates.example.invalid/editor.json', 'https://download.example.invalid/releases/1.2.37/editor-1.2.37-win32-x64.exe'
    }

    It 'the report names what can be installed and reads the sources that installers use' {
        foreach ($list in 'Requests', 'Downloads', 'Checked', 'Started') { $script:Fake[$list] = New-Object System.Collections.Generic.List[object] }
        $rows = @(& (Join-Path $script:InstallRepo 'vendor_catalog.ps1') -NoDiscover -PassThru 6>$null)
        $byProduct = @{}
        foreach ($row in $rows) { $byProduct[$row.Producto] = $row }
        @($rows | Where-Object { $_.Instalar } | ForEach-Object Instalar | Sort-Object) | Should -Be 'browser', 'client', 'desktop', 'editor', 'loose', 'plain', 'sdk', 'sync', 'tunnel'
        $byProduct['Navigator'].Instalar | Should -BeNullOrEmpty
        $byProduct['Navigator'].Version | Should -BeExactly '156.0.8078.12'
        $byProduct['Navigator'].Fuente | Should -BeExactly 'versionhistory.googleapis.com (stable)'
        $byProduct['Editor'].Version | Should -BeExactly '1.2.37'
        $byProduct['Editor'].Fecha | Should -BeExactly '2026-10-05'
        $byProduct['SDK'].Version | Should -BeExactly 'go1.27.1'
        # No version feed: the date of the "latest" download and the version in the name it redirects to
        $byProduct['Sync'].Version | Should -BeExactly '4.2.0.1'
        $byProduct['Sync'].Fecha | Should -BeExactly '2026-10-01'
        $byProduct['Sync'].Fuente | Should -BeExactly 'https://downloads.example.invalid/sync/latest.msi'
        $script:Fake.Downloads.Count | Should -Be 0
        $script:Fake.Started.Count | Should -Be 0
    }

    Context 'the winget index' {
        It 'lists everything the index has of the publishers of the vendor, each with its latest version' {
            foreach ($list in 'Requests', 'Downloads', 'Checked', 'Started', 'Folders') { $script:Fake[$list] = New-Object System.Collections.Generic.List[object] }
            $rows = @(& (Join-Path $script:InstallRepo 'vendor_catalog.ps1') -PassThru 6>$null | Where-Object { $_.Origen -eq 'winget' })
            @($rows | ForEach-Object { "$($_.Producto) $($_.Version)" }) | Should -Be @(
                'Acme.Bundle 2.0', 'Acme.Inner 1.0', 'Acme.Kit 0.9', 'Acme.Old 3.1', 'Acme.Portable 1.0', 'Acme.Suite.21.JDK 21.0.12.12'
                'Acme.Suite.25.JDK 25.0.4.10', 'Acme.Tool 1.10.0', 'Acme.Tool.Beta 1.11.0', 'Acme.Tool.Beta.EXE 1.11.0', 'Acme.Wrong 1.0')
            # The name to install it with is the one of the index, and it is the vendor's row
            @($rows | Where-Object { $_.Instalar -cne $_.Producto -or $_.Fabricante -ne 'Acme' -or $_.Estado -ne 'actual' }) | Should -BeNullOrEmpty
            $rows[7].Fuente | Should -BeExactly 'github.com/microsoft/winget-pkgs/tree/master/manifests/a/Acme/Tool/1.10.0'
            # A language (es-MX) is not a package, and no folder is asked for twice
            @($script:Fake.Folders | Where-Object { $_ -like '*es-MX*' }) | Should -BeNullOrEmpty
            @($script:Fake.Folders | Group-Object | Where-Object Count -GT 1) | Should -BeNullOrEmpty
        }

        It 'prints the index in a table of its own and writes it to the Markdown report' {
            $report = Join-Path $TestDrive 'indice.md'
            foreach ($list in 'Requests', 'Downloads', 'Checked', 'Started', 'Folders') { $script:Fake[$list] = New-Object System.Collections.Generic.List[object] }
            $output = @(& (Join-Path $script:InstallRepo 'vendor_catalog.ps1') -OutFile $report 6>&1 3>&1)
            $text = @($output | Where-Object { $_ -is [System.Management.Automation.InformationRecord] } | ForEach-Object { "$_" }) -join "`n"
            $text | Should -Match '(?m)^  INDICE DE WINGET \(11\)$'
            $text | Should -Match '(?m)^Acme\s+Acme\.Suite\.21\.JDK\s+21\.0\.12\.12\s*$'
            # The tables of the catalog do not count the rows of the index
            $text | Should -Match '(?m)^  ACTUALES \(10\)$'
            $lines = @(Get-Content -LiteralPath $report)
            $index = [array]::IndexOf($lines, '## Indice de winget')
            $index | Should -BeGreaterThan ([array]::IndexOf($lines, '## Descontinuados'))
            [array]::IndexOf($lines, '| Acme | Acme.Tool.Beta | 1.11.0 |') | Should -BeGreaterThan $index
        }

        It '-NoDiscover does not read the index' {
            $run = Invoke-Install -Parameters @{ NoDiscover = $true }
            @($run.Rows | Where-Object { $_.Origen -eq 'winget' }) | Should -BeNullOrEmpty
            $script:Fake.Folders.Count | Should -Be 0
        }

        It 'installs a package of the index from the address, with the SHA256 and the arguments of its manifest' {
            $run = Invoke-Install -Parameters @{ Install = 'Acme.Tool'; Yes = $true }
            $file = Join-Path $script:Downloaded 'Acme.Tool.msi'
            $run.Rows[0].Id | Should -BeExactly 'Acme.Tool'
            $run.Rows[0].Version | Should -BeExactly '1.10.0'
            $run.Rows[0].Resultado | Should -BeExactly 'instalado'
            # The installer for x64, not the first one of the manifest
            @($script:Fake.Downloads | ForEach-Object Uri) | Should -Be 'https://downloads.example.invalid/tool/1.10.0/tool-x64.msi'
            $script:Fake.Started[0].FilePath | Should -BeExactly $script:MsiExec
            $script:Fake.Started[0].Arguments | Should -BeExactly "/i `"$file`" /qn /norestart ADDLOCAL=ALL"
            $script:Fake.Started[0].Verb | Should -BeExactly $script:MachineVerb
            $run.Text | Should -Match 'SHA256 igual al del indice de winget'
            $run.Text | Should -Match 'Firmado por: Acme Corporation'
            $file | Should -Not -Exist
            # Only the folder of the package is read, not the whole index
            $script:Fake.Folders.ToArray() | Should -Be 'manifests/a/Acme/Tool', 'manifests/a/Acme/Tool/1.10.0'
            $script:Fake.Searches | Should -Be 0
        }

        It 'does not run a file whose SHA256 is not the one of the index' {
            $script:Fake.WrongHash = $true
            $failure = $null
            try { Invoke-Install -Parameters @{ Install = 'Acme.Tool'; Yes = $true } } catch { $failure = $_ }
            "$failure" | Should -BeExactly 'No se pudo instalar: Acme.Tool'
            $script:Fake.Downloads.Count | Should -Be 1
            $script:Fake.Checked.Count | Should -Be 0 -Because 'the hash is compared before the signature is even read'
            $script:Fake.Started.Count | Should -Be 0
            Join-Path $script:Downloaded 'Acme.Tool.msi' | Should -Not -Exist
        }

        It 'installs an unsigned package of the index once its SHA256 matches, and says so' {
            $script:Fake.SignatureStatus = 'NotSigned'
            $run = Invoke-Install -Parameters @{ Install = 'Acme.Tool'; Yes = $true }
            $run.Rows[0].Resultado | Should -BeExactly 'instalado'
            $run.Text | Should -Match '\[AVISO\] El instalador no lleva firma digital'
            $script:Fake.Started.Count | Should -Be 1
        }

        It 'does not run a package of the index whose signature is broken, even with the right SHA256' {
            $script:Fake.SignatureStatus = 'HashMismatch'
            { Invoke-Install -Parameters @{ Install = 'Acme.Tool'; Yes = $true } } | Should -Throw '*No se pudo instalar: Acme.Tool*'
            $script:Fake.Started.Count | Should -Be 0
        }

        It 'gives each kind of installer its silent arguments, and runs one for the current user without elevation' {
            $run = Invoke-Install -Parameters @{ Install = 'Acme.Kit'; Yes = $true }
            $run.Rows[0].Resultado | Should -BeExactly 'instalado'
            $run.Rows[0].Version | Should -BeExactly '0.9'
            @($script:Fake.Downloads | ForEach-Object Uri) | Should -Be 'https://downloads.example.invalid/kit/kit-user-0.9.exe'
            $script:Fake.Started[0].FilePath | Should -BeExactly (Join-Path $script:Downloaded 'Acme.Kit.exe')
            $script:Fake.Started[0].Arguments | Should -BeExactly '/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /mergetasks=!runcode'
            $script:Fake.Started[0].Verb | Should -BeExactly ''
        }

        It 'takes the installer in <Language> from <Url>' -ForEach @(
            @{ Language = 'es-MX'; Url = 'https://downloads.example.invalid/tool-beta/es-MX/setup.exe' }
            @{ Language = 'fr-FR'; Url = 'https://downloads.example.invalid/tool-beta/en-US/setup.exe' }
        ) {
            $run = Invoke-Install -Parameters @{ Install = 'Acme.Tool.Beta'; Language = $Language; Yes = $true }
            $run.Rows[0].Resultado | Should -BeExactly 'instalado'
            @($script:Fake.Downloads | ForEach-Object Uri) | Should -Be $Url
            $script:Fake.Started[0].Arguments | Should -BeExactly '--silent'
            # Told when it is not the language asked for
            if ($Language -eq 'fr-FR') { $run.Text | Should -Match '\[AVISO\] El indice no tiene este instalador en fr-FR: es el de en-US' }
            else { $run.Text | Should -Not -Match 'El indice no tiene este instalador' }
        }

        It 'reads a manifest in a single file, with the items of its list indented' {
            $run = Invoke-Install -Parameters @{ Install = 'Acme.Old'; Yes = $true }
            $run.Rows[0].Resultado | Should -BeExactly 'instalado'
            $run.Rows[0].Version | Should -BeExactly '3.1'
            @($script:Fake.Downloads | ForEach-Object Uri) | Should -Be 'https://downloads.example.invalid/old/old-3.1-x64.exe'
            $script:Fake.Started[0].Arguments | Should -BeExactly '/S /NCRC'
        }

        It 'does not download <Id>: <Why>' -ForEach @(
            @{ Id = 'Acme.Bundle'; Why = 'a setup program whose manifest does not say how to run it silently' }
            @{ Id = 'Acme.Portable'; Why = 'an archive, which winget installs itself' }
            @{ Id = 'Acme.Suite'; Why = 'a folder of packages, not a package' }
            @{ Id = 'Acme.Missing'; Why = 'not in the index' }
            @{ Id = 'Acme.Wrong'; Why = 'its manifest is of another package' }
            @{ Id = 'Acme.Inner'; Why = 'its manifest points to an address that is not public' }
            @{ Id = 'acme.tool'; Why = 'the names of the index are case-sensitive' }
        ) {
            { Invoke-Install -Parameters @{ Install = $Id; Yes = $true } } | Should -Throw "*No se pudo instalar: $Id*"
            $script:Fake.Downloads.Count | Should -Be 0
            $script:Fake.Started.Count | Should -Be 0
        }

        It 'refuses a package of a publisher that is not in the catalog, before asking anything' {
            { Invoke-Install -Parameters @{ Install = 'Acme.Tool,Other.Thing'; Yes = $true } } |
                Should -Throw '*Sin instalador en el catalogo: Other.Thing.*del indice de winget, lo de Acme*'
            $script:Fake.Requests.Count | Should -Be 0
        }

        It '-WhatIf reads the manifest and downloads nothing' {
            $run = Invoke-Install -Parameters @{ Install = 'Acme.Kit'; WhatIf = $true }
            $run.Rows[0].Resultado | Should -BeExactly 'simulado (-WhatIf)'
            $run.Rows[0].Descarga | Should -BeExactly 'https://downloads.example.invalid/kit/kit-user-0.9.exe'
            $script:Fake.Downloads.Count | Should -Be 0
        }
    }
}
