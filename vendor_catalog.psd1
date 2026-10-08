# Data of vendor_catalog.ps1: the Windows software of a few vendors, where its latest version is published and,
# for the products the script can install, where the official installer is. Nothing here is a package.
@{
    # Order of the vendors in the report
    Vendors  = @('Mozilla', 'Cloudflare', 'GitHub', 'Google', 'Amazon', 'Cursor (Anysphere)', 'Fenix (Corey Butler)')

    # GitHub organizations and users of each vendor. Every repository of theirs whose latest release has a
    # download for Windows is listed, besides the products below (skipped with -NoDiscover).
    Owners   = @{
        'Mozilla'              = @('mozilla', 'mozilla-mobile', 'mozilla-services', 'mozilla-ai', 'mozilla-platform-ops', 'MozillaSecurity', 'thunderbird')
        'Cloudflare'           = @('cloudflare')
        'GitHub'               = @('github', 'desktop', 'cli', 'actions', 'dependabot', 'git-lfs', 'git-ecosystem', 'githubnext', 'atom')
        'Google'               = @('google', 'GoogleChrome', 'google-gemini', 'bazelbuild', 'flutter')
        'Amazon'               = @('aws', 'awslabs', 'kirodotdev', 'corretto', 'amzn')
        'Cursor (Anysphere)'   = @('anysphere')
        'Fenix (Corey Butler)' = @('coreybutler', 'nvm-windows')
    }

    # Publishers of each vendor in the winget community repository (github.com/microsoft/winget-pkgs), the
    # fullest public list of what a vendor ships for Windows. Everything it has of them is listed (skipped with
    # -NoDiscover) and can be installed with -Install <Publisher.Package>: the script reads the vendor's address,
    # the SHA256 and the arguments from the manifest and downloads and runs the installer itself.
    Winget   = @{
        'Mozilla'              = @('Mozilla')
        'Cloudflare'           = @('Cloudflare')
        'GitHub'               = @('GitHub')
        'Google'               = @('Google')
        'Amazon'               = @('Amazon')
        'Cursor (Anysphere)'   = @('Anysphere')
        'Fenix (Corey Butler)' = @('CoreyButler')
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
    #       Chrome         Track of Chrome's version history API (stable, beta, dev, canary)
    #       Npm            Package of the npm registry
    #       Json           Url of a JSON document + VersionPath, and optionally DatePath and DownloadPath, each a
    #                      path of property names and indexes ('releases.0.updateTo.url')
    #       Listing        Url of a page or text + Pattern whose first group is the version (the highest wins)
    #       Head           no version feed: the date of the "latest" download (Url, or the installer's), and the
    #                      version when it redirects to a file named after it (Pattern, first group)
    #   Repo                       with any other source: its repository, so that the search does not list it again
    #   Choco                      ID of its package in the Chocolatey community repository, if it has one
    #   Pre                        $true when that package only has pre-release versions
    #   Status, Note               'descontinuado' and why, when the vendor dropped it without archiving a
    #                              repository (an archived repository is found out by the script)
    #   Id + Installer             the product can be installed with -Install <Id>. Installer says where from:
    #       Url            a download that is always the latest ({lang} = language, {version} = latest version),
    #       Asset          or a file of the GitHub release, by a pattern of its name,
    #                      or neither, when the source of the version points to the installer itself;
    #       Type           'msi' or 'exe' when the address does not end in it
    #       Arguments      what makes an .exe install silently (an .msi always gets /qn /norestart)
    #       Scope          'user' for an installer that needs no administrator
    #       Signer         who must have signed it (read from the signature of the real installer). Every product
    #                      here names one; without it the script would accept any publisher that Windows trusts
    Products = @(
        @{ Vendor = 'Mozilla'; Product = 'Firefox'; Channel = 'estable'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_VERSION'; Choco = 'firefox'
            Id = 'firefox'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox ESR'; Channel = 'esr'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_ESR'; Choco = 'firefoxesr'
            Id = 'firefox-esr'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Beta'; Channel = 'beta'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_RELEASED_DEVEL_VERSION'; Choco = 'firefox-beta'; Pre = $true
            Id = 'firefox-beta'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-beta-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Developer Edition'; Channel = 'dev'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_DEVEDITION'; Choco = 'firefox-dev'; Pre = $true
            Id = 'firefox-dev'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Nightly'; Channel = 'nightly'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_NIGHTLY'; Choco = 'firefox-nightly'; Pre = $true
            Id = 'firefox-nightly'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-nightly-latest-l10n-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird'; Channel = 'estable'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_VERSION'; Choco = 'thunderbird'
            Id = 'thunderbird'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-latest-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird ESR'; Channel = 'esr'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'THUNDERBIRD_ESR'
            Id = 'thunderbird-esr'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-esr-latest-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird Beta'; Channel = 'beta'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_DEVEL_VERSION'; Choco = 'thunderbird-mozilla'; Pre = $true
            Id = 'thunderbird-beta'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-beta-latest-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird Daily'; Channel = 'nightly'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_NIGHTLY_VERSION'; Choco = 'thunderbird-nightly'; Pre = $true
            Id = 'thunderbird-daily'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-nightly-latest-l10n-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Mozilla VPN'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla-mobile/mozilla-vpn-client'
            Id = 'mozilla-vpn'; Installer = @{ Asset = '^MozillaVPN\.msi$'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbolt'; Channel = 'estable'; Source = 'GitHub'; Repo = 'thunderbird/thunderbolt' }
        @{ Vendor = 'Mozilla'; Product = 'MozillaBuild'; Channel = 'estable'; Source = 'Listing'; Url = 'https://ftp.mozilla.org/pub/mozilla/libraries/win32/'; Pattern = 'MozillaBuildSetup-(\d+(?:\.\d+)+)\.exe'; Choco = 'mozillabuild' }
        @{ Vendor = 'Mozilla'; Product = 'geckodriver'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/geckodriver'; Choco = 'selenium-gecko-driver' }
        @{ Vendor = 'Mozilla'; Product = 'sccache'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/sccache'; Choco = 'sccache' }
        @{ Vendor = 'Mozilla'; Product = 'mozregression'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/mozregression' }
        @{ Vendor = 'Mozilla'; Product = 'grcov'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/grcov' }

        @{ Vendor = 'Cloudflare'; Product = 'Cloudflare WARP'; Channel = 'estable'; Source = 'Warp'; Track = 'ga'; Choco = 'warp'
            Id = 'warp'; Installer = @{ Type = 'msi'; Signer = 'Cloudflare, Inc.' } }
        @{ Vendor = 'Cloudflare'; Product = 'Cloudflare WARP'; Channel = 'beta'; Source = 'Warp'; Track = 'beta'; Choco = 'cloudflare-warp-pre'; Pre = $true
            Id = 'warp-beta'; Installer = @{ Type = 'msi'; Signer = 'Cloudflare, Inc.' } }
        @{ Vendor = 'Cloudflare'; Product = 'cloudflared'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cloudflared'; Choco = 'cloudflared'
            Id = 'cloudflared'; Installer = @{ Asset = '^cloudflared-windows-amd64\.msi$'; Signer = 'Cloudflare, Inc.' } }
        @{ Vendor = 'Cloudflare'; Product = 'flarectl'; Channel = 'estable'; Source = 'GitHubTag'; Repo = 'cloudflare/cloudflare-go'; TagPrefix = 'v0.'; Choco = 'flarectl' }
        @{ Vendor = 'Cloudflare'; Product = 'Wrangler'; Channel = 'estable'; Source = 'Npm'; Package = 'wrangler' }
        @{ Vendor = 'Cloudflare'; Product = 'workerd'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/workerd' }
        @{ Vendor = 'Cloudflare'; Product = 'cf-terraforming'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cf-terraforming' }
        @{ Vendor = 'Cloudflare'; Product = 'cfssl'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cfssl' }

        # The download link of desktop.github.com: the update API of the stable channel does not always answer
        @{ Vendor = 'GitHub'; Product = 'GitHub Desktop'; Channel = 'estable'; Source = 'Head'; Pattern = 'releases/(\d+(?:\.\d+)+)-'; Repo = 'desktop/desktop'; Choco = 'github-desktop'
            Id = 'github-desktop'; Installer = @{ Url = 'https://central.github.com/deployments/desktop/desktop/latest/win32'; Arguments = '-s'; Scope = 'user'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub Desktop'; Channel = 'beta'; Source = 'GitHubDesktop'; Track = 'beta'; Repo = 'desktop/desktop'; Choco = 'github-desktop-pre'; Pre = $true
            Id = 'github-desktop-beta'; Installer = @{ Arguments = '-s'; Scope = 'user'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub CLI (gh)'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cli/cli'; Choco = 'gh'
            Id = 'gh'; Installer = @{ Asset = '^gh_[\d.]+_windows_amd64\.msi$'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub Copilot CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/copilot-cli'; Choco = 'github-copilot-cli' }
        @{ Vendor = 'GitHub'; Product = 'CodeQL CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/codeql-cli-binaries'; Choco = 'codeql' }
        @{ Vendor = 'GitHub'; Product = 'Git LFS'; Channel = 'estable'; Source = 'GitHub'; Repo = 'git-lfs/git-lfs'; Choco = 'git-lfs'
            Id = 'git-lfs'; Installer = @{ Asset = '^git-lfs-windows-v[\d.]+\.exe$'; Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'Git Credential Manager'; Channel = 'estable'; Source = 'GitHub'; Repo = 'git-ecosystem/git-credential-manager'
            Id = 'gcm'; Installer = @{ Asset = '^gcm-win-x64-[\d.]+\.exe$'; Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'; Signer = 'Microsoft Corporation' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub Actions Runner'; Channel = 'estable'; Source = 'GitHub'; Repo = 'actions/runner' }
        @{ Vendor = 'GitHub'; Product = 'GitHub MCP Server'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/github-mcp-server'; Choco = 'github-mcp-server' }
        @{ Vendor = 'GitHub'; Product = 'Dependabot CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'dependabot/cli'; Choco = 'dependabot' }
        @{ Vendor = 'GitHub'; Product = 'GitHub Enterprise Importer (gei)'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/gh-gei' }
        @{ Vendor = 'GitHub'; Product = 'git-sizer'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/git-sizer'; Choco = 'git-sizer' }
        @{ Vendor = 'GitHub'; Product = 'smimesign'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/smimesign'; Choco = 'smimesign' }
        @{ Vendor = 'GitHub'; Product = 'Atom'; Channel = 'estable'; Source = 'GitHub'; Repo = 'atom/atom'; Choco = 'atom'; Status = 'descontinuado'; Note = 'GitHub lo retiro en diciembre de 2022' }
        @{ Vendor = 'GitHub'; Product = 'hub'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mislav/hub'; Choco = 'hub'; Status = 'descontinuado'; Note = 'sustituido por GitHub CLI (gh)' }

        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'estable'; Source = 'Chrome'; Track = 'stable'; Choco = 'googlechrome'
            Id = 'chrome'; Installer = @{ Url = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'beta'; Source = 'Chrome'; Track = 'beta'; Choco = 'googlechromebeta'; Pre = $true
            Id = 'chrome-beta'; Installer = @{ Url = 'https://dl.google.com/dl/chrome/install/beta/googlechromebetastandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'dev'; Source = 'Chrome'; Track = 'dev'
            Id = 'chrome-dev'; Installer = @{ Url = 'https://dl.google.com/dl/chrome/install/dev/googlechromedevstandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'canary'; Source = 'Chrome'; Track = 'canary' }
        @{ Vendor = 'Google'; Product = 'Google Drive'; Channel = 'estable'; Source = 'Head'; Choco = 'googledrive'
            Id = 'drive'; Installer = @{ Url = 'https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe'; Arguments = '--silent --desktop_shortcut'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Earth Pro'; Channel = 'estable'; Source = 'Head'; Choco = 'googleearthpro'
            Id = 'earth-pro'; Installer = @{ Url = 'https://dl.google.com/dl/earth/client/advanced/current/googleearthprowin-x64.exe'; Arguments = 'OMAHA=1'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Chrome Remote Desktop Host'; Channel = 'estable'; Source = 'Head'; Choco = 'chrome-remote-desktop-host'
            Id = 'chrome-remote-desktop'; Installer = @{ Url = 'https://dl.google.com/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Credential Provider for Windows'; Channel = 'estable'; Source = 'Head'
            Id = 'gcpw'; Installer = @{ Url = 'https://dl.google.com/credentialprovider/gcpwstandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Cloud CLI'; Channel = 'estable'; Source = 'Json'; Url = 'https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json'; VersionPath = 'version'; Choco = 'gcloudsdk'
            Id = 'gcloud'; Installer = @{ Url = 'https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe'; Arguments = '/S'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Go'; Channel = 'estable'; Source = 'Json'; Url = 'https://go.dev/dl/?mode=json'; VersionPath = '0.version'; Choco = 'golang'
            Id = 'go'; Installer = @{ Url = 'https://go.dev/dl/{version}.windows-amd64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Android Studio'; Channel = 'estable'; Source = 'Listing'; Url = 'https://dl.google.com/android/studio/patches/updates.xml'; Pattern = 'version="[^"|]*\| (\d+(?:\.\d+)+)(?: Patch \d+)?"'; Choco = 'androidstudio' }
        @{ Vendor = 'Google'; Product = 'Gemini CLI'; Channel = 'estable'; Source = 'Npm'; Package = '@google/gemini-cli'; Choco = 'gemini-cli' }

        @{ Vendor = 'Amazon'; Product = 'Kiro'; Channel = 'estable'; Source = 'Json'; Url = 'https://prod.download.desktop.kiro.dev/stable/metadata-win32-x64-user-stable.json'
            VersionPath = 'currentRelease'; DatePath = 'releases.0.updateTo.pub_date'; DownloadPath = 'releases.0.updateTo.url'; Choco = 'kiro'
            Id = 'kiro'; Installer = @{ Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=!runcode'; Scope = 'user'; Signer = 'Amazon.com, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'AWS CLI'; Channel = 'estable'; Source = 'GitHubTag'; Repo = 'aws/aws-cli'; TagPrefix = '2.'; Choco = 'awscli'
            Id = 'aws-cli'; Installer = @{ Url = 'https://awscli.amazonaws.com/AWSCLIV2.msi'; Signer = 'Amazon Web Services, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'AWS SAM CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'aws/aws-sam-cli'; Choco = 'awssamcli'
            Id = 'sam-cli'; Installer = @{ Asset = '^AWS_SAM_CLI_64_PY3\.msi$'; Signer = 'Amazon Web Services, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'AWS Session Manager Plugin'; Channel = 'estable'; Source = 'Listing'; Url = 'https://s3.amazonaws.com/session-manager-downloads/plugin/latest/VERSION'; Pattern = '^\s*(\d+(?:\.\d+)+)'; Choco = 'awscli-session-manager'
            Id = 'session-manager-plugin'; Installer = @{ Url = 'https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe'; Arguments = '/quiet /norestart'; Signer = 'Amazon Web Services, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'Amazon Corretto 21 (JDK)'; Channel = 'estable'; Source = 'Head'; Pattern = 'amazon-corretto-(\d+(?:\.\d+)+)-windows'; Choco = 'corretto21jdk'
            Id = 'corretto-21'; Installer = @{ Url = 'https://corretto.aws/downloads/latest/amazon-corretto-21-x64-windows-jdk.msi'; Signer = 'Amazon.com Services LLC' } }
        @{ Vendor = 'Amazon'; Product = 'Amazon Corretto 25 (JDK)'; Channel = 'estable'; Source = 'Head'; Pattern = 'amazon-corretto-(\d+(?:\.\d+)+)-windows'; Choco = 'corretto25jdk'
            Id = 'corretto-25'; Installer = @{ Url = 'https://corretto.aws/downloads/latest/amazon-corretto-25-x64-windows-jdk.msi'; Signer = 'Amazon.com Services LLC' } }
        @{ Vendor = 'Amazon'; Product = 'AWS CDK'; Channel = 'estable'; Source = 'Npm'; Package = 'aws-cdk' }

        @{ Vendor = 'Cursor (Anysphere)'; Product = 'Cursor'; Channel = 'estable'; Source = 'Json'; Url = 'https://api2.cursor.sh/updates/api/download/stable/win32-x64-user/cursor'
            VersionPath = 'version'; DownloadPath = 'downloadUrl'; Choco = 'cursoride'
            Id = 'cursor'; Installer = @{ Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=!runcode'; Scope = 'user'; Signer = 'Anysphere, Inc.' } }

        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'Fenix Web Server'; Channel = 'estable'; Source = 'GitHub'; Repo = 'coreybutler/fenix'; Choco = 'fenix-web-server' }
        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'Fenix Web Server'; Channel = 'pre'; Source = 'GitHub'; Repo = 'coreybutler/fenix'; Choco = 'fenix-web-server'; Pre = $true }
        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'NVM for Windows'; Channel = 'estable'; Source = 'GitHub'; Repo = 'nvm-windows/nvm'; Choco = 'nvm' }
    )
}
