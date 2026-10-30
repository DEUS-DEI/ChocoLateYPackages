# winget data of this package: update_all.ps1 prepares a winget version for each version it publishes to
# Chocolatey, and only submits it when WINGET_SUBMIT is 'true' (README, "winget"). {Key} is $Latest.Key of AU.
# No templates in this folder: "komac update" makes the manifests from those already in winget.
@{
    Id         = 'ArtisteerLimited.Nicepage'
    Version    = '{Version}'
    # The full installer, the one this package installs (Nicepage-<version>.exe only downloads it)
    Installers = @{ x64 = '{URL32}' }
}
