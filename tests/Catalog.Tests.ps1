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
            GitHubDesktop = @('Track'); Npm = @('Package'); Listing = 'Url', 'Pattern'
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
            $script:FilesBefore = @(Get-ChildItem -LiteralPath $script:Work -Recurse -File | ForEach-Object { "$($_.FullName) $($_.Length)" })
            $script:Full = Invoke-Catalog -Parameters @{ PassThru = $true }
        }

        It 'returns a row per product and per repository found, vendors in catalog order and named products first' {
            $script:Full.Rows.Count | Should -Be 19
            @($script:Full.Rows[0].PSObject.Properties.Name) | Should -Be @(
                'Fabricante', 'Producto', 'Canal', 'Estado', 'Version', 'Fecha', 'Chocolatey', 'AlDia', 'EnRepo', 'Nota', 'Origen', 'Fuente')
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
            @(Get-ChildItem -LiteralPath $script:Work -Recurse -File | ForEach-Object { "$($_.FullName) $($_.Length)" }) | Should -Be $script:FilesBefore
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
            @($lines | Where-Object { $_ -eq '| Fabricante | Producto | Canal | Version | Fecha | Chocolatey | En este repo | Nota |' }).Count | Should -Be 2
            $tunnel = [array]::IndexOf($lines, "| Acme | Tunnel | estable | v2.5.0 | $script:RecentDay | tunnel 2.4.0 (atrasado) |  |  |")
            $tunnel | Should -BeGreaterThan $current
            $tunnel | Should -BeLessThan $discontinued
            [array]::IndexOf($lines, '| Acme | Old Editor | estable | v1.60.0 | 2022-03-08 | old-editor 1.60.0 |  | repositorio archivado |') | Should -BeGreaterThan $discontinued
            [array]::IndexOf($lines, '| Acme | Deployer | estable | 4.148.0 |  | - |  |  |') | Should -BeGreaterThan $current
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

        It 'gives up when GitHub fails three times in a row' {
            $script:Fake.GraphQLFailures = 3
            { Invoke-Catalog -Parameters @{ Vendor = 'Beta'; NoDiscover = $true; PassThru = $true } } | Should -Throw '*502*'
            @($script:Fake.Requests | Where-Object { $_.Uri -eq 'https://api.github.com/graphql' }).Count | Should -Be 3
        }
    }
}
