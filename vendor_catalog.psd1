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

    # Repositories that the search finds (their name, or a pattern like 'github/gh-*') with Choco, Winget, NoPackage
    # or NoWinget, as in Products. With Choco the report does not guess the package from the name of the repository.
    Repos    = @{
        'github/app'                                  = @{ Choco = 'github-copilot-app'; Winget = 'GitHub.CopilotApp' }
        'google/flatbuffers'                          = @{ Choco = 'flatc' }
        'bazelbuild/bazel'                            = @{ Winget = 'Bazel.Bazel' }
        'bazelbuild/bazelisk'                         = @{ Winget = 'Bazel.Bazelisk' }
        'actions/gh-*'                                = @{ NoPackage = 'extension de gh: gh extension install' }
        'cli/gh-*'                                    = @{ NoPackage = 'extension de gh: gh extension install' }
        'github/gh-*'                                 = @{ NoPackage = 'extension de gh: gh extension install' }
        'bazelbuild/java_tools'                       = @{ NoPackage = 'piezas que descarga Bazel' }
        'bazelbuild/rules_rust'                       = @{ NoPackage = 'lo descarga Bazel' }
        'google/dawn'                                 = @{ NoPackage = 'biblioteca' }
        'google/filament'                             = @{ NoPackage = 'biblioteca' }
        'google/sentencepiece'                        = @{ NoPackage = 'biblioteca' }
        'google/scientific_dart'                      = @{ NoPackage = 'bibliotecas DLL' }
        'google/binexport'                            = @{ NoPackage = 'complemento de IDA Pro y Ghidra' }
        'google/idaidle'                              = @{ NoPackage = 'complemento de IDA Pro' }
        'google/gn-language-server'                   = @{ NoPackage = 'lo instala la extension del editor' }
        'google/android-emulator-hypervisor-driver'   = @{ NoWinget = 'se instala con un script' }
        'github/copilot-language-server-release'      = @{ NoPackage = 'lo descargan los editores' }
        'github/computer-use-plugin'                  = @{ NoPackage = 'complemento de Copilot' }
        'awslabs/serverless-rules'                    = @{ NoPackage = 'complemento de tflint' }
        'awslabs/windows-web-app-migration-assistant' = @{ NoWinget = 'son scripts de PowerShell' }
        'dependabot/git-shim'                         = @{ NoPackage = 'pieza interna de Dependabot' }
        'mozilla/autograph-experiments'               = @{ NoPackage = 'cliente de pruebas' }
        'anysphere/ripgrep'                           = @{ NoPackage = 'version de ripgrep para Cursor' }
    }

    # Chocolatey package of some packages of the winget index that no product above names (the others get the
    # Chocolatey package of the product with that Winget ID)
    WingetChoco = @{
        'Mozilla.Firefox.MSIX'                     = 'firefox'
        'Mozilla.Firefox.DeveloperEdition.MSIX'    = 'firefox-dev'
        'Mozilla.Firefox.ESR.MSIX'                 = 'firefoxesr'
        'Mozilla.jsshell'                          = 'jsshell'
        'Mozilla.opus-tools'                       = 'opus-tools'
        'Mozilla.SeaMonkey'                        = 'seamonkey'
        'Mozilla.Thunderbird.MSIX'                 = 'thunderbird'
        'Mozilla.Thunderbird.Beta.MSIX'            = 'thunderbird-mozilla'
        'Mozilla.Thunderbird.ESR.MSIX'             = 'thunderbirdesr'
        'Google.Chrome.EXE'                        = 'googlechrome'
        'Google.Chrome.Beta.EXE'                   = 'googlechromebeta'
        'Google.Chrome.Dev.EXE'                    = 'googlechromedev'
        'Google.Antigravity'                       = 'antigravity'
        'Google.AntigravityCLI'                    = 'antigravity-cli'
        'Google.AntigravityIDE'                    = 'antigravity-ide'
        'Google.ContainerTools.Skaffold'           = 'skaffold'
        'Google.DartSDK'                           = 'dart-sdk'
        'Google.GeminiDesktop'                     = 'gemini-desktop'
        'Google.GoogleWebDesigner'                 = 'google-web-designer'
        'Google.JapaneseIME'                       = 'googlejapaneseinput'
        'Google.Libwebp'                           = 'webp'
        'Google.Pinyin'                            = 'google-pinyin'
        'Google.PlatformTools'                     = 'adb'
        'Google.Protobuf'                          = 'protoc'
        'Google.UIforETW'                          = 'uiforetw'
        'Google.WorkspaceSyncForMicrosoftOutlook'  = 'google-workspace-sync'
        'Amazon.AppStream'                         = 'amazon-appstream'
        'Amazon.Chime'                             = 'amazon-chime'
        'Amazon.Corretto.11.JDK'                   = 'corretto11jdk'
        'Amazon.Corretto.17.JDK'                   = 'corretto17jdk'
        'Amazon.Corretto.8.JDK'                    = 'corretto8jdk'
        'Amazon.Corretto.8.JRE'                    = 'corretto8jre'
        'Amazon.Kindle'                            = 'kindle'
        'Amazon.KindlePreviewer'                   = 'kindlepreviewer'
        'Amazon.Music'                             = 'amazon-music'
        'Amazon.NoSQLWorkbench'                    = 'nosql-workbench'
        'Amazon.Redshift.ODBC.v1'                  = 'redshift-odbc'
        'Amazon.SendToKindle'                      = 'sendtokindle'
        'Amazon.WorkspacesClient'                  = 'amazon-workspaces'
    }

    # Packages of the winget index that cannot have a package in Chocolatey, and why
    WingetNoChoco = @{
        'Mozilla.XULRunner'          = 'Mozilla lo retiro en 2015'
        'GitHub.Atom.Beta'           = 'descontinuado'
        'Google.GoogleDesktop'       = 'Google lo retiro en 2011'
        'Google.GoogleUpdater'       = 'lo instalan Chrome y los demas programas de Google'
        'Google.Picasa'              = 'Google lo retiro en 2016'
        'Google.Talk'                = 'Google lo retiro'
        'Google.VPNByGoogleOne'      = 'Google lo retiro en 2024'
        'Amazon.CopilotCLI'          = 'descontinuado'
        'Amazon.Corretto.18.JDK'     = 'version sin soporte del fabricante'
        'Amazon.Corretto.19.JDK'     = 'version sin soporte del fabricante'
        'Amazon.Corretto.20.JDK'     = 'version sin soporte del fabricante'
        'Amazon.Corretto.22.JDK'     = 'version sin soporte del fabricante'
        'Amazon.Corretto.23.JDK'     = 'version sin soporte del fabricante'
        'Amazon.Corretto.24.JDK'     = 'version sin soporte del fabricante'
    }

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
    #   Winget                     ID of its package in the winget community repository, or of the one that this
    #                              repository prepares for winget (README, "winget")
    #   Format                     what the vendor publishes for Windows ('exe, msi'), when it is not the files of
    #                              a GitHub release (the script reads those)
    #   NoPackage, NoWinget        why it cannot be packaged at all, or not for winget (report, "Se puede")
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
        @{ Vendor = 'Mozilla'; Product = 'Firefox'; Channel = 'estable'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_VERSION'; Choco = 'firefox'; Winget = 'Mozilla.Firefox'; Format = 'exe, msi'
            Id = 'firefox'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox ESR'; Channel = 'esr'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_ESR'; Choco = 'firefoxesr'; Winget = 'Mozilla.Firefox.ESR'; Format = 'exe, msi'
            Id = 'firefox-esr'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-esr-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Beta'; Channel = 'beta'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'LATEST_FIREFOX_RELEASED_DEVEL_VERSION'; Choco = 'firefox-beta'; Pre = $true; Winget = 'Mozilla.Firefox.Beta.MSIX'; Format = 'exe, msi'
            Id = 'firefox-beta'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-beta-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Developer Edition'; Channel = 'dev'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_DEVEDITION'; Choco = 'firefox-dev'; Pre = $true; Winget = 'Mozilla.Firefox.DeveloperEdition'; Format = 'exe, msi'
            Id = 'firefox-dev'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Firefox Nightly'; Channel = 'nightly'; Source = 'Mozilla'; File = 'firefox_versions.json'; Key = 'FIREFOX_NIGHTLY'; Choco = 'firefox-nightly'; Pre = $true; Winget = 'Mozilla.Firefox.Nightly.MSIX'; Format = 'exe, msi'
            Id = 'firefox-nightly'; Installer = @{ Url = 'https://download.mozilla.org/?product=firefox-nightly-latest-l10n-ssl&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird'; Channel = 'estable'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_VERSION'; Choco = 'thunderbird'; Winget = 'Mozilla.Thunderbird'; Format = 'exe, msi'
            Id = 'thunderbird'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-latest-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird ESR'; Channel = 'esr'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'THUNDERBIRD_ESR'; Choco = 'thunderbirdesr'; Winget = 'Mozilla.Thunderbird.ESR'; Format = 'exe, msi'
            Id = 'thunderbird-esr'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-esr-latest-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird Beta'; Channel = 'beta'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_DEVEL_VERSION'; Choco = 'thunderbird-mozilla'; Pre = $true; Winget = 'Mozilla.Thunderbird.Beta'; Format = 'exe, msi'
            Id = 'thunderbird-beta'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-beta-latest-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbird Daily'; Channel = 'nightly'; Source = 'Mozilla'; File = 'thunderbird_versions.json'; Key = 'LATEST_THUNDERBIRD_NIGHTLY_VERSION'; Choco = 'thunderbird-nightly'; Pre = $true; Format = 'exe, msi'
            NoWinget = 'todas las builds de un ciclo se llaman igual en Windows'
            Id = 'thunderbird-daily'; Installer = @{ Url = 'https://download.mozilla.org/?product=thunderbird-nightly-latest-l10n-SSL&os=win64&lang={lang}'; Arguments = '/S'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Mozilla VPN'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla-mobile/mozilla-vpn-client'; Winget = 'Mozilla.VPN'
            Id = 'mozilla-vpn'; Installer = @{ Asset = '^MozillaVPN\.msi$'; Signer = 'Mozilla Corporation' } }
        @{ Vendor = 'Mozilla'; Product = 'Thunderbolt'; Channel = 'estable'; Source = 'GitHub'; Repo = 'thunderbird/thunderbolt' }
        @{ Vendor = 'Mozilla'; Product = 'MozillaBuild'; Channel = 'estable'; Source = 'Listing'; Url = 'https://ftp.mozilla.org/pub/mozilla/libraries/win32/'; Pattern = 'MozillaBuildSetup-(\d+(?:\.\d+)+)\.exe'; Choco = 'mozillabuild'; Format = 'exe' }
        @{ Vendor = 'Mozilla'; Product = 'geckodriver'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/geckodriver'; Choco = 'selenium-gecko-driver'; Winget = 'Mozilla.GeckoDriver' }
        @{ Vendor = 'Mozilla'; Product = 'sccache'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/sccache'; Choco = 'sccache'; Winget = 'Mozilla.sccache' }
        @{ Vendor = 'Mozilla'; Product = 'mozregression'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/mozregression'; Winget = 'Mozilla.mozregression' }
        @{ Vendor = 'Mozilla'; Product = 'grcov'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mozilla/grcov' }

        @{ Vendor = 'Cloudflare'; Product = 'Cloudflare WARP'; Channel = 'estable'; Source = 'Warp'; Track = 'ga'; Choco = 'warp'; Winget = 'Cloudflare.Warp'; Format = 'msi'
            Id = 'warp'; Installer = @{ Type = 'msi'; Signer = 'Cloudflare, Inc.' } }
        @{ Vendor = 'Cloudflare'; Product = 'Cloudflare WARP'; Channel = 'beta'; Source = 'Warp'; Track = 'beta'; Choco = 'cloudflare-warp-pre'; Pre = $true; Winget = 'Cloudflare.Warp.Beta'; Format = 'msi'
            Id = 'warp-beta'; Installer = @{ Type = 'msi'; Signer = 'Cloudflare, Inc.' } }
        @{ Vendor = 'Cloudflare'; Product = 'cloudflared'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cloudflared'; Choco = 'cloudflared'; Winget = 'Cloudflare.cloudflared'
            Id = 'cloudflared'; Installer = @{ Asset = '^cloudflared-windows-amd64\.msi$'; Signer = 'Cloudflare, Inc.' } }
        @{ Vendor = 'Cloudflare'; Product = 'flarectl'; Channel = 'estable'; Source = 'GitHubTag'; Repo = 'cloudflare/cloudflare-go'; TagPrefix = 'v0.'; Choco = 'flarectl'; Format = 'tar.gz' }
        @{ Vendor = 'Cloudflare'; Product = 'Wrangler'; Channel = 'estable'; Source = 'Npm'; Package = 'wrangler' }
        @{ Vendor = 'Cloudflare'; Product = 'workerd'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/workerd' }
        @{ Vendor = 'Cloudflare'; Product = 'cf-terraforming'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cf-terraforming' }
        @{ Vendor = 'Cloudflare'; Product = 'cfssl'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cloudflare/cfssl' }

        # The download link of desktop.github.com: the update API of the stable channel does not always answer
        @{ Vendor = 'GitHub'; Product = 'GitHub Desktop'; Channel = 'estable'; Source = 'Head'; Pattern = 'releases/(\d+(?:\.\d+)+)-'; Repo = 'desktop/desktop'; Choco = 'github-desktop'; Winget = 'GitHub.GitHubDesktop'; Format = 'exe, msi'
            Id = 'github-desktop'; Installer = @{ Url = 'https://central.github.com/deployments/desktop/desktop/latest/win32'; Arguments = '-s'; Scope = 'user'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub Desktop'; Channel = 'beta'; Source = 'GitHubDesktop'; Track = 'beta'; Repo = 'desktop/desktop'; Choco = 'github-desktop-pre'; Pre = $true; Winget = 'GitHub.GitHubDesktop.Beta'; Format = 'exe, msi'
            Id = 'github-desktop-beta'; Installer = @{ Arguments = '-s'; Scope = 'user'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub CLI (gh)'; Channel = 'estable'; Source = 'GitHub'; Repo = 'cli/cli'; Choco = 'gh'; Winget = 'GitHub.cli'
            Id = 'gh'; Installer = @{ Asset = '^gh_[\d.]+_windows_amd64\.msi$'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub Copilot CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/copilot-cli'; Choco = 'github-copilot-cli'; Winget = 'GitHub.Copilot' }
        @{ Vendor = 'GitHub'; Product = 'CodeQL CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/codeql-cli-binaries'; Choco = 'codeql' }
        @{ Vendor = 'GitHub'; Product = 'Git LFS'; Channel = 'estable'; Source = 'GitHub'; Repo = 'git-lfs/git-lfs'; Choco = 'git-lfs'; Winget = 'GitHub.GitLFS'
            Id = 'git-lfs'; Installer = @{ Asset = '^git-lfs-windows-v[\d.]+\.exe$'; Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'; Signer = 'GitHub, Inc.' } }
        @{ Vendor = 'GitHub'; Product = 'Git Credential Manager'; Channel = 'estable'; Source = 'GitHub'; Repo = 'git-ecosystem/git-credential-manager'; Winget = 'Git.GCM'
            Note = 'los paquetes gcm y git-credential-manager-for-windows de Chocolatey son de la version antigua'
            Id = 'gcm'; Installer = @{ Asset = '^gcm-win-x64-[\d.]+\.exe$'; Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'; Signer = 'Microsoft Corporation' } }
        @{ Vendor = 'GitHub'; Product = 'GitHub Actions Runner'; Channel = 'estable'; Source = 'GitHub'; Repo = 'actions/runner' }
        @{ Vendor = 'GitHub'; Product = 'GitHub MCP Server'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/github-mcp-server'; Choco = 'github-mcp-server' }
        @{ Vendor = 'GitHub'; Product = 'Dependabot CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'dependabot/cli'; Choco = 'dependabot' }
        @{ Vendor = 'GitHub'; Product = 'GitHub Enterprise Importer (gei)'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/gh-gei' }
        @{ Vendor = 'GitHub'; Product = 'git-sizer'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/git-sizer'; Choco = 'git-sizer'; Winget = 'GitHub.git-sizer' }
        @{ Vendor = 'GitHub'; Product = 'smimesign'; Channel = 'estable'; Source = 'GitHub'; Repo = 'github/smimesign'; Choco = 'smimesign'; Winget = 'GitHub.smimesign' }
        @{ Vendor = 'GitHub'; Product = 'Atom'; Channel = 'estable'; Source = 'GitHub'; Repo = 'atom/atom'; Choco = 'atom'; Status = 'descontinuado'; Note = 'GitHub lo retiro en diciembre de 2022'; Winget = 'GitHub.Atom' }
        @{ Vendor = 'GitHub'; Product = 'hub'; Channel = 'estable'; Source = 'GitHub'; Repo = 'mislav/hub'; Choco = 'hub'; Status = 'descontinuado'; Note = 'sustituido por GitHub CLI (gh)'; Winget = 'GitHub.hub' }

        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'estable'; Source = 'Chrome'; Track = 'stable'; Choco = 'googlechrome'; Winget = 'Google.Chrome'; Format = 'msi, exe'
            Id = 'chrome'; Installer = @{ Url = 'https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'beta'; Source = 'Chrome'; Track = 'beta'; Choco = 'googlechromebeta'; Pre = $true; Winget = 'Google.Chrome.Beta'; Format = 'msi, exe'
            Id = 'chrome-beta'; Installer = @{ Url = 'https://dl.google.com/dl/chrome/install/beta/googlechromebetastandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'dev'; Source = 'Chrome'; Track = 'dev'; Choco = 'googlechromedev'; Pre = $true; Winget = 'Google.Chrome.Dev'; Format = 'msi, exe'
            Id = 'chrome-dev'; Installer = @{ Url = 'https://dl.google.com/dl/chrome/install/dev/googlechromedevstandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Chrome'; Channel = 'canary'; Source = 'Chrome'; Track = 'canary'; Choco = 'googlechromecanary'; Pre = $true; Winget = 'Google.Chrome.Canary'; Format = 'exe' }
        @{ Vendor = 'Google'; Product = 'Google Drive'; Channel = 'estable'; Source = 'Head'; Choco = 'googledrive'; Winget = 'Google.GoogleDrive'; Format = 'exe'
            Id = 'drive'; Installer = @{ Url = 'https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe'; Arguments = '--silent --desktop_shortcut'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Earth Pro'; Channel = 'estable'; Source = 'Head'; Choco = 'googleearthpro'; Winget = 'Google.EarthPro'; Format = 'exe'
            Id = 'earth-pro'; Installer = @{ Url = 'https://dl.google.com/dl/earth/client/advanced/current/googleearthprowin-x64.exe'; Arguments = 'OMAHA=1'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Chrome Remote Desktop Host'; Channel = 'estable'; Source = 'Head'; Choco = 'chrome-remote-desktop-host'; Winget = 'Google.ChromeRemoteDesktopHost'; Format = 'msi'
            Id = 'chrome-remote-desktop'; Installer = @{ Url = 'https://dl.google.com/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Credential Provider for Windows'; Channel = 'estable'; Source = 'Head'; Winget = 'Google.CredentialProviderForWindows'; Format = 'msi'
            Id = 'gcpw'; Installer = @{ Url = 'https://dl.google.com/credentialprovider/gcpwstandaloneenterprise64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Google Cloud CLI'; Channel = 'estable'; Source = 'Json'; Url = 'https://dl.google.com/dl/cloudsdk/channels/rapid/components-2.json'; VersionPath = 'version'; Choco = 'gcloudsdk'; Winget = 'Google.CloudSDK'; Format = 'exe'
            Id = 'gcloud'; Installer = @{ Url = 'https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe'; Arguments = '/S'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Go'; Channel = 'estable'; Source = 'Json'; Url = 'https://go.dev/dl/?mode=json'; VersionPath = '0.version'; Choco = 'golang'; Winget = 'GoLang.Go'; Format = 'msi'
            Id = 'go'; Installer = @{ Url = 'https://go.dev/dl/{version}.windows-amd64.msi'; Signer = 'Google LLC' } }
        @{ Vendor = 'Google'; Product = 'Android Studio'; Channel = 'estable'; Source = 'Listing'; Url = 'https://dl.google.com/android/studio/patches/updates.xml'; Pattern = 'version="[^"|]*\| (\d+(?:\.\d+)+)(?: Patch \d+)?"'; Choco = 'androidstudio'; Winget = 'Google.AndroidStudio'; Format = 'exe' }
        @{ Vendor = 'Google'; Product = 'Gemini CLI'; Channel = 'estable'; Source = 'Npm'; Package = '@google/gemini-cli'; Choco = 'gemini-cli' }

        @{ Vendor = 'Amazon'; Product = 'Kiro'; Channel = 'estable'; Source = 'Json'; Url = 'https://prod.download.desktop.kiro.dev/stable/metadata-win32-x64-user-stable.json'; Winget = 'Amazon.Kiro'; Format = 'exe'
            VersionPath = 'currentRelease'; DatePath = 'releases.0.updateTo.pub_date'; DownloadPath = 'releases.0.updateTo.url'; Choco = 'kiro'
            Id = 'kiro'; Installer = @{ Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=!runcode'; Scope = 'user'; Signer = 'Amazon.com, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'AWS CLI'; Channel = 'estable'; Source = 'GitHubTag'; Repo = 'aws/aws-cli'; TagPrefix = '2.'; Choco = 'awscli'; Winget = 'Amazon.AWSCLI'; Format = 'msi'
            Id = 'aws-cli'; Installer = @{ Url = 'https://awscli.amazonaws.com/AWSCLIV2.msi'; Signer = 'Amazon Web Services, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'AWS SAM CLI'; Channel = 'estable'; Source = 'GitHub'; Repo = 'aws/aws-sam-cli'; Choco = 'awssamcli'; Winget = 'Amazon.SAM-CLI'
            Id = 'sam-cli'; Installer = @{ Asset = '^AWS_SAM_CLI_64_PY3\.msi$'; Signer = 'Amazon Web Services, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'AWS Session Manager Plugin'; Channel = 'estable'; Source = 'Listing'; Url = 'https://s3.amazonaws.com/session-manager-downloads/plugin/latest/VERSION'; Pattern = '^\s*(\d+(?:\.\d+)+)'; Choco = 'awscli-session-manager'; Winget = 'Amazon.SessionManagerPlugin'; Format = 'exe'
            Id = 'session-manager-plugin'; Installer = @{ Url = 'https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe'; Arguments = '/quiet /norestart'; Signer = 'Amazon Web Services, Inc.' } }
        @{ Vendor = 'Amazon'; Product = 'Amazon Corretto 21 (JDK)'; Channel = 'estable'; Source = 'Head'; Pattern = 'amazon-corretto-(\d+(?:\.\d+)+)-windows'; Choco = 'corretto21jdk'; Winget = 'Amazon.Corretto.21.JDK'; Format = 'msi'
            Id = 'corretto-21'; Installer = @{ Url = 'https://corretto.aws/downloads/latest/amazon-corretto-21-x64-windows-jdk.msi'; Signer = 'Amazon.com Services LLC' } }
        @{ Vendor = 'Amazon'; Product = 'Amazon Corretto 25 (JDK)'; Channel = 'estable'; Source = 'Head'; Pattern = 'amazon-corretto-(\d+(?:\.\d+)+)-windows'; Choco = 'corretto25jdk'; Winget = 'Amazon.Corretto.25.JDK'; Format = 'msi'
            Id = 'corretto-25'; Installer = @{ Url = 'https://corretto.aws/downloads/latest/amazon-corretto-25-x64-windows-jdk.msi'; Signer = 'Amazon.com Services LLC' } }
        @{ Vendor = 'Amazon'; Product = 'AWS CDK'; Channel = 'estable'; Source = 'Npm'; Package = 'aws-cdk' }

        @{ Vendor = 'Cursor (Anysphere)'; Product = 'Cursor'; Channel = 'estable'; Source = 'Json'; Url = 'https://api2.cursor.sh/updates/api/download/stable/win32-x64-user/cursor'; Winget = 'Anysphere.Cursor'; Format = 'exe'
            VersionPath = 'version'; DownloadPath = 'downloadUrl'; Choco = 'cursoride'
            Id = 'cursor'; Installer = @{ Arguments = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /MERGETASKS=!runcode'; Scope = 'user'; Signer = 'Anysphere, Inc.' } }

        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'Fenix Web Server'; Channel = 'estable'; Source = 'GitHub'; Repo = 'coreybutler/fenix'; Choco = 'fenix-web-server'; Winget = 'CoreyButler.FenixWebServer' }
        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'Fenix Web Server'; Channel = 'pre'; Source = 'GitHub'; Repo = 'coreybutler/fenix'; Choco = 'fenix-web-server'; Pre = $true; Format = 'exe'; NoWinget = 'su instalador espera a que se acepte un aviso' }
        @{ Vendor = 'Fenix (Corey Butler)'; Product = 'NVM for Windows'; Channel = 'estable'; Source = 'GitHub'; Repo = 'nvm-windows/nvm'; Choco = 'nvm'; Winget = 'CoreyButler.NVMforWindows' }
    )
}
