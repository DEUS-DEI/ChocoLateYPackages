<#
.SYNOPSIS
    Lists the Windows software that the vendors of vendor_catalog.psd1 publish today (Mozilla, Cloudflare,
    GitHub, Google, Amazon, Cursor and the author of Fenix) and installs it from the vendor, without Chocolatey.

.DESCRIPTION
    Without -Install the script only reports: nothing is installed, packed, pushed or written to the repository.

    With -Install it downloads the official installer of each product named, straight from the vendor (https
    only), checks that Windows trusts its digital signature and that the publisher is the one the catalog
    expects, and runs it silently. It asks before each product (-Yes skips the question, -WhatIf only shows
    what would be done). Chocolatey takes no part in it.

    The products of the report come from two places:
      - vendor_catalog.psd1: the products with a name, a channel and, when there is one, the ID of their
        package in the Chocolatey community repository.
      - GitHub (unless -NoDiscover): every other repository of the vendors' organizations whose latest
        release has a download for Windows.

    For each product the script asks the vendor for the latest version, asks Chocolatey for the version of
    its package and tells whether this repository packages it (Paquetes\actuales, Paquetes\descontinuados).
    A product is "descontinuado" when its repository is archived or the catalog says so; everything else is
    "actual", with a note when it has had no release for three years.

    GitHub is read through its GraphQL API, which needs a token: the GITHUB_TOKEN (or GH_TOKEN) variable, or
    the session of the GitHub CLI (gh auth login). Without a token the GitHub products are left without a
    version and the other repositories are not searched.

.PARAMETER Vendor
    Only these vendors (comma separated; the beginning of the name is enough: Mozilla, Cloudflare, GitHub,
    Fenix). Default: all of them.

.PARAMETER NoDiscover
    Only the products of vendor_catalog.psd1: do not search the vendors' other repositories (much faster).

.PARAMETER OutFile
    Also write the report to this file as Markdown.

.PARAMETER PassThru
    Return the rows as objects (for Export-Csv, ConvertTo-Json, Where-Object...) instead of printing tables.

.PARAMETER Install
    Install these products (comma separated): the names of the "Instalar" column of the report, such as
    firefox, chrome, kiro, cursor, gh or aws-cli. The parameters of the report (-Vendor, -NoDiscover, -OutFile)
    play no part: a product is installed whoever its vendor is.

.PARAMETER Language
    Language of the installers that come in several (Firefox, Thunderbird). Default: the display language of
    Windows; English when the vendor has no installer in that language.

.PARAMETER Yes
    With -Install: do not ask before each product.

.EXAMPLE
    .\vendor_catalog.ps1

.EXAMPLE
    .\vendor_catalog.ps1 -Vendor Cloudflare,GitHub -NoDiscover

.EXAMPLE
    .\vendor_catalog.ps1 -PassThru | Where-Object { $_.Estado -eq 'actual' -and -not $_.Chocolatey } | Format-Table

.EXAMPLE
    .\vendor_catalog.ps1 -Install firefox,kiro -WhatIf

.EXAMPLE
    .\vendor_catalog.ps1 -Install chrome,gh -Yes
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string[]] $Vendor,
    [switch] $NoDiscover,
    [string] $OutFile,
    [switch] $PassThru,
    [string[]] $Install,
    [string] $Language,
    [switch] $Yes
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'  # Windows PowerShell downloads are much slower with the progress bar
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Fields asked of a repository: its newest stable release with its files. Counting or sorting the releases of
# every repository of an organization is too much for GitHub (502), so the latest releases of any kind (where
# the newest pre-release is) are only asked for the products of the catalog.
$script:RepositoryFields = 'nameWithOwner isArchived latestRelease { tagName publishedAt releaseAssets(first: 60) { nodes { name } } }'
$script:RecentReleases = 'releases(first: 15, orderBy: {field: CREATED_AT, direction: DESC}) { nodes { tagName publishedAt isPrerelease } }'
# A download for Windows: an installer, or "win", "windows", "win32", "win64" as a word of the file name
# ("darwin" is not one). Signatures, manifests and libraries built for other programs are not software.
$script:WindowsAsset = '(\.(exe|msi|msix|appx)$)|((^|[^a-z])win(dows)?(32|64)?([^a-z]|$))|pc-windows'
$script:NotSoftware = '\.(whl|json|txt|sig|asc|pem|sha256|sha512|sbom|ps1)$|-napi-'
$script:GitHubHeaders = @{ 'User-Agent' = 'ChocoLateYPackages-vendor-catalog' }
$script:GitHubFailure = ''
$script:MozillaFiles = @{}
$script:ChocolateyVersions = @{}

function Get-GitHubToken {
    # The token is only sent to api.github.com and never printed
    if ($env:GITHUB_TOKEN) { return $env:GITHUB_TOKEN }
    if ($env:GH_TOKEN) { return $env:GH_TOKEN }
    if (Get-Command -Name gh -ErrorAction SilentlyContinue) {
        # With 'Stop', Windows PowerShell can turn what gh writes to stderr into a terminating error
        $ErrorActionPreference = 'Continue'
        $token = & gh auth token 2>$null
        if ($LASTEXITCODE -eq 0 -and $token) { return "$token".Trim() }
    }
}

function Invoke-GitHubQuery([string] $Query, [hashtable] $Variables = @{}) {
    $body = ConvertTo-Json -InputObject @{ query = $Query; variables = $Variables } -Depth 4 -Compress
    $response = $null
    foreach ($attempt in 1..3) {
        try {
            $response = Invoke-RestMethod -Uri 'https://api.github.com/graphql' -Method Post -Headers $script:GitHubHeaders `
                -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($body))
            break
        } catch {
            # GitHub answers 502 now and then to a query that works a moment later
            if ($attempt -eq 3) { throw }
            Start-Sleep -Seconds 3
        }
    }
    # A repository that does not exist comes back as an error next to the data of the others
    if (-not $response.data) { throw "GitHub: $(@($response.errors | ForEach-Object { $_.message }) -join '; ')" }
    $response.data
}

function Get-GitHubRepository([string[]] $Name) {
    # The products of the catalog, 40 per request: r0: repository(owner: "o", name: "n") { ... } r1: ...
    $found = @{}
    for ($start = 0; $start -lt $Name.Count; $start += 40) {
        $batch = @($Name[$start..([Math]::Min($start + 39, $Name.Count - 1))])
        $parts = for ($i = 0; $i -lt $batch.Count; $i++) {
            if ($batch[$i] -notmatch '^[\w.-]+/[\w.-]+$') { throw "Repositorio no valido en vendor_catalog.psd1: '$($batch[$i])'" }
            $owner, $repository = $batch[$i] -split '/', 2
            'r{0}: repository(owner: "{1}", name: "{2}") {{ {3} {4} }}' -f $i, $owner, $repository, $script:RepositoryFields, $script:RecentReleases
        }
        $data = Invoke-GitHubQuery -Query ("query {`n" + ($parts -join "`n") + "`n}")
        for ($i = 0; $i -lt $batch.Count; $i++) { $found[$batch[$i]] = $data."r$i" }
    }
    $found
}

function Get-CatalogRepository([string[]] $Name) {
    # The repositories of the products of the catalog. When GitHub fails only those products are left without
    # an answer: the ones of other sources do not depend on it.
    try {
        Get-GitHubRepository -Name $Name
    } catch {
        $script:GitHubFailure = "GitHub no responde ($($_.Exception.Message))"
        @{}
    }
}

function Find-GitHubRepository([string] $Owner) {
    # Every repository of an organization or user that is not a fork, 100 per request
    $query = 'query($login: String!, $cursor: String) { repositoryOwner(login: $login) { repositories(first: 100, after: $cursor, ' +
        'ownerAffiliations: OWNER, isFork: false) { pageInfo { hasNextPage endCursor } nodes { ' + $script:RepositoryFields + ' } } } }'
    $cursor = $null
    do {
        $data = Invoke-GitHubQuery -Query $query -Variables @{ login = $Owner; cursor = $cursor }
        if (-not $data.repositoryOwner) { Write-Warning "GitHub no conoce a '$Owner' (vendor_catalog.psd1, Owners)"; return }
        $page = $data.repositoryOwner.repositories
        $page.nodes
        $cursor = $page.pageInfo.endCursor
    } while ($page.pageInfo.hasNextPage)
}

function Get-Release($Repository, [bool] $Prerelease) {
    # latestRelease is the newest stable release. A pre-release channel wants the newest pre-release instead
    # (marked as such, or with a label in its tag: 3.0.0-rc.13), not whatever was published last. A repository
    # that only publishes pre-releases has no latestRelease: its newest release is taken.
    $recent = @()
    if ($Repository.releases -and $Repository.releases.nodes) { $recent = @($Repository.releases.nodes) }
    if ($Prerelease) {
        $newest = @($recent | Where-Object { $_.isPrerelease -or $_.tagName -match '\d-[a-z]' })[0]
        if ($newest) { return $newest }
    }
    if ($Repository.latestRelease) { return $Repository.latestRelease }
    $recent[0]
}

function Get-WindowsAsset($Release) {
    @($Release.releaseAssets.nodes | ForEach-Object { $_.name } |
        Where-Object { $_ -match $script:WindowsAsset -and $_ -notmatch $script:NotSoftware }) | Select-Object -First 1
}

function ConvertTo-DateText($Value) {
    # yyyy-MM-dd of a date as the sources give it. Windows PowerShell leaves ISO 8601 dates as text and
    # PowerShell 7 turns them into [datetime]; an HTTP header says "Wed, 07 Oct 2026 14:51:10 GMT".
    if (-not $Value) { return '' }
    if ($Value -is [datetime]) { return $Value.ToUniversalTime().ToString('yyyy-MM-dd') }
    if ("$Value" -match '^\d{4}-\d{2}-\d{2}') { return "$Value".Substring(0, 10) }
    $parsed = [datetime]::MinValue
    if ([datetime]::TryParse("$Value", [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal, [ref] $parsed)) {
        return $parsed.ToString('yyyy-MM-dd')
    }
    ''
}

function Get-JsonValue($Object, [string] $Path) {
    # 'releases.0.updateTo.url': a property name or the index of an element at each step
    foreach ($step in $Path -split '\.') {
        if ($null -eq $Object) { return $null }
        $Object = if ($step -match '^\d+$') { @($Object)[[int] $step] } else { $Object.$step }
    }
    $Object
}

function Test-Stale([string] $Date) {
    if ($Date -notmatch '^\d{4}-\d{2}-\d{2}$') { return $false }
    [datetime]::ParseExact($Date, 'yyyy-MM-dd', [cultureinfo]::InvariantCulture) -lt (Get-Date).AddYears(-3)
}

function ConvertTo-PlainVersion([string] $Text) {
    # 'v2.102.0', 'release-3.6.6', '140.17.0esr' -> [version] with four numbers. Nothing for a pre-release,
    # a build stamp or anything else that cannot be ordered safely.
    $clean = $Text -replace '^[^\d]*' -replace 'esr$'
    if ($clean -notmatch '^\d{1,9}(\.\d{1,9}){1,3}$') { return $null }
    $numbers = @($clean -split '\.') + @('0', '0', '0') | Select-Object -First 4
    [version] ($numbers -join '.')
}

function ConvertTo-VersionPart([string] $Text) {
    # Numbers, pre-release label and number of that label of a version, whoever wrote it:
    #   'v2.102.0' -> 2 102 0      '158.0b5' -> 158 0, beta, 5      '3.0.0-rc.13' -> 3 0 0, rc, 13
    #   '158.0.0-beta3' -> 158 0 0, beta, 3      '159.0.1.2026100210-alpha' -> 159 0 1 2026100210, alpha, none
    $clean = ($Text -replace '^[^\d]*' -replace 'esr$').ToLowerInvariant()
    if ($clean -notmatch '^(?<numbers>\d{1,12}(\.\d{1,12}){0,3})(?<rest>.*)$') { return $null }
    $part = @{ Numbers = @($Matches.numbers -split '\.' | ForEach-Object { [long] $_ }); Label = ''; Number = $null }
    $rest = $Matches.rest
    if ($rest) {
        if ($rest -notmatch '^[-.]?(?<label>[a-z]+)[-.]?(?<number>\d{1,12})?') { return $null }
        $part.Label = switch ($Matches.label) { 'a' { 'alpha' } 'b' { 'beta' } default { $Matches.label } }
        if ($Matches.number) { $part.Number = [long] $Matches.number }
    }
    $part
}

function Test-UpToDate([string] $Vendor, [string] $Chocolatey) {
    # 'si' / 'no' when the two versions can be ordered, nothing when they cannot
    if (-not $Vendor -or -not $Chocolatey) { return '' }
    if (($Vendor -replace '^[^\d]*') -eq ($Chocolatey -replace '-pre$')) { return 'si' }
    $upstream = ConvertTo-VersionPart -Text $Vendor
    $package = ConvertTo-VersionPart -Text $Chocolatey
    if (-not $upstream -or -not $package) { return '' }
    # Only over the numbers the vendor's version has: a package adds its own after them (the date of a fix
    # version in 2.0.0.20260926, the build of a nightly, the beta number in 158.0.4-beta)
    for ($i = 0; $i -lt $upstream.Numbers.Count; $i++) {
        $number = if ($i -lt $package.Numbers.Count) { $package.Numbers[$i] } else { 0 }
        if ($number -gt $upstream.Numbers[$i]) { return 'si' }
        if ($number -lt $upstream.Numbers[$i]) { return 'no' }
    }
    # Same numbers: the pre-release labels decide, when both say the same kind of thing
    if (-not $upstream.Label -and -not $package.Label) { return 'si' }
    if ($upstream.Label -and -not $package.Label) { return 'si' }  # the final version of that pre-release
    if ($upstream.Label -ne $package.Label -or $null -eq $upstream.Number -or $null -eq $package.Number) { return '' }
    if ($package.Number -ge $upstream.Number) { 'si' } else { 'no' }
}

function Get-MozillaVersion([string] $File, [string] $Key) {
    if (-not $script:MozillaFiles.ContainsKey($File)) {
        $script:MozillaFiles[$File] = Invoke-RestMethod -Uri "https://product-details.mozilla.org/1.0/$File"
    }
    $script:MozillaFiles[$File].$Key
}

function Get-SourceName($Entry) {
    switch ($Entry.Source) {
        'Mozilla'       { "product-details.mozilla.org ($($Entry.Key))" }
        'GitHub'        { "github.com/$($Entry.Repo)" }
        'GitHubTag'     { "github.com/$($Entry.Repo) (tags $($Entry.TagPrefix)*)" }
        'Warp'          { "downloads.cloudflareclient.com ($($Entry.Track))" }
        'GitHubDesktop' { "central.github.com ($($Entry.Track))" }
        'Npm'           { "registry.npmjs.org/$($Entry.Package)" }
        'Listing'       { $Entry.Url }
        'Chrome'        { "versionhistory.googleapis.com ($($Entry.Track))" }
        'Json'          { $Entry.Url }
        'Head'          { if ($Entry.Url) { $Entry.Url } else { $Entry.Installer.Url } }
        default         { "$($Entry.Source)" }
    }
}

function Get-SourceVersion($Entry, [hashtable] $Repositories) {
    # Latest version of a product of the catalog: Version, Date (when the source has one), Archived, a Note
    # and, for an installer, the Download the source itself points to or the Assets of the GitHub release
    $latest = @{ Version = ''; Date = ''; Archived = $false; Note = ''; Download = ''; Assets = @() }
    switch ($Entry.Source) {
        'Mozilla' {
            $latest.Version = Get-MozillaVersion -File $Entry.File -Key $Entry.Key
        }
        'GitHub' {
            if (-not $script:GitHubHeaders.ContainsKey('Authorization')) { throw 'sin token de GitHub' }
            if ($script:GitHubFailure) { throw $script:GitHubFailure }
            $repository = $Repositories[$Entry.Repo]
            if (-not $repository) { throw 'GitHub no encuentra el repositorio' }
            $latest.Archived = [bool] $repository.isArchived
            $release = Get-Release -Repository $repository -Prerelease ([bool] $Entry.Pre)
            if ($release) {
                $latest.Version = $release.tagName
                $latest.Date = ConvertTo-DateText -Value $release.publishedAt
                if ($release.releaseAssets) { $latest.Assets = @($release.releaseAssets.nodes | ForEach-Object { $_.name }) }
                # A pre-release channel whose newest pre-release is older than the stable version, or has none
                # among the releases asked for. The two dates are compared whole (same day, hours apart).
                $stable = $repository.latestRelease
                if ($Entry.Pre -and $stable) {
                    if ($stable.tagName -eq $release.tagName) {
                        $latest.Note = 'sin prereleases entre las ultimas versiones: es la estable'
                    } elseif ($stable.publishedAt -gt $release.publishedAt) {
                        $latest.Note = "la version estable $($stable.tagName) es posterior"
                    }
                }
            }
        }
        'GitHubTag' {
            $refs = Invoke-RestMethod -Uri "https://api.github.com/repos/$($Entry.Repo)/git/matching-refs/tags/$($Entry.TagPrefix)" -Headers $script:GitHubHeaders
            $pattern = '^refs/tags/' + [regex]::Escape($Entry.TagPrefix) + '\d+(\.\d+)*$'
            $latest.Version = $refs | ForEach-Object { $_.ref } | Where-Object { $_ -match $pattern } |
                ForEach-Object { $_ -replace '^refs/tags/' } | Sort-Object { ConvertTo-PlainVersion -Text $_ } -Descending | Select-Object -First 1
        }
        'Warp' {
            $feed = Invoke-RestMethod -Uri "https://downloads.cloudflareclient.com/v1/update/json/windows/$($Entry.Track)"
            $item = $feed.items | Sort-Object { [version] $_.version } -Descending | Select-Object -First 1
            $latest.Version = $item.version
            $latest.Date = ConvertTo-DateText -Value $item.releaseDate
            $latest.Download = $item.packageURL
        }
        'GitHubDesktop' {
            $release = Invoke-RestMethod -Uri "https://central.github.com/api/deployments/desktop/desktop/latest?env=$($Entry.Track)&os=windows&arch=x64"
            $latest.Version = $release.version
            $latest.Date = ConvertTo-DateText -Value $release.pub_date
            # The API points to the update ZIP; the setup program is published next to it
            $latest.Download = "$($release.url)" -replace 'GitHubDesktop-x64\.zip$', 'GitHubDesktopSetup-x64.exe'
        }
        'Chrome' {
            $history = Invoke-RestMethod -Uri "https://versionhistory.googleapis.com/v1/chrome/platforms/win64/channels/$($Entry.Track)/versions?pageSize=1&order_by=version%20desc"
            $latest.Version = @($history.versions)[0].version
        }
        'Json' {
            $document = Invoke-RestMethod -Uri $Entry.Url
            $latest.Version = Get-JsonValue -Object $document -Path $Entry.VersionPath
            if ($Entry.DatePath) { $latest.Date = ConvertTo-DateText -Value (Get-JsonValue -Object $document -Path $Entry.DatePath) }
            if ($Entry.DownloadPath) { $latest.Download = Get-JsonValue -Object $document -Path $Entry.DownloadPath }
        }
        'Head' {
            # No version feed: the "latest" download itself tells when it changed and, when it redirects to a
            # file with the version in its name, which version it is
            $address = if ($Entry.Url) { $Entry.Url } else { $Entry.Installer.Url }
            $response = Invoke-WebRequest -Uri $address -Method Head -UseBasicParsing
            $latest.Date = ConvertTo-DateText -Value $response.Headers['Last-Modified']
            $latest.Version = '(ultima)'
            if ($Entry.Pattern -and "$($response.BaseResponse.ResponseUri)" -match $Entry.Pattern) { $latest.Version = $Matches[1] }
        }
        'Npm' {
            $latest.Version = (Invoke-RestMethod -Uri "https://registry.npmjs.org/$($Entry.Package)/latest").version
        }
        'Listing' {
            $page = (Invoke-WebRequest -Uri $Entry.Url -UseBasicParsing).Content
            # Windows PowerShell gives bytes when the server does not say that the answer is text
            if ($page -is [byte[]]) { $page = [System.Text.Encoding]::UTF8.GetString($page) }
            $latest.Version = [regex]::Matches($page, $Entry.Pattern) | ForEach-Object { $_.Groups[1].Value } |
                Sort-Object { ConvertTo-PlainVersion -Text $_ } -Descending | Select-Object -First 1
        }
        default { throw "fuente desconocida '$($Entry.Source)' en vendor_catalog.psd1" }
    }
    if (-not $latest.Version) { throw 'la fuente no devolvio ninguna version' }
    $latest
}

function Get-ChocolateyVersion([string] $Id, [bool] $Prerelease) {
    # Version of a package in the community repository, or nothing when the ID has no listed version.
    # The feed needs the quotes written as they are, compares the ID case-sensitively (hence tolower) and
    # answers 406 to an "or", so each flag is asked on its own: the stable version first and then the newest
    # of any kind, or only the newest (-Prerelease) for a package of pre-releases or an ID that is a guess.
    $key = "$Id|$Prerelease".ToLowerInvariant()
    if ($script:ChocolateyVersions.ContainsKey($key)) { return $script:ChocolateyVersions[$key] }
    $version = $null
    $flags = if ($Prerelease) { @('IsAbsoluteLatestVersion') } else { @('IsLatestVersion', 'IsAbsoluteLatestVersion') }
    foreach ($flag in $flags) {
        $url = "https://community.chocolatey.org/api/v2/Packages()?`$filter=tolower(Id)%20eq%20'$($Id.ToLowerInvariant())'%20and%20$flag"
        $feed = ([xml] (Invoke-WebRequest -Uri $url -UseBasicParsing).Content).feed
        $entry = @($feed.entry | Where-Object { $_ })[0]
        if ($entry) { $version = [string] $entry.properties.Version; break }
    }
    $script:ChocolateyVersions[$key] = $version
    $version
}

function Get-LocalStatus([string] $Id) {
    # What this repository does with a Chocolatey ID: 'actual', 'descontinuado', and the retired IDs whose
    # bridge leads to it
    if (-not $Id) { return '' }
    $text = @()
    if ($script:ActiveIds -contains $Id) { $text += 'actual' }
    if ($script:RetiredIds -contains $Id) { $text += 'descontinuado' }
    if ($script:Replaced.ContainsKey($Id)) { $text += "sustituye a $($script:Replaced[$Id] -join ', ')" }
    $text -join '; '
}

function Get-InstallerSpec($Entry, $Latest, [string] $Language) {
    # Where the installer of a product is downloaded from, how it is run and who must have signed it
    $installer = $Entry.Installer
    $url = if ($installer.Asset) {
        # A file of the GitHub release, by its name
        $asset = @($Latest.Assets | Where-Object { $_ -match $installer.Asset })[0]
        if (-not $asset) { throw "el release $($Latest.Version) no tiene ningun archivo que cumpla '$($installer.Asset)'" }
        "https://github.com/$($Entry.Repo)/releases/download/$($Latest.Version)/$asset"
    } elseif ($installer.Url) {
        $installer.Url.Replace('{lang}', $Language).Replace('{version}', "$($Latest.Version)")
    } else {
        $Latest.Download  # the source of the version says where the installer is
    }
    if ("$url" -notmatch '^https://') { throw 'el catalogo no da una descarga https para este producto' }
    $type = if ($installer.Type) { $installer.Type } elseif (([uri] $url).AbsolutePath -match '\.msi$') { 'msi' } else { 'exe' }
    @{ Url = "$url"; Type = $type; Arguments = "$($installer.Arguments)"; Signer = "$($installer.Signer)"; PerUser = ($installer.Scope -eq 'user') }
}

function Save-Installer([string] $Url, [string] $Path) {
    # Downloads an installer. An https download can be redirected anywhere: where the file really came from
    # has to be https as well, or it is not kept (it would have travelled in the open).
    $response = Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing -PassThru
    $origin = $response.BaseResponse.ResponseUri
    if (-not $origin -or $origin.Scheme -ne 'https') {
        Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        throw "la descarga termino en una direccion que no es https ($origin)"
    }
}

function Get-InstallerPublisher([string] $Path, [string] $Signer) {
    # Who signed a downloaded installer. Fails unless Windows trusts the signature and, when the catalog
    # names the signer, it is that one: a file that is not the vendor's must never be run.
    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    if ("$($signature.Status)" -ne 'Valid') { throw "la firma digital del instalador no es valida ($($signature.Status))" }
    $publisher = $signature.SignerCertificate.GetNameInfo([System.Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false)
    if ($Signer -and $publisher -ne $Signer) { throw "el instalador esta firmado por '$publisher' y no por '$Signer'" }
    $publisher
}

function Test-Administrator {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object System.Security.Principal.WindowsPrincipal $identity).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Installer($Spec, [string] $Path) {
    # Runs an installer silently and returns its exit code. An installer for the current user runs as the
    # user; the others ask for elevation (UAC) unless the script is already elevated.
    $start = @{ Wait = $true; PassThru = $true }
    if ($Spec.Type -eq 'msi') {
        $start.FilePath = Join-Path $env:SystemRoot 'System32\msiexec.exe'
        $start.ArgumentList = ("/i `"$Path`" /qn /norestart $($Spec.Arguments)").Trim()
    } else {
        $start.FilePath = $Path
        if ($Spec.Arguments) { $start.ArgumentList = $Spec.Arguments }
    }
    if (-not $Spec.PerUser -and -not (Test-Administrator)) { $start.Verb = 'RunAs' }
    (Start-Process @start).ExitCode
}

# --- Vendors asked for ---
$catalog = Import-PowerShellDataFile -Path (Join-Path $PSScriptRoot 'vendor_catalog.psd1')
$vendors = @($catalog.Vendors)
if ($Vendor) {
    # powershell -File passes "a,b" as a single string
    $wanted = @($Vendor -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $unknown = @($wanted | Where-Object { $name = $_; -not ($vendors | Where-Object { $_ -like "$name*" }) })
    if ($unknown) { throw "Fabricante(s) desconocido(s): $($unknown -join ', '). Disponibles: $($vendors -join ', ')" }
    $vendors = @($vendors | Where-Object { $name = $_; $wanted | Where-Object { $name -like "$_*" } })
}

# --- Packages of this repository: active ones, retired IDs and the active package each bridge leads to ---
$script:ActiveIds = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Paquetes\actuales') -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
$script:RetiredIds = @()
$script:Replaced = @{}
foreach ($nuspec in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Paquetes\descontinuados\*\*.nuspec') -ErrorAction SilentlyContinue) {
    $metadata = ([xml] (Get-Content -LiteralPath $nuspec.FullName -Raw)).package.metadata
    $script:RetiredIds += $metadata.id
    foreach ($dependency in @($metadata.dependencies.dependency | Where-Object { $_.id })) {
        if (-not $script:Replaced.ContainsKey($dependency.id)) { $script:Replaced[$dependency.id] = @() }
        $script:Replaced[$dependency.id] += $metadata.id
    }
}

Write-Host '========================================================'
Write-Host 'Catalogo de fabricantes: software para Windows y paquetes'
Write-Host '========================================================'

$token = Get-GitHubToken
if ($token) {
    $script:GitHubHeaders.Authorization = "Bearer $token"
} else {
    Write-Host '[AVISO] Sin token de GitHub (GITHUB_TOKEN o "gh auth login"): los productos alojados en GitHub quedan sin version y no se buscan otros repositorios.' -ForegroundColor Yellow
}

# --- Install mode: official installers, straight from the vendor ---
if ($Install) {
    # powershell -File passes "a,b" as a single string
    $ids = @($Install -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
    $installable = @($catalog.Products | Where-Object { $_.Id -and $_.Installer })
    $available = @($installable | ForEach-Object { $_.Id })
    $unknown = @($ids | Where-Object { $available -notcontains $_ })
    if ($unknown) { throw "Sin instalador en el catalogo: $($unknown -join ', '). Se puede instalar: $(($available | Sort-Object) -join ', ')" }
    if (-not $Language) { $Language = (Get-UICulture).Name }
    $selected = @(foreach ($id in $ids) { $installable | Where-Object { $_.Id -eq $id } | Select-Object -First 1 })

    $repositories = @{}
    $names = @($selected | Where-Object { $_.Source -eq 'GitHub' } | ForEach-Object { $_.Repo } | Sort-Object -Unique)
    if ($token -and $names) { $repositories = Get-CatalogRepository -Name $names }
    $folder = Join-Path ([System.IO.Path]::GetTempPath()) 'vendor_catalog'

    $results = @(foreach ($entry in $selected) {
            $result = [pscustomobject][ordered]@{ Id = $entry.Id; Producto = "$($entry.Product) ($($entry.Channel))"; Version = ''; Descarga = ''; Resultado = '' }
            $file = $null
            try {
                $latest = Get-SourceVersion -Entry $entry -Repositories $repositories
                $spec = Get-InstallerSpec -Entry $entry -Latest $latest -Language $Language
                $result.Version = $latest.Version
                $result.Descarga = $spec.Url
                Write-Host ">>> $($entry.Product) ($($entry.Channel)) $($latest.Version)" -ForegroundColor Cyan
                Write-Host "    $($spec.Url)"
                $proceed = if ($Yes -and -not $WhatIfPreference) { $true } else { $PSCmdlet.ShouldProcess("$($entry.Product) $($latest.Version) <$($spec.Url)>", 'Descargar e instalar') }
                if (-not $proceed) {
                    $result.Resultado = if ($WhatIfPreference) { 'simulado (-WhatIf)' } else { 'omitido' }
                    $result
                    continue
                }

                New-Item -ItemType Directory -Path $folder -Force | Out-Null
                $file = Join-Path $folder "$($entry.Id).$($spec.Type)"
                try {
                    Save-Installer -Url $spec.Url -Path $file
                } catch {
                    # A vendor does not build its installer in every language: English is always there
                    if ($entry.Installer.Url -notmatch '\{lang\}' -or $Language -eq 'en-US') { throw }
                    Write-Host "    [AVISO] No hay instalador en $($Language): se descarga en en-US." -ForegroundColor Yellow
                    $spec = Get-InstallerSpec -Entry $entry -Latest $latest -Language 'en-US'
                    $result.Descarga = $spec.Url
                    Save-Installer -Url $spec.Url -Path $file
                }
                $publisher = Get-InstallerPublisher -Path $file -Signer $spec.Signer
                Write-Host "    Firmado por: $publisher"
                Write-Host '    Instalando...'
                $code = Invoke-Installer -Spec $spec -Path $file
                $result.Resultado = switch ($code) {
                    0 { 'instalado' }
                    3010 { 'instalado (falta reiniciar Windows)' }
                    1641 { 'instalado (Windows se esta reiniciando)' }
                    default { "error: el instalador termino con el codigo $code" }
                }
            } catch {
                $result.Resultado = "error: $($_.Exception.Message)"
            } finally {
                if ($file -and (Test-Path -LiteralPath $file)) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue }
            }
            $result
        })

    if ($PassThru) {
        $results
    } else {
        Write-Host "`n========================================================"
        Write-Host '                RESUMEN DE INSTALACION'
        Write-Host '========================================================'
        Write-Host (($results | Format-Table -Property Id, Producto, Version, Resultado -AutoSize -Wrap | Out-String -Width 200).Trim("`r", "`n"))
    }
    $failed = @($results | Where-Object { $_.Resultado -like 'error:*' } | ForEach-Object { $_.Id })
    if ($failed) { throw "No se pudo instalar: $($failed -join ', ')" }
    return
}

# --- 1. Products of the catalog ---
$entries = @($catalog.Products | Where-Object { $vendors -contains $_.Vendor })
Write-Host ">>> Consultando a los fabricantes: $($entries.Count) productos del catalogo ($($vendors -join ', '))..." -ForegroundColor Cyan
$repositories = @{}
$names = @($entries | Where-Object { $_.Source -eq 'GitHub' } | ForEach-Object { $_.Repo } | Sort-Object -Unique)
if ($token -and $names) { $repositories = Get-CatalogRepository -Name $names }

$rows = New-Object System.Collections.Generic.List[object]
foreach ($entry in $entries) {
    $row = [pscustomobject][ordered]@{
        Fabricante = $entry.Vendor; Producto = $entry.Product; Canal = $entry.Channel; Estado = 'actual'
        Version = ''; Fecha = ''; PaqueteChocolatey = "$($entry.Choco)"; Chocolatey = ''; AlDia = ''
        EnRepo = (Get-LocalStatus -Id $entry.Choco); Instalar = $(if ($entry.Id -and $entry.Installer) { $entry.Id } else { '' })
        Nota = ''; Origen = 'catalogo'; Fuente = (Get-SourceName -Entry $entry)
        Prerelease = [bool] $entry.Pre; Supuesto = $false
    }
    $notes = @()
    if ($entry.Note) { $notes += $entry.Note }
    try {
        $latest = Get-SourceVersion -Entry $entry -Repositories $repositories
        $row.Version = $latest.Version
        $row.Fecha = $latest.Date
        if ($latest.Note) { $notes += $latest.Note }
        if ($latest.Archived) { $row.Estado = 'descontinuado'; $notes += 'repositorio archivado' }
        elseif (Test-Stale -Date $latest.Date) { $notes += "sin versiones desde $($latest.Date.Substring(0, 4))" }
    } catch {
        $row.Version = '?'
        $notes += "no se pudo consultar: $($_.Exception.Message)"
    }
    if ($entry.Status) { $row.Estado = $entry.Status }
    $row.Nota = $notes -join '; '
    $rows.Add($row)
}

# --- 2. Other repositories of the vendors with a download for Windows ---
if ($token -and -not $NoDiscover) {
    Write-Host '>>> Buscando en GitHub otros repositorios con descargas para Windows (puede tardar un par de minutos)...' -ForegroundColor Cyan
    $known = @($catalog.Products | ForEach-Object { $_.Repo } | Where-Object { $_ })
    foreach ($name in $vendors) {
        foreach ($owner in @($catalog.Owners[$name])) {
            $found = 0
            foreach ($repository in Find-GitHubRepository -Owner $owner) {
                $fullName = $repository.nameWithOwner
                if ($known -contains $fullName -or ($catalog.Ignore | Where-Object { $fullName -match $_ })) { continue }
                $release = $repository.latestRelease
                if (-not $release -or -not (Get-WindowsAsset -Release $release)) { continue }
                $date = ConvertTo-DateText -Value $release.publishedAt
                # The only ID to try is the name of the repository, and only for software that is still alive
                $guess = if ($repository.isArchived) { '' } else { ($fullName -split '/')[1].ToLowerInvariant() }
                $rows.Add([pscustomobject][ordered]@{
                        Fabricante = $name; Producto = $fullName; Canal = ''
                        Estado = $(if ($repository.isArchived) { 'descontinuado' } else { 'actual' })
                        Version = $release.tagName; Fecha = $date; PaqueteChocolatey = $guess; Chocolatey = ''; AlDia = ''
                        EnRepo = (Get-LocalStatus -Id $guess); Instalar = ''
                        Nota = $(if ($repository.isArchived) { 'repositorio archivado' } elseif (Test-Stale -Date $date) { "sin versiones desde $($date.Substring(0, 4))" } else { '' })
                        Origen = 'GitHub'; Fuente = "github.com/$fullName"; Prerelease = $true; Supuesto = $true
                    })
                $found++
            }
            Write-Host "    github.com/$owner : $found"
        }
    }
}

# --- 3. Chocolatey ---
$withId = @($rows | Where-Object { $_.PaqueteChocolatey })
Write-Host ">>> Consultando Chocolatey: $($withId.Count) paquetes..." -ForegroundColor Cyan
foreach ($row in $withId) {
    try {
        $version = Get-ChocolateyVersion -Id $row.PaqueteChocolatey -Prerelease $row.Prerelease
    } catch {
        $row.Chocolatey = "$($row.PaqueteChocolatey): no se pudo consultar"
        continue
    }
    if ($version) {
        # For a repository found on GitHub the ID is only its name: a package called the same may be something else
        $row.Chocolatey = "$($row.PaqueteChocolatey) $version" + $(if ($row.Supuesto) { ' (?)' } else { '' })
        if (-not $row.Supuesto) { $row.AlDia = Test-UpToDate -Vendor $row.Version -Chocolatey $version }
    } elseif ($row.Supuesto) {
        $row.PaqueteChocolatey = ''
    } else {
        $row.Chocolatey = "$($row.PaqueteChocolatey): sin version listada"
    }
}

# --- Report ---
$order = @{}
for ($i = 0; $i -lt $catalog.Vendors.Count; $i++) { $order[$catalog.Vendors[$i]] = $i }
# Vendors in the order of the catalog; for each one its named products first, then the repositories found
$sorted = @($rows | Sort-Object -Property { $order[$_.Fabricante] }, { $_.Origen -ne 'catalogo' }, Producto, Canal)
$public = 'Fabricante', 'Producto', 'Canal', 'Estado', 'Version', 'Fecha', 'Chocolatey', 'AlDia', 'EnRepo', 'Instalar', 'Nota', 'Origen', 'Fuente'
$shown = @(
    'Fabricante', 'Producto', 'Canal', 'Version', 'Fecha'
    @{ Name = 'Chocolatey'; Expression = { if ($_.Chocolatey) { $_.Chocolatey + $(if ($_.AlDia -eq 'no') { ' (atrasado)' } else { '' }) } else { '-' } } }
    @{ Name = 'En este repo'; Expression = { $_.EnRepo } }
    'Instalar', 'Nota'
)
$groups = [ordered]@{ 'ACTUALES' = 'actual'; 'DESCONTINUADOS' = 'descontinuado' }

if ($OutFile) {
    $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
    $lines = @('# Catalogo de fabricantes', '',
        "Generado por ``vendor_catalog.ps1`` el $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm')) UTC. Fabricantes: $($vendors -join ', ').", '')
    foreach ($title in $groups.Keys) {
        $lines += "## $($title.Substring(0, 1))$($title.Substring(1).ToLowerInvariant())", ''
        $lines += '| Fabricante | Producto | Canal | Version | Fecha | Chocolatey | En este repo | Instalar | Nota |', '| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |'
        foreach ($row in $sorted | Where-Object { $_.Estado -eq $groups[$title] } | Select-Object -Property $shown) {
            $lines += '| ' + (@($row.PSObject.Properties | ForEach-Object { "$($_.Value)" -replace '\|', '/' }) -join ' | ') + ' |'
        }
        $lines += ''
    }
    [System.IO.File]::WriteAllLines($path, $lines, (New-Object System.Text.UTF8Encoding $false))
    Write-Host ">>> Informe guardado en $path" -ForegroundColor Green
}

if ($PassThru) {
    $sorted | Select-Object -Property $public
} else {
    foreach ($title in $groups.Keys) {
        $group = @($sorted | Where-Object { $_.Estado -eq $groups[$title] })
        Write-Host "`n========================================================"
        Write-Host "  $title ($($group.Count))"
        Write-Host '========================================================'
        if ($group) {
            Write-Host (($group | Select-Object -Property $shown | Format-Table -AutoSize | Out-String -Width 300).Trim("`r", "`n"))
        } else {
            Write-Host '  (ninguno)'
        }
    }
    Write-Host ''
    $current = @($sorted | Where-Object { $_.Estado -eq 'actual' })
    Write-Host ('Actuales: {0} ({1} con paquete en Chocolatey, {2} de ellos atrasados; {3} en este repositorio). Descontinuados: {4}.' -f `
            $current.Count, @($current | Where-Object { $_.Chocolatey -and $_.Chocolatey -notmatch 'sin version listada|no se pudo' }).Count,
        @($current | Where-Object { $_.AlDia -eq 'no' }).Count, @($current | Where-Object { $_.EnRepo }).Count, ($sorted.Count - $current.Count))
    Write-Host 'Chocolatey "(?)": existe un paquete con el mismo nombre que el repositorio; puede no ser el mismo programa.'
    Write-Host 'Columna "Instalar": .\vendor_catalog.bat -Install <nombre>[,<nombre>] baja el instalador oficial del fabricante, comprueba su firma y lo instala, sin Chocolatey.'
}
