# Data of vendor_catalog.ps1: the Windows software of the vendors whose programs this repository packages.
# Nothing here is a package: it is the list the catalog checks against each vendor and against Chocolatey.
@{
    # Order of the vendors in the report
    Vendors  = @('Mozilla', 'Cloudflare', 'GitHub', 'Fenix (Corey Butler)')

    # GitHub organizations and users of each vendor. Every repository of theirs whose latest release has a
    # download for Windows is listed, besides the products below (skipped with -NoDiscover).
    Owners   = @{
        'Mozilla'              = @('mozilla', 'mozilla-mobile', 'mozilla-services', 'mozilla-ai', 'mozilla-platform-ops', 'MozillaSecurity', 'thunderbird')
        'Cloudflare'           = @('cloudflare')
        'GitHub'               = @('github', 'desktop', 'cli', 'actions', 'dependabot', 'git-lfs', 'git-ecosystem', 'githubnext', 'atom')
        'Fenix (Corey Butler)' = @('coreybutler', 'nvm-windows')
    }

    # Repositories that publish files for Windows but are not a program to install (regular expressions)
    Ignore   = @(
        '^actions/(.+-versions|runner-images)$'  # tool caches and virtual machine images of the runners
        'terraform-provider-'                    # Terraform plugins, installed by Terraform itself
        '^desktop/dugite-native$'                # Git build embedded in GitHub Desktop
        '^github/codeql-action$'                 # the same CodeQL CLI as github/codeql-cli-binaries
        '^github/copilot\.vim$'                  # Neovim builds kept for the tests of the plugin
        '^cloudflare/binary-install$'            # sample binary of an npm helper
    )

    # Products with a name. Fields:
    #   Vendor, Product, Channel   what it is ('estable', 'esr', 'beta', 'dev', 'nightly', 'pre')
    #   Source                     where the latest version comes from, with its own fields:
    #       Mozilla        File + Key of https://product-details.mozilla.org/1.0/
    #       GitHub         Repo: latest release (the newest one, pre-releases included, with Pre = $true)
    #       GitHubTag      Repo + TagPrefix: highest tag "<TagPrefix>x.y" (a product released from one branch)
    #       Warp           Track of Cloudflare's update feed (ga, beta)
    #       GitHubDesktop  Track of GitHub Desktop's update API (production, beta)
    #       Npm            Package of the npm registry
    #       Listing        Url of a folder listing + Pattern whose first group is the version
    #   Repo                       with any other source: its repository, so that the search does not list it again
    #   Choco                      ID of its package in the Chocolatey community repository, if it has one
    #   Pre                        $true when that package only has pre-release versions
    #   Status, Note               'descontinuado' and why, when the vendor dropped it without archiving a
    #                              repository (an archived repository is found out by the script)
    Products = @(
        @{ Vendor = 'Mozilla'; Product = 'Firefox'; Channel = 'estable'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_VERSION'; Choco = 'firefox' }
        @{ Vendor = 'Mozilla'; Product = 'Firefox ESR'; Channel = 'esr'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_ESR'; Choco = 'firefoxesr' }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Beta'; Channel = 'beta'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_RELEASED_DEVEL_VERSION'; Choco = 'firefox-beta'; Pre = $true }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Developer Edition'; Channel = 'dev'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_DEVEDITION'; Choco = 'firefox-dev'; Pre = $true }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Nightly'; Channel = 'nightly'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_NIGHTLY'; Choco = 'firefox-nightly'; Pre = $true }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird'; Channel = 'estable'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_VERSION'; Choco = 'thunderbird' }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird ESR'; Channel = 'esr'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'THUNDERBIRD_ESR' }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird Beta'; Channel = 'beta'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_DEVEL_VERSION'; Choco = 'thunderbird-mozilla'; Pre = $true }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird Daily'; Channel = 'nightly'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_NIGHTLY_VERSION'; Choco = 'thunderbird-nightly'; Pre = $true }
        @{ Vendor = 'Mozilla'; Product = 'Mozilla VPN'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla-mobile/mozilla-vpn-client' }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbolt'; Channel = 'estable'; Source = 'GitHub'; Repo = 'thunderbird/thunderbolt' }
        @{ Vendor = 'Mozilla'; Product = 'MozillaBuild'; Channel = 'estable'; Source = 'Listing'; Url = 'https://ftp.mozilla.org/pub/mozilla/libraries/win32/'; Pattern = 'MozillaBuildSetup-(\d+(?:\.\d+)+)\.exe'; Choco = 'mozillabuild' }
        @{ Vendor = 'Mozilla'; Product = 'geckodriver'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/geckodriver'; Choco = 'selenium-gecko-driver' }
        @{ Vendor = 'Mozilla'; Product = 'sccache'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/sccache'; Choco = 'sccache' }
        @{ Vendor = 'Mozilla'; Product = 'mozregression'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/mozregression' }
        @{ Vendor = 'Mozilla'; Product = 'grcov'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/grcov' }

        @{ Vendor = 'Cloudflare'; Product = 'Cloudflare WARP'; Channel = 'estable'; Source = 'Warp'; Track = 'ga'; Choco = 'warp' }
        @{ Vendor = 'Cloudflare'; Product = 'Cloudflare WARP'; Channel = 'beta'; Source = 'Warp'; Track = 'beta'; Choco = 'cloudflare-warp-pre'; Pre = $true }
        @{ Vendor = 'Cloudflare'; Product = 'cloudflared'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cloudflared'; Choco = 'cloudflared' }
        @{ Vendor = 'Cloudflare'; Product = 'flarectl'; Channel = 'estable'; Source = 'GitHubTag'; Repo = 'cloudflare/cloudflare-go'; TagPrefix = 'v0.'; Choco = 'flarectl' }
        @{ Vendor = 'Cloudflare'; Product = 'Wrangler'; Channel = 'estable'; Source = 'Npm'; Package = 'wrangler' }
        @{ Vendor = 'Cloudflare'; Product = 'workerd'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/workerd' }
        @{ Vendor = 'Cloudflare'; Product = 'cf-terraforming'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cf-terraforming' }
        @{ Vendor = 'Cloudflare'; Product = 'cfssl'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cfssl' }

        @{ Vendor = 'GitHub'; Product = 'GitHub Desktop'; Channel = 'estable'; Source = 'GitHubDesktop'; Track = 'production'; Repo = 'desktop/desktop'; Choco = 'github-desktop' }
        @{ Vendor = 'GitHub'; Product = 'GitHub Desktop'; Channel = 'beta'; Source = 'GitHubDesktop'; Track = 'beta'; Repo = 'desktop/desktop'; Choco = 'github-desktop-pre'; Pre = $true }
        @{ Vendor = 'GitHub'; Product = 'GitHub CLI (gh)'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cli/cli'; Choco = 'gh' }
        @{ Vendor = 'GitHub'; Product = 'GitHub Copilot CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/copilot-cli'; Choco = 'github-copilot-cli' }
        @{ Vendor = 'GitHub'; Product = 'CodeQL CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/codeql-cli-binaries'; Choco = 'codeql' }
        @{ Vendor = 'GitHub'; Product = 'Git LFS'; Channel = 'estable'; Source = 'GitHub'; Repo = 'git-lfs/git-lfs'; Choco = 'git-lfs' }
        @{ Vendor = 'GitHub'; Product = 'Git Credential Manager'; Channel = 'estable'; Source = 'GitHub'; Repo = 'git-ecosystem/git-credential-manager' }
        @{ Vendor = 'GitHub'; Product = 'GitHub Actions Runner'; Channel = 'estable'; Source = 'GitHub'; Repo = 'actions/runner' }
        @{ Vendor = 'GitHub'; Product = 'GitHub MCP Server'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/github-mcp-server'; Choco = 'github-mcp-server' }
        @{ Vendor = 'GitHub'; Product = 'Dependabot CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'dependabot/cli'; Choco = 'dependabot' }
        @{ Vendor = 'GitHub'; Product = 'GitHub Enterprise Importer (gei)'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/gh-gei' }
        @{ Vendor = 'GitHub'; Product = 'git-sizer'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/git-sizer'; Choco = 'git-sizer' }
        @{ Vendor = 'GitHub'; Product = 'smimesign'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/smimesign'; Choco = 'smimesign' }
        @{ Vendor = 'GitHub'; Product = 'Atom'; Channel = 'estable'; Source = 'GitHub'; Repo = 'atom/atom'; Choco = 'atom'; Status = 'descontinuado'; Note = 'GitHub lo retiro en diciembre de 2022' }
        @{ Vendor = 'GitHub'; Product = 'hub'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mislav/hub'; Choco = 'hub'; Status = 'descontinuado'; Note = 'sustituido por GitHub CLI (gh)' }

        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'Fenix Web Server'; Channel = 'estable'; Source = 'GitHub'; Repo = 'coreybutler/fenix'; Choco = 'fenix-web-server' }
        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'Fenix Web Server'; Channel = 'pre'; Source = 'GitHub'; Repo = 'coreybutler/fenix'; Choco = 'fenix-web-server'; Pre = $true }
        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'NVM for Windows'; Channel = 'estable'; Source = 'GitHub'; Repo = 'nvm-windows/nvm'; Choco = 'nvm' }
    )
}
