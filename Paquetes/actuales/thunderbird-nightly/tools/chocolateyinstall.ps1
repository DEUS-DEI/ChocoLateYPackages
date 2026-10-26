$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '161.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/10'
$build   = '2026-10-25-07-52-10'

# Package parameters: /Language:es-MX  /Arch:win32
$pp   = Get-PackageParameters
$arch = if ($pp['Arch']) {
          # Mozilla's names (win64, win32 and the old win) plus the usual aliases (x64, amd64, 64, x86, 32)
          switch -regex ($pp['Arch']) {
            '^(win)?(32|x86|i?386)$|^win$'  { 'win32'; break }
            '^(win)?(64|x64|amd64|x86_64)$' { 'win64'; break }
            default { throw "Invalid /Arch '$($pp['Arch'])'. Use win64 or win32." }
          }
        }
        elseif ((Get-OSArchitectureWidth -Compare 64) -and $env:chocolateyForceX86 -ne 'true') { 'win64' }
        else { 'win32' }

# Languages of the installers of this build, from Mozilla's manifests (block written by update.ps1)
# <languages>
$languages = @{
  win32 = @(
    'af', 'ar', 'ast', 'be', 'bg', 'br', 'ca', 'cak', 'cs', 'cy', 'da', 'de',
    'dsb', 'el', 'en-CA', 'en-GB', 'en-US', 'es-AR', 'es-ES', 'es-MX', 'et', 'eu', 'fi', 'fr',
    'fy-NL', 'ga-IE', 'gd', 'gl', 'he', 'hr', 'hsb', 'hu', 'hy-AM', 'id', 'is', 'it',
    'ja', 'ka', 'kab', 'kk', 'ko', 'lt', 'lv', 'mk', 'ms', 'nb-NO', 'nl', 'nn-NO',
    'pa-IN', 'pl', 'pt-BR', 'pt-PT', 'rm', 'ro', 'ru', 'sk', 'sl', 'sq', 'sr', 'sv-SE',
    'th', 'tr', 'uk', 'uz', 'vi', 'zh-CN', 'zh-TW'
  )
  win64 = @(
    'af', 'ar', 'ast', 'be', 'bg', 'br', 'ca', 'cak', 'cs', 'cy', 'da', 'de',
    'dsb', 'el', 'en-CA', 'en-GB', 'en-US', 'es-AR', 'es-ES', 'es-MX', 'et', 'eu', 'fi', 'fr',
    'fy-NL', 'ga-IE', 'gd', 'gl', 'he', 'hr', 'hsb', 'hu', 'hy-AM', 'id', 'is', 'it',
    'ja', 'ka', 'kab', 'kk', 'ko', 'lt', 'lv', 'mk', 'ms', 'nb-NO', 'nl', 'nn-NO',
    'pa-IN', 'pl', 'pt-BR', 'pt-PT', 'rm', 'ro', 'ru', 'sk', 'sl', 'sq', 'sr', 'sv-SE',
    'th', 'tr', 'uk', 'uz', 'vi', 'zh-CN', 'zh-TW'
  )
}
# </languages>

# Preferred language: /Language, then the Windows display and regional languages, then en-US.
# Mozilla uses both full tags (es-MX, pt-BR) and bare languages (de, fr, ja), so for each tag try
# the exact tag, its base language and any variant of that language.
$requested = @($pp['Language'], (Get-UICulture).Name, (Get-Culture).Name, 'en-US') | Where-Object { $_ }
$available = @($languages[$arch])
$language  = $null
foreach ($tag in $requested) {
  $base = $tag.Split('-')[0]
  $language = @($available | Where-Object { $_ -eq $tag }) + @($available | Where-Object { $_ -eq $base }) +
              @($available | Where-Object { $_ -like "$base-*" }) | Select-Object -First 1
  if ($language) { break }
}
if (-not $language) { throw "No Thunderbird Daily $version installer found for architecture '$arch'." }
# Also warn when an explicit /Language gets a variant (es-CO -> es-AR); the automatic choice stays quiet
if ($language.Split('-')[0] -ne $requested[0].Split('-')[0] -or ($pp['Language'] -and $language -ne $pp['Language'])) {
  Write-Warning "Language '$($requested[0])' is not available for Thunderbird Daily $version; installing '$language'."
}

# sha256 of that installer, from the same manifests (block written by update.ps1). Every checksum is a
# literal: Chocolatey's package validator (rule CPMR0073) rejects a download whose checksum it cannot read here.
# <checksums>
switch ("$arch/$language") {
  'win32/af'    { $checksum = '98c443b6037b21bbfabcdb98c2cb7855a152de0a53760499f035de643c42aaff' }
  'win32/ar'    { $checksum = 'c987990c776caf8bf0aa5345e9562f98150e9f0824df1f7260fc6023ba1abc04' }
  'win32/ast'   { $checksum = '568978d9535e824b8f142ef4512955a45b86c6c7fdbe7d30f29156467a79cfee' }
  'win32/be'    { $checksum = 'a4fd8c9c7d75b43828a8bc8ad91a2f030f075a1c56d22bf3c2cdb25d57c5140d' }
  'win32/bg'    { $checksum = 'd9a15d3037aa8f0469e32254475125ffbf675d645d34b7fee8ffd839fa3c9039' }
  'win32/br'    { $checksum = '38994ff56cafb99fe7634903051d784247b8812400c536829076ca38c193a53b' }
  'win32/ca'    { $checksum = 'e39f27e8fe92cea902e4bbcc925298d112c3091a7b7826c0efe7e0db9d8cf3cf' }
  'win32/cak'   { $checksum = '1ab642fd3ec7c65704318c00f17df2d51995ba6ee6b90671154a4d71e3933605' }
  'win32/cs'    { $checksum = 'effa912e34b0cbf957a064bbaaf77a7297350c439d3359fccbd8179c13fc39a8' }
  'win32/cy'    { $checksum = 'a62fc2ac64e9d8a5c70e5e7d17201632e5f0ab4113adb9f578d24beb5ef9431e' }
  'win32/da'    { $checksum = 'dbf1861160a1e6dcb0fa9b47489197660c5fcdadb4c4449fbd033a1d597aca8b' }
  'win32/de'    { $checksum = '8315484cc68bcacb72f893a406ddba1c81b54118f41f7069d4f5b8b61340284e' }
  'win32/dsb'   { $checksum = '7d281b90f8ccc43e4146d6e185ac598a9398ebf5c52db68b51d4f19156c4221b' }
  'win32/el'    { $checksum = '736ac800c309d66bfe707b5fcb26bd698d5d9c9eeac7be53e082869f904afe85' }
  'win32/en-CA' { $checksum = '8426a74b01b262c4633118669a98ee4566735e8d9b850a02df562ddc1c00368c' }
  'win32/en-GB' { $checksum = '1fde115647059c14bbcac014030e4bfc242b5d7434c4e75f0caaceaa3fddc6a3' }
  'win32/en-US' { $checksum = '801f7e66b8a110f534f8b721c1c1d7e5be303d87e7765b4e3bc4767bbab895b4' }
  'win32/es-AR' { $checksum = '699ddcaa9520c58594f36f7bebb8e0c5cdc3dc56207bdcad8b1d3f474f6e5515' }
  'win32/es-ES' { $checksum = '0b26ca6562f6a1d3370851de897a6655cae57c48036f28ff1a28c827de4134fd' }
  'win32/es-MX' { $checksum = '3b2a6670839f7de285ce04e4d547e48115bfa187ae8f44eacf3fd77c1b839ae9' }
  'win32/et'    { $checksum = '06753c6617c2791611614cf412c7660af0d2c00d990e7f593641012362a0f035' }
  'win32/eu'    { $checksum = 'cc629eee71926dc9e3cb0538af9213fe2052c87d9bbba1862b92b155b54fefcd' }
  'win32/fi'    { $checksum = 'fa6cb63c4373618e5fceaa895b3ee23644fdf65c279c15d7fede4fcc6c458124' }
  'win32/fr'    { $checksum = '17020d7ec978c30a60b00b137f231256502b3fe489957f59fa2848d6544cee15' }
  'win32/fy-NL' { $checksum = '701537cac134d48f8142f5d1520ad36afceb19b3853c966d647d539e670baeea' }
  'win32/ga-IE' { $checksum = 'd26599d3fd466479ee37ff5fc22d13b48cbfd9b12cbfcd2d8386c5f4b097af6f' }
  'win32/gd'    { $checksum = 'beab79437db59b82c9508811ee786620159b5bd46037549af59079f8446fa23e' }
  'win32/gl'    { $checksum = '0e6523c84925b8e67fdfa3e26fb72b6e31c5e35663d2e29d896094498651c120' }
  'win32/he'    { $checksum = 'dd601e5ae204d2c726d8bbb5c869470ca504885a7106b346e7164e672c3303df' }
  'win32/hr'    { $checksum = '53da7b00f58253504760afd2f6e1b4b26f91bada8c8b51b857f61754becb2366' }
  'win32/hsb'   { $checksum = '75017018b7c0af1b4633803ef227132fac40dd0ccf588b2b948fae29d3bbb680' }
  'win32/hu'    { $checksum = '732f297a460b42eedb212f2c1280dc597755dbab32f54e81d84e8f8642348354' }
  'win32/hy-AM' { $checksum = '43d585d542cdaa09fe4ea6fb4d3757f67b3337df4f65cbd6c1b6fed8d271a32d' }
  'win32/id'    { $checksum = '46808cdc52a4684b2dfe08461222fad7c3018a922115884f5d8c61593b4af5d7' }
  'win32/is'    { $checksum = '8169ff0eb9253c0911ce01200a796c6d31cd47f7ce6c8e47eb68d2b1cd0facfe' }
  'win32/it'    { $checksum = '5c69929afbdce30d8dd48906aed7e6d982fe0998b6c11716545bd4c5fd840aee' }
  'win32/ja'    { $checksum = '398f17547fca0686ff909f4f542867fa0dbe25cecde9c3753164edfb077e0e31' }
  'win32/ka'    { $checksum = '08a28dee391c0dc5cd6568c057efed994378fcccf6e670b60370192353d8236e' }
  'win32/kab'   { $checksum = '6d886d46cda9d47940c6a1e53ad7b239bd082f56e48a425306ce1e07ce9021a3' }
  'win32/kk'    { $checksum = '1f1532d648949c6e3fa678cce914a27f78780e300cdb9ea55af000ab4f2f58a4' }
  'win32/ko'    { $checksum = 'e0c63e8d76eb7f89f9fe7e6ab3e0bccd81c0ec6d603042082ea040d55c04934e' }
  'win32/lt'    { $checksum = '4cbb2cb3a7b1859df0f06619e0b19d69ece686e84dfc3a9b647caf93f3a21cb1' }
  'win32/lv'    { $checksum = 'fa229b80fe5d547ac1f37ddc078f7ff2356cad6ee13e0b54d9fea6428dd713d1' }
  'win32/mk'    { $checksum = '1bbe18dc95b2f6ef122fec0499d0d293f95d95889fef4779285e91d216b3e059' }
  'win32/ms'    { $checksum = '3cd595b848d1bd4ca28a05e287525d3eeb7b1c5b18a7b9f7af5b2613fba75de9' }
  'win32/nb-NO' { $checksum = 'c8a1aa1c04b20534980acb6ae9dc2538b6c229d8740b54bdc18a545926928dc4' }
  'win32/nl'    { $checksum = 'b0a4a31ddf3a2d66694ed5200e411cfba536c5882e99bbfda63036f83c5978eb' }
  'win32/nn-NO' { $checksum = 'd74be41ff6e34e8cda2c66bdc88314b7a5118074b8e995f418a5130f947386db' }
  'win32/pa-IN' { $checksum = 'b3519f2e281e5167c491941076deb8552e5f2c49fb8a845f87fb757b3673e4a1' }
  'win32/pl'    { $checksum = '00a541e2cbdde8edf02aa1fe828236edcad9420ad0471b29a1610bc5ce243900' }
  'win32/pt-BR' { $checksum = '2f6dd891fa5813ee141130a0e46f4251227ab1f84b4bf7d0901dc5a8a5d87a6b' }
  'win32/pt-PT' { $checksum = '4701eb572aea6e6dccaccb4ddd5f68c13edeeb0399204564e908909f12966421' }
  'win32/rm'    { $checksum = '97d0839229321fe22cf70a712bd3c0bc42be81e09408a209b6acb8c5adbbbad5' }
  'win32/ro'    { $checksum = '9f7bd9dd62052e4f8f1069a344437ef1c333a3cb9dba72f70ad55f430507e744' }
  'win32/ru'    { $checksum = 'aab02d3f2dea446a2574c79269418211bf0c670576cdc11e65240afab7ce9a5c' }
  'win32/sk'    { $checksum = 'c70d38fd621b9b42fb5f17ec5e8576f3577d9986b5c8d3c6a3907bb70a054d36' }
  'win32/sl'    { $checksum = '35e704e69275f7b9df4af128bf89c3d89fa93f3bae9f10ac15b05439c4e74edf' }
  'win32/sq'    { $checksum = '442eb2fa3a4ee0d1acbd542d6caaebba4f6aacd35ba031503845a2c3fba1a08c' }
  'win32/sr'    { $checksum = 'ce4e06d9c1f801fbdd432ee623bfd4a2eb185fd8f9d107b0ca4e73f3b83cd884' }
  'win32/sv-SE' { $checksum = 'c9e0a320dd901a7b541ca6078dc9e08df1bcb6f61791d2b82191ce7d08cef714' }
  'win32/th'    { $checksum = 'd951fc0dde5ad82f80196e6cd63487569765ff63276c07e403137797b3c36097' }
  'win32/tr'    { $checksum = '1d2c1915c2885aaa1ac9d85acf0323a83b38f8ecc3a7998d14eca18e1368bada' }
  'win32/uk'    { $checksum = 'c20213ebea2296f8e24bb2fe2b8fc10bd3a6e90a3fa505fde6d6ab69d67ebbe2' }
  'win32/uz'    { $checksum = 'd2c94d1d5ca39ce67539720a1849ba9015275c68cffe5b9ea8faab5c4690ec6d' }
  'win32/vi'    { $checksum = 'cfab6fe03fa0b0f7fdbd29e8d6e9b6732819aea3d23a17e7dd7f852c64efc681' }
  'win32/zh-CN' { $checksum = 'fb361ba494ec707dd9cdeb79aca0f69a5f97f63a1772cbdef4bcd25865eb7d90' }
  'win32/zh-TW' { $checksum = 'b8f7b91671acf8e91b8410a976fa2d7f024ed953b6586e91f34224f169e03061' }
  'win64/af'    { $checksum = '4037cb84bb6ca07c0b040bb3cbd3f9ca8216349fdf06430d9581c1c0285349fe' }
  'win64/ar'    { $checksum = '23efa1c1c79ec63bacd868c412fdba3306740c96e0e6ee69bb959f7c6327d7c8' }
  'win64/ast'   { $checksum = 'ffb95cd83364c9f612d05b3e03d2eb07809ce5c0f79dcd77d1a1c359df4206b4' }
  'win64/be'    { $checksum = 'a25cb55f45b7d3b8ceee448d3db726b9c733dbd7594bf824289dd92709f3a583' }
  'win64/bg'    { $checksum = '63877c42e58d1faf1d5db1fe210d65ffc0457195e1898ef89f5a140edc18504b' }
  'win64/br'    { $checksum = '81b1d11dac0c10cdf8e56d782e4aaad92c2135be72c1cfd66ea9a79e7804b7c1' }
  'win64/ca'    { $checksum = '5fb96997cf03197322ace82504396a9c9d2414bf5ec045f3d8f140f281f50fef' }
  'win64/cak'   { $checksum = 'fc4d6221486dd48a6b93b4efa8af5ae50aa0c0433b39e0d59535b2a8622ed6d4' }
  'win64/cs'    { $checksum = '514f25515056aaec5492499fdb551917347474e573c5705675ae09e90b455976' }
  'win64/cy'    { $checksum = 'eb6f8084e014e5cf3c87aa42014fb98e99e5c28422cd695f99a70648f5dbf3e4' }
  'win64/da'    { $checksum = '7f3d42e87a04a7f1b041b90f68fa13d6a7e29804cd031533678c2e118517a2e9' }
  'win64/de'    { $checksum = '8b2478a265c172e4c9eaf53a39e418e5308ae0df64a4cd9ed581e742608880e9' }
  'win64/dsb'   { $checksum = 'ecf74a186dfa751affa6f53a52ae7bae87e6e7236dc758353c1a062898c6093c' }
  'win64/el'    { $checksum = 'f6724b0ed35c79b7d72ebf694b640822c0c4f6301e940fe92b9296c9220451e1' }
  'win64/en-CA' { $checksum = '412952b4d9af8351d16633cb62a1dbdc691861098848060b834a1eaf2314e6cc' }
  'win64/en-GB' { $checksum = 'f98321e17dac505fb4e0cc578ea2625005543cd043464cf4a30a4fae2cda90eb' }
  'win64/en-US' { $checksum = 'd78b9f4ad79d14802f03846cf342b87258425d6921442354cd1c48a60bfff179' }
  'win64/es-AR' { $checksum = 'fedf9c98d8e132a20db566cd81938d75987f26cbef9805a658100a80831612c8' }
  'win64/es-ES' { $checksum = '9196d80449592aa47e9ed42ef8b740205ffebc18211a3d4bed9ea99f4b6d86d9' }
  'win64/es-MX' { $checksum = '07e1f97a1183aba371c8eba7cc8da290b43b749ca448c289171a4b1721fe49b1' }
  'win64/et'    { $checksum = 'ecc9618a5176159654d2bb4483ceff9e9431fd11088f0925eaaa97f9ceeb4450' }
  'win64/eu'    { $checksum = 'd9d1249d21acf96749aad0a846d6bbb3c88da0a36d4bfbd3fb6cfddba84ace52' }
  'win64/fi'    { $checksum = '195bbe87e5300425c42680ab3f3d9b7ce79639b254ba8912943e3db0867ac797' }
  'win64/fr'    { $checksum = 'fdf37a28c941dfb0dba158406744a8ca8a90f678750908286d28ae1baf6fe181' }
  'win64/fy-NL' { $checksum = '1c81642c531de0e60984ec0613948f492345fc57bd3ff607fe0501eb8eb0a239' }
  'win64/ga-IE' { $checksum = 'c017fe2affb84a191e2cb89010357ac38013548542687305e9bb7a07ebd5d17d' }
  'win64/gd'    { $checksum = '923397a00d104157e104e7df12602c41a00eacec2e8febd94d5061f3e12c71a5' }
  'win64/gl'    { $checksum = 'd50b1a5e668b8dc184196739f98cbe26ce254cbe733b2983322c833e67a0026f' }
  'win64/he'    { $checksum = '573025567a1a4a1f76d9ca6b986d538d468f8b8e58b72994686705ceb7c0dbd9' }
  'win64/hr'    { $checksum = 'c59171136226d7999dcbb7922b6470e914f854d5c15fb9024945204a7edeade8' }
  'win64/hsb'   { $checksum = '6540b271f0207a8853e2bd59732a36bf957a7cefdcd9384066a42eb01573ff6b' }
  'win64/hu'    { $checksum = '21426b4bb0d014e3e431dfedca5c4d6f39da93d4ac4d8e703b4e687b1cd119b2' }
  'win64/hy-AM' { $checksum = 'e868d2478a264c10cb5ddc83b99e15d50236f9e6063d23c935d0a969b4666161' }
  'win64/id'    { $checksum = '36533454fa0f174a0a0b0811f2cec5d791a84eba5a6b93b9fb600f35424494f4' }
  'win64/is'    { $checksum = 'fa03d3c918d0b5ee7757b1f99d50ffd77aabb486e69f3d321c853567a3fd3ae2' }
  'win64/it'    { $checksum = '4ea8277d040c45fa8cc8c144b69e49124d07101a5569e7495213eacf6f7fb8ec' }
  'win64/ja'    { $checksum = '3e207ecbb58b092ec57e3e4266efda407c6dd7f2ad2ffc976022908329e0e692' }
  'win64/ka'    { $checksum = 'dd1f5cdbb74c2b08d65b071a24f10e1a9fd9e955371bc03961b9e4188a4a1ced' }
  'win64/kab'   { $checksum = 'bee76eb2b79e16abff49238f464aca7f6b3b68a9085cef5a17b2c80483a02234' }
  'win64/kk'    { $checksum = '0eaefaaa6a5b2dd5560b6fb12c0517b3ce94efb886de4a9e8ecddfbb36fd6d69' }
  'win64/ko'    { $checksum = '20026a99cb7749209072f81ae18f219ba50f0e5343e10d8cde70c512fe94ee0b' }
  'win64/lt'    { $checksum = '6e153a458b13ff3f950df47172f149ea6195e169abf57fee56089e601e5c58da' }
  'win64/lv'    { $checksum = '9a66db43341790096bc8e48e247775eda9d89010020bab133e696d62a171946b' }
  'win64/mk'    { $checksum = '3b02b05f669ccbeecefd4242ea094bf82b0b43e602e1b7156b02de90bea4e63b' }
  'win64/ms'    { $checksum = '39b7c975b75c79a13df6398d794bbcb258f6ba4f335f497a9aae7b9bc0cb53eb' }
  'win64/nb-NO' { $checksum = '7ac0885e217237208c9085834a4214778ef3e5ec048a91bccf96245696b0404e' }
  'win64/nl'    { $checksum = '156612fe7b54367541fc421043cf9d89cad11a2fbc98b2b2e9430e3efb5849c4' }
  'win64/nn-NO' { $checksum = '6ce40a8bfc6eadd2ccf2175a964344b2ac4ae0e5b1b7d06e7c9d3a3792b15a02' }
  'win64/pa-IN' { $checksum = '068de3347d461521987767c4b2a576d035f7641e95ef41d8a96b21f866745cf7' }
  'win64/pl'    { $checksum = '0afc9e1b974b2dd759916ea73abf05cb7e0e98d4b7c97e45e405835ea31d5cda' }
  'win64/pt-BR' { $checksum = 'fb84bbba1d9c4d912bcb3673b68734bae12c77acf3b4a221c0fdb56a12ead9b5' }
  'win64/pt-PT' { $checksum = 'e75282fd3f991d34bcb04f569d6f7af4b98671981a4d5103e2af955eb9202064' }
  'win64/rm'    { $checksum = '5c31d73ca2d7c66dc01b557c0b7b118b1954b521db4b63a63e460957a7453769' }
  'win64/ro'    { $checksum = 'a09d7a1b2add7f165ed555d47dac09b3c49a488535ba44454932bdbbf5a0f667' }
  'win64/ru'    { $checksum = '504a190840af4057d3ee77cf5b774a1bae1808f9887c3d9650bc48b38d274802' }
  'win64/sk'    { $checksum = 'fe9b46ae41869c9023b9c4a05d15265840fbe83d7b48ae5a09f0a6ae27308a14' }
  'win64/sl'    { $checksum = '460dee3e8031739102ec3ce80a2779c22a673a05db0868b8695f4b8cf276227d' }
  'win64/sq'    { $checksum = '3609e205d0aeb00c50dc9dc4e465e8c4fc6c25fecb8a8bfeccc6ff09784f3c0a' }
  'win64/sr'    { $checksum = '72a28bf59de197083aba771f86068bb965135e4441ff4c52cd8a22566a9d8630' }
  'win64/sv-SE' { $checksum = 'bfa2a296c46783a2d79a1d7318f12e327635e989e7d18cd0226a8c97ea72c94b' }
  'win64/th'    { $checksum = 'b4e1a6ecda7b92941955e79ec1a61393e7663e01306c1419a2f89e41ae1fd986' }
  'win64/tr'    { $checksum = '2b624116b68fb1f262c765ffe9b3c9b1ad7b004a6ba33b34028ddfbcc15bc57c' }
  'win64/uk'    { $checksum = '1368a7ffa85cbef17556208514a9ebcae0f986b72f6c60f63d284e312321fa6d' }
  'win64/uz'    { $checksum = 'd4556db74c478f456bc29760007cb3deb58914ee044dd316cee122fa018e4e18' }
  'win64/vi'    { $checksum = 'c4b18e8b01822d9c5735d743026599761bd3808e090147b10a73c7fbf1ebee18' }
  'win64/zh-CN' { $checksum = '47f654416aed3ef0ab44dda2cb39d054961fc9c45684f8c235764a77a598e580' }
  'win64/zh-TW' { $checksum = '5079d770097d8edb6a4660fb0d17dabec539486e2f8b485d5a9c33eb382b4681' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
