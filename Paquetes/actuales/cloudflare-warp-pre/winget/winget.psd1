# winget data of this package: update_all.ps1 prepares a winget version for each version it publishes to
# Chocolatey, and only submits it when WINGET_SUBMIT is 'true' (README, "winget"). {Key} is $Latest.Key of AU.
# The manifests come from the *.yaml templates of this folder: the ID is new in winget, so "komac update" has
# no previous version to start from. Once it is in winget the templates can go (README).
@{
    Id             = 'Cloudflare.Warp.Beta'
    # The MSI (and Apps & Features) calls 2026.9.1555.1 26.9.1555.1, like the stable Cloudflare.Warp in winget
    Version        = '{Version}'
    VersionPattern = '^20(?<v>\d{2}\.\d+\.\d+\.\d+)-pre$'
    Installers     = @{ x64 = '{URL64}' }
}
