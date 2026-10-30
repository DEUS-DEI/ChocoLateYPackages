# winget data of this package: update_all.ps1 prepares a winget version for each version it publishes to
# Chocolatey, and only submits it when WINGET_SUBMIT is 'true' (README, "winget"). {Key} is $Latest.Key of AU.
# The manifests always come from the *.yaml templates of this folder: Komac takes Mozilla's installer for a
# portable 32-bit program, so "komac update" would write a wrong manifest. Like Mozilla.Thunderbird, en-US only.
@{
    Id              = 'Mozilla.Thunderbird.Beta'
    Version         = '{AppVersion}'  # 160.0b2, as Mozilla and Apps & Features call it
    Installers      = @{
        x64 = 'https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/{AppVersion}/win64/en-US/Thunderbird%20Setup%20{AppVersion}.exe'
        x86 = 'https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/{AppVersion}/win32/en-US/Thunderbird%20Setup%20{AppVersion}.exe'
    }
    ReleaseNotesUrl = '{ReleaseNotes}'
}
