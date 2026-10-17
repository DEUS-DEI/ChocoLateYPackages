$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '160.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/10'
$build   = '2026-10-16-10-44-33'

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
  'win32/af'    { $checksum = '8e23ed55bee4da1691bc4260c869a53d43e0085f9f91976e70a73c4afdbd87d5' }
  'win32/ar'    { $checksum = '495a790953f55c64d952647f28cc630080fef4051ae71235f7fca7044bb16a98' }
  'win32/ast'   { $checksum = '8512f8b8986d4e772b5a720f31092bc300d9349ec5b438130d8d1545c6ec69c3' }
  'win32/be'    { $checksum = '155d44546504ed9b10039f6229c0fee39c59222d1f251db433bbd6e5bb6b65fd' }
  'win32/bg'    { $checksum = '7696fe321026982fa3de01e08e2e62a9a8ce628a442f3036f47cd3448789d6fb' }
  'win32/br'    { $checksum = '9784e5f297dcc3bf31ddc48da7a6f5d6de67ea36588a2706a07172b54a63fcb6' }
  'win32/ca'    { $checksum = '1cfaf403e4c7a186f520b360e404551a3a655e6b5334d76e8a8fc58539115d21' }
  'win32/cak'   { $checksum = 'a598ba378409266bbe0c3704722766f6b7f770ae4c4d9eff13247c3c8996b934' }
  'win32/cs'    { $checksum = '74a1e06e41bf1fd5905f89769a39a75bd1251ab42c0185aeb9f1e69538eaf554' }
  'win32/cy'    { $checksum = '34a428c8e44eca45b174fc7e161bfea9b26e63d74f4fd4cc1d38ef43c3d79ad1' }
  'win32/da'    { $checksum = '4adc318148661a6a9f47bb4d226618631d69ac5671ca2d507b36030fcb3cd44e' }
  'win32/de'    { $checksum = 'fa951e3cfc45d6b5d2924b6aa463b328c22f2a76c1515ca304d7fecd6b77ecf2' }
  'win32/dsb'   { $checksum = '81345e119fe607b953b441ccb5ab2628d8bb582eeb7e8f70c8769766e8c0c84e' }
  'win32/el'    { $checksum = '30271c4ae5a035fb84e4e58c62a3def7db15de67036ee5d806243dde65095f1b' }
  'win32/en-CA' { $checksum = 'c5e96c8f74a38d5e41ade47521cd096500d97ce6a74d00b4380de082f68366ec' }
  'win32/en-GB' { $checksum = 'f290070c1e5153c0427c53f283383843cf23ff05452b43a776e18b40faf1acd9' }
  'win32/en-US' { $checksum = '37f7aceef873800ff7cd517167f14509c8f30eb1415cef2142f6360fa09f447a' }
  'win32/es-AR' { $checksum = '25ea114c9423777d8ec0d597f1b4b2ba2b266849368c56c657b17d8cbefe0368' }
  'win32/es-ES' { $checksum = '845da95a939d8889530f165a7798b154be994fa21af6784e212597e3080cb5b9' }
  'win32/es-MX' { $checksum = '0e0c78d97642ace65c7c53efc907c760fab2de0cfc3246d42838359b38351c52' }
  'win32/et'    { $checksum = 'f2477b19acdfd824703b15e41313cc2a932fbead2d58deaea43c215668c96f77' }
  'win32/eu'    { $checksum = 'aeec903e4259e2a519aabb26697673c0d2232e0ceb56ddc38617c2ddc4871e07' }
  'win32/fi'    { $checksum = '58d6d0bacac5bb726c908943eb074a19514e7bba24ef6e1d78a357d36510b667' }
  'win32/fr'    { $checksum = '551dbe35d43729b30ac4a5294a37b67f31a367a7dd9c02031637a6f20dbad724' }
  'win32/fy-NL' { $checksum = 'e4c7802c50cd9e28b18f712dbd24a8efaf4458c133d2b99948c62afecfc57695' }
  'win32/ga-IE' { $checksum = 'd2cb3f55595253922aedc2b8e5371a78502df2ac32c418fa209910dcee0c1361' }
  'win32/gd'    { $checksum = '4626a31963a46d1233d491327a51c478962fbcc32d337d8e2cf3cd67590fa462' }
  'win32/gl'    { $checksum = '8c77e3ce1bdb39398c75540de2e1eeec99b00c59c466ba697969cad11f8c6a28' }
  'win32/he'    { $checksum = '41215c8a3fe49f128deb75cd02e3996fe5a0b76e1d1f1bb8b5ba19e0dfdefda0' }
  'win32/hr'    { $checksum = 'afbad054610bca9c5687ff5d8267e963f84e4d578ed04a25f7ddce67996829f4' }
  'win32/hsb'   { $checksum = 'dee40bf9e001eb93158c493d6fb5870357c73fa86afd1c27f42d0098c27561ed' }
  'win32/hu'    { $checksum = '45282560d07b4da64dab277ee0fa3f556c11d8ec2cf77e80497d35aaf909c1af' }
  'win32/hy-AM' { $checksum = 'dc1a1a31b09905d9d0df347a29e647b9699f9d39526b0c936303fd7279d219da' }
  'win32/id'    { $checksum = 'cf5f70c0cd991075bae8979d6295df3c7d17760a5c78d8cfaec870aaa69c3794' }
  'win32/is'    { $checksum = '1582243b64d557f9d5fd44e78d129bdf827a74740c719c42bfb8eafccf2fb339' }
  'win32/it'    { $checksum = '110f2966773a187954ad84a5778b37afff67ce2e59aca738fa3bd108eacb5bd9' }
  'win32/ja'    { $checksum = '27437b091462af3770be33571bb61ac7ab5201b2641462e08908f609d4fc664a' }
  'win32/ka'    { $checksum = 'f3b745a11b023c83e50d9d9378ed948efc5a52634a3f6c5123b66a1fb9753e44' }
  'win32/kab'   { $checksum = '23716b7ffcdf0bca85aa00f847afb2f1d3a8faadab108d27b5febcadde422178' }
  'win32/kk'    { $checksum = '4dfeaee58617954f72033f87121bbe308db371422bcc5865428b564b9f709355' }
  'win32/ko'    { $checksum = 'e54352664c38973a7abedf3bad8d5b78d1aabf7331921afa53ca28eb6812eced' }
  'win32/lt'    { $checksum = 'a13bb27fe1f593250cd063f822a4676d74de05c35d5ff8a7ed74af5a658d3cf6' }
  'win32/lv'    { $checksum = 'e13a8206478d272f7b042c70149de06b9e9786bc98669cf38c3e656445415195' }
  'win32/mk'    { $checksum = '33c342260a521eb0ef903fb83cc744c4d9c0d972b3e7624df4fe4c34fcb05f12' }
  'win32/ms'    { $checksum = '0d27ed1b9d2977e6ef81fb9d6c70cacd58ca173e976abd39242c43e7114f9fa0' }
  'win32/nb-NO' { $checksum = 'da1eb9f69cb5e99c389ada5026418936367c6b1e84a70ea31a2cb6a3d7beb278' }
  'win32/nl'    { $checksum = '3e04301eb9d523feb77bcd5bfeb73ebf06fe64460b58e32e14c00b194d12c149' }
  'win32/nn-NO' { $checksum = '09fcce8704eba0b33cc6422a129cc499b64fb0cb7474d98d3f6d10cb14957d5d' }
  'win32/pa-IN' { $checksum = '3829cf4ab7095a664043aa7ee6fdcda30503682054250b246a85790358039035' }
  'win32/pl'    { $checksum = '2d8e6c9fd98b368956fa0e6b711267bc615e5603c301a6c505fe99560065fc7e' }
  'win32/pt-BR' { $checksum = 'abfe89e6f5cebfb847536fd20a98629149a25f3afc727969f7b34189daa22dce' }
  'win32/pt-PT' { $checksum = '2f3b5c0d263c2aff78f1ee2bd2e4fe0ed57762ef5871483fe0c8e7b0a69581e8' }
  'win32/rm'    { $checksum = '6e3e3fc90d8d970607d7fc77ae350629d6ee1c64fcac7a1db8edddf023e60cc0' }
  'win32/ro'    { $checksum = '035dc0f2229888ff47d6b07a2e74d838872b4e0ea36cba1788103c49983a2b53' }
  'win32/ru'    { $checksum = '60466c517d8c699379767f82fe2a72e6ccb7fccd3a754471197345585d411d51' }
  'win32/sk'    { $checksum = '1b6e2399aabf478370eafe16e12779c03bbc87cfa15b0d523f7f1f5ac686c3cf' }
  'win32/sl'    { $checksum = '89e1f904a7ef5162e4827663dc9545a3fc0f889ec0802f5c10b66f18dfa61aaf' }
  'win32/sq'    { $checksum = '0fb3ae10303eee983c2a31d8680c65d56303a7777c39802e0bff58f6aaf1dd7d' }
  'win32/sr'    { $checksum = '1c1e63c41dc294fb4ab6e9d675c0c42eee793485a96f0df556e49800aa7a8ec4' }
  'win32/sv-SE' { $checksum = '232f380c2e76fbae3bbbe7d19d297d1eb97effc06a6712733a05156fc0deb3b1' }
  'win32/th'    { $checksum = '71dfe5854ecfcd5c18695019a26353b87b5b420f590ea148d6b2374a04cc1da0' }
  'win32/tr'    { $checksum = '06239aaa44b8c22c4789e3cca757c3fb2cd6446c2024b567484991a8669a3ba3' }
  'win32/uk'    { $checksum = '26fe20586000c4df5cc2ff66cf3ebb34ae440be4330ab19f8d90fe4468d0bcf7' }
  'win32/uz'    { $checksum = 'bcd135c24990dd2fbb2addea43a5dee4cc0447e53ced6d521323c12675df20f6' }
  'win32/vi'    { $checksum = 'a8635b6e20168fc3f5cdb5afe00e5c78ca0e7902e705245ece0b7c3e98c8f003' }
  'win32/zh-CN' { $checksum = 'c0a78ab77dbbf153e8a23bb6f83c397823193dee014006bb7e831c6570be659e' }
  'win32/zh-TW' { $checksum = 'd8409f4190636ee9e8bddf58abf27a451c8f84e37d6e123de471524932997973' }
  'win64/af'    { $checksum = '2a95c1a21b0d3661c61ae8ac0f7079bf5ca1929d30497c9a1a7844c1f9988953' }
  'win64/ar'    { $checksum = 'f3eac9d78cded5869cff8a7f2e01163dd0ba0f98ba17eafdf716b933c83af680' }
  'win64/ast'   { $checksum = '5e7dbce3340660e75565a1fbd1923568f21d7a8b21d5498b4ebe1c9e52aa6c22' }
  'win64/be'    { $checksum = '5d0ad4c2ae3929e5179c15fec4d218551cd580cc9c5fe371ae3e6469252148e6' }
  'win64/bg'    { $checksum = 'c439a970bbb04f03b515954588475e84aaeacaee7d663c5d89c93ba633847764' }
  'win64/br'    { $checksum = '53d1f217df26df35b05645087b2750c2f519e6bc94ea36361d79c8b7b450e8ed' }
  'win64/ca'    { $checksum = '8a3cb6f10f8023c20eac57685d484770318d76290f036764087823375bc3f0f3' }
  'win64/cak'   { $checksum = 'aea32e61c2b544906d117d5c5283b7e4a8ede0f9f56c83c921c2a648cb062912' }
  'win64/cs'    { $checksum = '08983d229ba11b1c1954a9962a5db9515a55b4e5e8cbb9b60cb32ea7549ba3ed' }
  'win64/cy'    { $checksum = 'cf9c572bb2dc12d6b0a5c297509b213f9bbe28696855de737cf3a0072c6e3245' }
  'win64/da'    { $checksum = '0db07abad01088f0279e277cd99d316ef143e79bb4b5f642ba972103977c576b' }
  'win64/de'    { $checksum = '7303529a1a0fef8b7e08350ec757be62b796fa28e226165cee4a58c3d3b409bf' }
  'win64/dsb'   { $checksum = '2f46a48cd76fc9cecfcf3b10e3f517247e1a8114e73d9f4e12dbc5f14d96ac76' }
  'win64/el'    { $checksum = 'b9242ae9c8fb3851ac4e4f3281e92887dd9473d9e56adce0e7b3e303e11c963d' }
  'win64/en-CA' { $checksum = '1b2725cddc190df31b462fd847f73caa0ccaa7381af76492060d1f0c4b6a9a4f' }
  'win64/en-GB' { $checksum = '07defe73de113f34cb47956cbb242c64a66fbe4a20aed9330a8c88f061d56260' }
  'win64/en-US' { $checksum = '3a2542219a479a5493f7f7201a3e37e4c0ff9fe365f088f0a12db95181597119' }
  'win64/es-AR' { $checksum = '98871da0d5e6bcf74c77e80b96f8b2de987f4871de2256b163a398430091835b' }
  'win64/es-ES' { $checksum = '389b59fedcb4069d5b3204351cc56b406425721900ca351752ccdbb67468e8c4' }
  'win64/es-MX' { $checksum = '23d9c10e430648104c659e96e1799f80b8382a30a54aadf0c54189a1714cf799' }
  'win64/et'    { $checksum = '63bc60c51f303a6ff2caacbe4da2caa67894938df90827e4387ee5d523ce19d3' }
  'win64/eu'    { $checksum = '02e3ff269c4d2c091bbd693d9f091930abe3f5bac5e672f478e5e8d002704e93' }
  'win64/fi'    { $checksum = '1d851722b51936b106bb05b10602f783bf98bf101ffdd9f92af9389101fecfa6' }
  'win64/fr'    { $checksum = '48684c40fee9ace670b9f47eb7d313aa0d73b18caf5dfcd248bec2fbe567bfe1' }
  'win64/fy-NL' { $checksum = '760457843a9332c14971070019ffa3a87625295b6c65a640dcdd0d28b3d8e271' }
  'win64/ga-IE' { $checksum = '699f1dd8891eeb47c14bb811851911e80709c9fe0474b73229e85ccf987559cd' }
  'win64/gd'    { $checksum = '0eed3b2855604530ccb382d4b2eba2c82e59a646a34d71965001fda1d3fe9c79' }
  'win64/gl'    { $checksum = '045261c8556eae23c072ff383aa8ec25a752b389fada651102a1912f8d7a2c18' }
  'win64/he'    { $checksum = '52cc5058d026a877bb0ae467b349e0148a1764431f132d09a9259c2231c9f2b2' }
  'win64/hr'    { $checksum = '433a5391768279bf6bdaea075a993e8b22ea2b198f893294f183300c62596d0b' }
  'win64/hsb'   { $checksum = '0449db11c746a5ec076598e1d11886ab28617f14ca5d1adaae8f20df76f5d8a5' }
  'win64/hu'    { $checksum = 'a16b012c5b9823371d6b7409582ec780e92bbab2082f1f251d796afec4b256bc' }
  'win64/hy-AM' { $checksum = 'c3909c2bc75addac5bc6b39e83496314395744abf873b7b983da820f338d9103' }
  'win64/id'    { $checksum = 'd4313d4e3524586460d07477cb339efe154fd85a83fc9e353e3f832dd4d4a939' }
  'win64/is'    { $checksum = '0aeec1f18d8936b744bf9f6622548e9006fc7042b9f89081d0d357c91536c125' }
  'win64/it'    { $checksum = '5bfc0eb8150e5f00bd8de068c28c8162dd6482914509009046b4f71d4b103e4d' }
  'win64/ja'    { $checksum = '9424b88f2773df8b460542b43e5eb265146ea79b944b232940905eb2af265702' }
  'win64/ka'    { $checksum = '2e2338333cfe6542db9edf647603773b57e054c41e85eb0cf8c4291263b4a04c' }
  'win64/kab'   { $checksum = '6d81c739e0612edb51a375dab7c7118bee8036418ac003bb87723c0ee930ca52' }
  'win64/kk'    { $checksum = '856bfc426eae9c6cedf40921675774fb09bbebf6ab772c99361cff9f8bd75d99' }
  'win64/ko'    { $checksum = '0abb14c2bf79dae2f5dbc94c7bd21f85cf3cd95103620b30a2911a2a8e614214' }
  'win64/lt'    { $checksum = '513ac346b31a2ab08f57c19f5b44034fb306e7f822fb13dd831d7cfea1758b74' }
  'win64/lv'    { $checksum = 'cd4457d9b46bc50f3e07ffca7010b40aea136cbb366f7fbd51d8e209542fd36d' }
  'win64/mk'    { $checksum = '1b36b74cfec6d03f14dc57f3084605befa8c68feca0882af29a7ba61395a9477' }
  'win64/ms'    { $checksum = 'b2369df926347b95cbba9e6bd18ce6003877993094c2b09ae3f7043ee13b79a8' }
  'win64/nb-NO' { $checksum = 'ca8150135018afc13290ba6f02cc44740890011add0f2dc3886251db610d285a' }
  'win64/nl'    { $checksum = '735dda094af786b2b8b46801ad63f1dd71e8964fedf53b841a0324a28ac167d8' }
  'win64/nn-NO' { $checksum = 'b5c05b5e9979c5e124a0f33293376e8bb7a3c52e6281cda39362f10e29e543af' }
  'win64/pa-IN' { $checksum = '1f5d15c063892f81b080759151dcc840e2db3655f4099f06bb504372a954645b' }
  'win64/pl'    { $checksum = 'ce47d5f56855564b9b78db6d99a56054d57c76965bb660c9f8f5613e5eb86a9f' }
  'win64/pt-BR' { $checksum = 'd05c23e01f4a80fb9a94413768fdaa4b2ddab6d191ad714e4c85f98f5ed47f14' }
  'win64/pt-PT' { $checksum = '33fc2b3e50595fbc6a54802fb4fd776916e9105241ee60cea0da32541a3568ab' }
  'win64/rm'    { $checksum = 'aaedf593d0951ba1d03669bc2a8a32569ce5911436e736df8b4e1f18d87dafe6' }
  'win64/ro'    { $checksum = 'd145fd6d85df8d5d12ea706d56b2eab82114eeb5280cd60219a71a1770671d39' }
  'win64/ru'    { $checksum = '3c7321a56f4bb1ed9f01e15ed730408369fe845f4d2e208ea10402361a814b07' }
  'win64/sk'    { $checksum = 'cb27e5cf261397918a1043c855740ec818bb50171881c595bf3c9cbcda453708' }
  'win64/sl'    { $checksum = '68c29eb374c4a5c868282db9a70d6cc6a16174c8dca16764452bdd34796f7fa5' }
  'win64/sq'    { $checksum = 'da25456067b948fe583fbfbcd46edae85472632fdd2fd27ae4b23a34404d9f65' }
  'win64/sr'    { $checksum = '480a2456054f5e5ac60f90246ae46346617a5619397b7752c01b5f19ab39681d' }
  'win64/sv-SE' { $checksum = 'ce7684ed0ad3d0b1959c298c7203307b28b02f07a5281d2df0d1efb0aaccd6c1' }
  'win64/th'    { $checksum = '2c54f7a6bdeebf6aedcf6a06f60be6211cc7fa7dea39094346d5b805ebc1be69' }
  'win64/tr'    { $checksum = '90a488602b3e890a9a67061678a7e2f364faa713af8c2c3d8e36097e29cee172' }
  'win64/uk'    { $checksum = '5e18a31b3108b1a79ac7eb308cf34682fc0dd6e1e7369986ec59ababa3528403' }
  'win64/uz'    { $checksum = '96b6cb80322f7ae945e689ccad473855c3931bb388e556f90e1bd80746a5159b' }
  'win64/vi'    { $checksum = '604c4afb123b2ef191fe5d4adf6bb40810ca9f8dc848a762667607aabf784af3' }
  'win64/zh-CN' { $checksum = '6b2b9b1170f7d72bbb14b50bd6303ae376e80446917dff304a22d43d792b2231' }
  'win64/zh-TW' { $checksum = 'aa8acad07fbc777b6c77efb54f23d4893718df22a461d41029b8e2b0480ea5c9' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
