# winget data of this package: update_all.ps1 prepares a winget version for each version it publishes to
# Chocolatey, and only submits it when WINGET_SUBMIT is 'true' (README, "winget"). {Key} is $Latest.Key of AU.
# No templates in this folder: "komac update" makes the manifests from those already in winget.
@{
    Id         = 'GitHub.GitHubDesktop.Beta'
    Version    = '{Version}'
    # The four installers of the manifest in winget, from the GitHub release (the same builds as the CDN)
    Installers = @{
        'x64-exe'   = 'https://github.com/desktop/desktop/releases/download/release-{Version}/GitHubDesktopSetup-x64.exe'
        'arm64-exe' = 'https://github.com/desktop/desktop/releases/download/release-{Version}/GitHubDesktopSetup-arm64.exe'
        'x64-msi'   = 'https://github.com/desktop/desktop/releases/download/release-{Version}/GitHubDesktopSetup-x64.msi'
        'arm64-msi' = 'https://github.com/desktop/desktop/releases/download/release-{Version}/GitHubDesktopSetup-arm64.msi'
    }
}
