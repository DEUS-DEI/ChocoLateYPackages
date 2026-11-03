$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '160.0b3'
$baseUrl = "https://download-installer.cdn.mozilla.net/pub/thunderbird/releases/$version"

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

# Languages of the installers Mozilla publishes for this version, from its SHA256SUMS (block written by update.ps1)
# <languages>
$languages = @{
  win32 = @(
    'af', 'ar', 'ast', 'be', 'bg', 'br', 'ca', 'cak', 'cs', 'cy', 'da', 'de',
    'dsb', 'el', 'en-CA', 'en-GB', 'en-US', 'es-AR', 'es-ES', 'es-MX', 'et', 'eu', 'fi', 'fr',
    'fy-NL', 'ga-IE', 'gd', 'gl', 'he', 'hr', 'hsb', 'hu', 'hy-AM', 'id', 'is', 'it',
    'ja', 'ka', 'kab', 'kk', 'ko', 'lt', 'lv', 'ms', 'nb-NO', 'nl', 'nn-NO', 'pa-IN',
    'pl', 'pt-BR', 'pt-PT', 'rm', 'ro', 'ru', 'sk', 'sl', 'sq', 'sr', 'sv-SE', 'th',
    'tr', 'uk', 'uz', 'vi', 'zh-CN', 'zh-TW'
  )
  win64 = @(
    'af', 'ar', 'ast', 'be', 'bg', 'br', 'ca', 'cak', 'cs', 'cy', 'da', 'de',
    'dsb', 'el', 'en-CA', 'en-GB', 'en-US', 'es-AR', 'es-ES', 'es-MX', 'et', 'eu', 'fi', 'fr',
    'fy-NL', 'ga-IE', 'gd', 'gl', 'he', 'hr', 'hsb', 'hu', 'hy-AM', 'id', 'is', 'it',
    'ja', 'ka', 'kab', 'kk', 'ko', 'lt', 'lv', 'ms', 'nb-NO', 'nl', 'nn-NO', 'pa-IN',
    'pl', 'pt-BR', 'pt-PT', 'rm', 'ro', 'ru', 'sk', 'sl', 'sq', 'sr', 'sv-SE', 'th',
    'tr', 'uk', 'uz', 'vi', 'zh-CN', 'zh-TW'
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
if (-not $language) { throw "No Thunderbird $version installer found for architecture '$arch'." }
# Also warn when an explicit /Language gets a variant (es-CO -> es-AR); the automatic choice stays quiet
if ($language.Split('-')[0] -ne $requested[0].Split('-')[0] -or ($pp['Language'] -and $language -ne $pp['Language'])) {
  Write-Warning "Language '$($requested[0])' is not available for Thunderbird $version; installing '$language'."
}

# sha256 of that installer, from the same SHA256SUMS (block written by update.ps1). Every checksum is a
# literal: Chocolatey's package validator (rule CPMR0073) rejects a download whose checksum it cannot read here.
# <checksums>
switch ("$arch/$language") {
  'win32/af'    { $checksum = 'ad002a9228a5ff6ab4ff6bb950e1cdbac7a5d646eaacb78e025571a524c72669' }
  'win32/ar'    { $checksum = '4e6331f95aca51cf7511c376a58b805ac9cdfe2ff0d55f4e09ce199ca2c9adce' }
  'win32/ast'   { $checksum = '9cb2f481393228b99b9b31842b9f2c6aca694758f526117c12a95e5d3c662aff' }
  'win32/be'    { $checksum = 'c68887ebff4211356b9d7fc7222b262a233a73a71105349cef5a7099fb0235a4' }
  'win32/bg'    { $checksum = '541029dd4fe0ba00fc130a36ce9a9d7777fa3f2830e6f00a159a04b93b5e35be' }
  'win32/br'    { $checksum = '64a005a4fddfd613fea77cb6f7143f803e55f6b250ef173041a277d194136414' }
  'win32/ca'    { $checksum = '80eccc1ce74ef6171c895211d99d8b16f1eb79c354d270bbeb062abccd4918a0' }
  'win32/cak'   { $checksum = '245f779cc66f08d7940ef6a95196c47e7a7606628c02075154f2273dd975180c' }
  'win32/cs'    { $checksum = '774fe529935d1e8521d7c9fb3a0efc6c44e07efebcb291206aefeded23109b8f' }
  'win32/cy'    { $checksum = 'd1193e9f6695822d6a4a67ac889e630d851062b3d0ae5d8a52887965e170419c' }
  'win32/da'    { $checksum = 'ee0b14e5847ad8f5e573171ec6ce1efe36d4839fc9df41b2cb88038881f7d0d4' }
  'win32/de'    { $checksum = '7540986cb11b4afadecda08dc2168660bb0abccc93c87c792a3323eaf4d3d88f' }
  'win32/dsb'   { $checksum = '7a3ef1a4c06a29efa903c74f85a0ece39df041fe580cd3809ba383091b996a26' }
  'win32/el'    { $checksum = '5b18bd15ed740d9c76284bef5531ac0d4df88ea08bde5e8926c365db5a69f3be' }
  'win32/en-CA' { $checksum = '1696ddfdbcae821b045d2a9caf9f28cda4db9beaf71c14e3e301d016049e6389' }
  'win32/en-GB' { $checksum = '3e3c82822d61408937ea42182bec1c94515d6a3c840d12caa72c126e7f19c246' }
  'win32/en-US' { $checksum = 'd9e3f0db3f55393e7040514cc6529b8a2796085779fa0545d2bc4f3a171a0829' }
  'win32/es-AR' { $checksum = '2ceb36a521d973ecf223cf09b5e3d8d9ad1e9121f1a69e68dde77d0ce8af49d4' }
  'win32/es-ES' { $checksum = 'c0160fa04d73bf7ba23683bb7cb01ab04d81718c6d64176fa66f21c34980dee2' }
  'win32/es-MX' { $checksum = '7fcd53cb24a7f3f61d3af5be14be75251502a14e4364f0c6b373f743f803659b' }
  'win32/et'    { $checksum = 'c1b38b5dc46b5fbaadad2cca3cc692280ef217c584c3b79b2261e2d1bdea0508' }
  'win32/eu'    { $checksum = 'd6155d3c4719609956a84545bfca5b57693ecb049c4d1ee039b154d897ed91f5' }
  'win32/fi'    { $checksum = 'f4226af79e33ac579500d51dfb388f2d89eda5f309ba88564869a7f4dea8af62' }
  'win32/fr'    { $checksum = '9428cd5926ee550edf85ed87946895eed35ead8e55c2b4939bc454f94a36a1e6' }
  'win32/fy-NL' { $checksum = '216bedca145ac1f6d692c056da706299fe30461bd958eb776743e170f2c99c46' }
  'win32/ga-IE' { $checksum = '4c0bc144810096304d948786617bf477a4010c7cc59dd472bcaf2bc3e1001b46' }
  'win32/gd'    { $checksum = 'c28395862b4f54ebe52fe59e17ba539f01397978daa9d32e41184caa635d7610' }
  'win32/gl'    { $checksum = '3270ea6da81e4265d73667656496df2cc1d081ded2f63819ddccd7ba423e1fa9' }
  'win32/he'    { $checksum = '529088b7c9fd675664984d1f201f776fb84602b7ebfac2322a81bf65238f63c9' }
  'win32/hr'    { $checksum = '52c7cec4c750f2f395a00d892a9bf1e941cec5ad67641dad6fedef2d00921d28' }
  'win32/hsb'   { $checksum = '2d3c818e77701c8849bb8ba7ce5d56dca8e521df06b60eed3a67e7ac2c29651f' }
  'win32/hu'    { $checksum = '9aed79bbcbff34f3c1abf1732eec4d90cfa91b8b36d790d2c868fce2cb18baaf' }
  'win32/hy-AM' { $checksum = 'be2df8fe9231293cfca62ffd3cdfdc8569694bef3681c878f220252c2b8f0615' }
  'win32/id'    { $checksum = 'de6abf709f55ca49ce74994ae912b433a31f0162df4856f284bfed00514f4fd0' }
  'win32/is'    { $checksum = '8ae15ec09326459ebf66272342253129c8e47817d37d4871d7effe6f5ee42d51' }
  'win32/it'    { $checksum = '996917b70ff0ae3c231318ceec3b4f854d9dfd7111049f3400a02b233177f0b8' }
  'win32/ja'    { $checksum = 'ac7c4d4755758d16939979f4591255c68bd67959f2058291591e6508c5d04e32' }
  'win32/ka'    { $checksum = 'f4c174da3d545c7231e32a356afd6696624769370798dc2eaeacc02cc04172e4' }
  'win32/kab'   { $checksum = 'eb82a06ca78582d3e6ce935faabd746c65ac06088cc0eeb1f45e3340f2e54358' }
  'win32/kk'    { $checksum = 'e4ff51cacddff4b494f1a824fb29d75f522db41f533ec8a7f57a532166d47552' }
  'win32/ko'    { $checksum = '2b439ecd435b9171018699017ae06e69aa0a67557de54f46ef536c9966de9f2f' }
  'win32/lt'    { $checksum = '6e0356d8c6ca8b77b0907969187b70d0ae49af0842028cfe5902003d35de0adc' }
  'win32/lv'    { $checksum = '5da93ae3532916d515a5dec6150b99a7b2dcbece1fd50ffa8a287fd16c7644f1' }
  'win32/ms'    { $checksum = 'f828fd83b2e11972894436f9325d58dc2b3d7c36411308eafee268e86cb671f4' }
  'win32/nb-NO' { $checksum = 'b441a617253ed99b1c4a817faa70f4f12075f527776c40855dbf15d7b6991681' }
  'win32/nl'    { $checksum = 'caab250882993a22c33e97d5cef0291ba227ef85a3f53c6e726b85a9bb6ddc74' }
  'win32/nn-NO' { $checksum = '1da3f39a08a171b25ab698c0c567c6e8ae5c60a2359612cc5e828552d4f9a89a' }
  'win32/pa-IN' { $checksum = 'e27f01065d2e0043a4c3065074fb94fdf8c377d8e8e95c3aa81fbc187e027154' }
  'win32/pl'    { $checksum = '806a4a0aa4b08107b16aa40686c52eedf3fc3da82fa7439404f6a6cd1b3512b1' }
  'win32/pt-BR' { $checksum = 'ca33d8b18ab862593e9f8b931528d8f5145dff68d99816763ad6d149f073ced9' }
  'win32/pt-PT' { $checksum = '5e40c66dbcd7a11a71ff574107757a7694a04d523e00a7b3970ac1f02df20edd' }
  'win32/rm'    { $checksum = '5eea3c02e84ea7bd5f4b87af0fe6303de3daddbf5f6d0d3d8c869780f37c946b' }
  'win32/ro'    { $checksum = '8b06fad085ad64722a725454a6d215ae39aa36cc78d40122be8567199fd498f9' }
  'win32/ru'    { $checksum = '75cabdd2fefd544dce51cfe35015c8c982245acffe3c5efbc949bba6e0b5b12a' }
  'win32/sk'    { $checksum = '3e25548f360fec140f08c7c8bae2327df6483e598cef1ac67f4e8a13873efd45' }
  'win32/sl'    { $checksum = 'a61f25e998528b231c302a024aac650e8f233362f2b871cf92bc8006686933be' }
  'win32/sq'    { $checksum = '5b0bd2126e2e76a62341d5cccee862f85176439941612d3a96f0440c37a0b6e6' }
  'win32/sr'    { $checksum = '43cd24668ca40aafd52272664bc6e1b24bb0b6862da7900973518bb690e18304' }
  'win32/sv-SE' { $checksum = 'fd58c51d9e134b1c9028c345f037e537c915c44b8225effe2ef2f69bf64a9908' }
  'win32/th'    { $checksum = 'f33d4bfa346ebe0f547d5bd9006325d7dc68f653f0c0f2dd199a487df7603b52' }
  'win32/tr'    { $checksum = '18d07d83e9555fc9e0e017685e26e4c03028b890bba7ed5064258526e61ce306' }
  'win32/uk'    { $checksum = 'd397087f63e439bb73a54e7425bee43626208194a7555b91edef1d579e0da2a8' }
  'win32/uz'    { $checksum = '48f62355ad88f36c14e836ce80c7227beadb94d2125a4ca16c6fd17887f6a8af' }
  'win32/vi'    { $checksum = '750fd3266a9736bba81748aa88c531929e3c7cc8fc945f80376085c2416200a9' }
  'win32/zh-CN' { $checksum = 'c7d416f81af12acd4e3131c4c9a66b7faf800ae7901d0fa68b4e656a09475e5f' }
  'win32/zh-TW' { $checksum = 'ad64307f93e993feca651cea4b5ebc4752f1b2b33c070258479750a985a9dde2' }
  'win64/af'    { $checksum = '3080d0dec800e86575932eb280c7d9efe25762fa5815d6091a7fe7e6b0e2ae58' }
  'win64/ar'    { $checksum = 'add9ab1e4b5b02da31ce1eb834617f633390c5bf306ad67180ad0bbcfe54dc2d' }
  'win64/ast'   { $checksum = '988097e00463bcbe423d22ff341e77155afa4178c64b12a5016927a84ce14cd3' }
  'win64/be'    { $checksum = '24f7a6788cfa897a2d565d4c923b8eeed3a67e89201635ed36d0fa97d19bad00' }
  'win64/bg'    { $checksum = 'af1ef094e387543355c10240b03882869e56feedddf6fccbe134a675298f2f03' }
  'win64/br'    { $checksum = 'a62d292ba2129f2fce6a85b69b1235f351e93c35c891155a83003a39572fab8b' }
  'win64/ca'    { $checksum = '89a0a179deb885d4ed4a94913f272b3d4cf1536610ad6ce87d627787a7362671' }
  'win64/cak'   { $checksum = '88ced637d56ff353dc7e527f2fed66cda81600e893d9922eaa81eb5a1bea9b0f' }
  'win64/cs'    { $checksum = '979155dd796c4459368955352db388e6d48c11b4910ba23a3fe5b562f4251c53' }
  'win64/cy'    { $checksum = '3c60683018b0c733f48bca215e81ec74fb1c45373055434e6506447930634c90' }
  'win64/da'    { $checksum = '764b11064abf41c86da24c03a9785cee7704ed5a15945cc78d26cbc488209c80' }
  'win64/de'    { $checksum = '07217daadce2ef30566dd652c9e8b5bca8fb220ecc00af93b6122d7ca7ab3238' }
  'win64/dsb'   { $checksum = 'e900a7860030f22eb8e751ffea35f196ffd25342a8f55a1968bd3b6373273bfd' }
  'win64/el'    { $checksum = '833e8a53b78ce7a75b9741c7ca33657d1670e3e81467e5f89cd7d3f3e54a1eea' }
  'win64/en-CA' { $checksum = 'b5d5cefe58df36d908aaac32da855d586dd082bd7a82405eb7e0129c296ba8d0' }
  'win64/en-GB' { $checksum = 'd2c58a7fc53716d6d9f53a2e3fe147c8ba8cea2fb17563a93ba6935c99dfdfcd' }
  'win64/en-US' { $checksum = '2e021b1597b9edc7c4b69f99c67861e81545bdadbf9d2086c1f493d256871a26' }
  'win64/es-AR' { $checksum = '74b15fcc588a269b4cf1b1b9bc21bc76325a7a46e9d8cc8cea22f0882f28bdda' }
  'win64/es-ES' { $checksum = '12a3cd3196d4fd43cd6d84a04dd2c34ab0cd7c1739f4465b7b1899b012a7fa87' }
  'win64/es-MX' { $checksum = '0afea2e05e296610449d64104b78082e0c1546c3742e1e331cfec8c5c83be34d' }
  'win64/et'    { $checksum = '3e306b32dbda6543379806c632aa10a090256c2ba01ad680fae766dde431d21a' }
  'win64/eu'    { $checksum = '69df52e3a82dc5f2cd4bfbd940368e4c90710b4470e0a281502bc820e19bed6d' }
  'win64/fi'    { $checksum = 'c9de366994dece0699652bbcb0b19fbca9ebd4c348dd43968ec69c745ba301c9' }
  'win64/fr'    { $checksum = 'c01d0f65147cb8f64968653cbb7985ad2fb473c76a704aad6acadd674558ebe5' }
  'win64/fy-NL' { $checksum = '0cb16b9f83e9129b3f2eb514aa19e42c228d1d8472f6001f986951f44aff0e69' }
  'win64/ga-IE' { $checksum = 'ea5be67e5080b3e033fa5c1a47fdddc5f6b729cef3368728405613ab9dd6fb62' }
  'win64/gd'    { $checksum = '6c64a932a821996b608085cad630cdb1ad20f686db7b1a3687871155180aeab0' }
  'win64/gl'    { $checksum = '7cfb88c083c8f38fadf6590a0cf3abc0e970423cb0b726edac073342eeebc62c' }
  'win64/he'    { $checksum = 'ec5dc9014d44b7d95fa3911bc93984a75e09ecfd73bacb38df5b32ece9471f0f' }
  'win64/hr'    { $checksum = '4177e41afc08db039d7354b394dfdab074cb9149900c14bc3c8e9e946e0a2caa' }
  'win64/hsb'   { $checksum = '266366131151b7460a8a45264d2ef56e49d39952be9a7b9dad3491d817507dbb' }
  'win64/hu'    { $checksum = '4e45912919beba0627fa8b4b6ae857699bf9136b74f06ade1482a042216823f8' }
  'win64/hy-AM' { $checksum = '7ab4d673419868b3eeb1d08d903869be7a44c3df76924cdcd548e78758a891b3' }
  'win64/id'    { $checksum = 'cbbc96360ad897fc8fbeca31a38cf69a43ad0e1dd4915fa38b3b0e13755c39c8' }
  'win64/is'    { $checksum = '148d0ded9edff879a430e8c473f62f718e758ad33f2348bf9353cba28d6d5fc1' }
  'win64/it'    { $checksum = 'dbc454c090b71dea6f6952ac97cb9f900aeafbf0718963142a859b6c415416cb' }
  'win64/ja'    { $checksum = 'd03a1c0cc918b61d24088061f79c0ae76ddf13e35f63f841e9875a2e84e35aaa' }
  'win64/ka'    { $checksum = '647edc90ebf9911ba7b0472bb934cd8549b44e4cc8db3388f6806e5614ef0231' }
  'win64/kab'   { $checksum = 'ff29593708cb342d3bc4e0356e9c552e390ce7173adc56b5b51626d29d7acf83' }
  'win64/kk'    { $checksum = 'bcc18c8ffcc6e23dd44980ed176223be9e2a37672ec2c4749a92cde2d80975c0' }
  'win64/ko'    { $checksum = 'ab2259850534400d94dd9d749cdfcd1e67f2fb4e1867a5ec280d0154124b19c7' }
  'win64/lt'    { $checksum = 'eb5fbac700ab640200f3153325dcbfd769e1fa81219167c696e50592d79a6a33' }
  'win64/lv'    { $checksum = 'e42fb4c696df13f6680c39779246d5638b20d205f1fb0acffccb30e404165bc2' }
  'win64/ms'    { $checksum = '8d8db2ace631b9e1ea4af886b496abbb8d5c595032939df76dd694ab3db131c2' }
  'win64/nb-NO' { $checksum = 'bec8e25d5a98b7888413660bcb3758d86f305ea76d59807de583fb88018cec23' }
  'win64/nl'    { $checksum = '111497bd09d4b6233fbaa1948e1c2720830edea78b60ec9675c25f6a58ff9267' }
  'win64/nn-NO' { $checksum = '05df8e926bf9f853e9bdc7e9c3b2780aed5d82648fcfe1c4d91e1c23208b0796' }
  'win64/pa-IN' { $checksum = '22f910bcdd5284c7e212efc2c874d7cc9390af3de3bd8ecd75fc058184affd7e' }
  'win64/pl'    { $checksum = '488a3089236ae3634ce239c2f7a4eeece1592d4f14a5f5df0548d1a28e3ae819' }
  'win64/pt-BR' { $checksum = '205423637f53b2920a42d072ee54d8583c1470582e7d2a72851bca5cf42e8266' }
  'win64/pt-PT' { $checksum = 'e18be9ba80067ca0629b19e0d694a1853ded8eeedc4a4f7418abafd9e1115bdb' }
  'win64/rm'    { $checksum = 'a25b66eb33c8fd6534cca36ca1179174f25484e3d0daa3b5f555524afdcba738' }
  'win64/ro'    { $checksum = '48bfd5111713c63b212fc942d877d0c0c2611719d4f5e81f1d6329be869de615' }
  'win64/ru'    { $checksum = 'bf2df6e141f12ac94994a6b86a7fb4b32f11dafd38bbeada2fe7bc81fc67e67f' }
  'win64/sk'    { $checksum = '0dbe287ff96277aa87707437902ac3141092dd97bf8bc488099b94901fdadb72' }
  'win64/sl'    { $checksum = '08da9f59be5b94715320b98494d603164d88c214c8e3bd9375ed7325b24cc1e0' }
  'win64/sq'    { $checksum = '3212a57e2157ab3748468a1578a372ef61d121f83b15dbfbc011e2f52a6b64e5' }
  'win64/sr'    { $checksum = '005dd9cd65e964d7d6ce19dc4e189a7a4d91cc9a4a0469e5cd61ca9e019e756f' }
  'win64/sv-SE' { $checksum = 'a90eb917db37e6eb226aad39709e524ad9d3f706600f001f3eba8080b5761ac5' }
  'win64/th'    { $checksum = '8c48c101270c9db1ae4e17fc2cb5870ee8f0e6a3b1ae2e21d12c21dbb134e4b4' }
  'win64/tr'    { $checksum = 'ea37c54bb7ccf210a922b2fea94d8964f8311cddcdf849a49b9c41de5857031f' }
  'win64/uk'    { $checksum = '52a5f09f0f55fccca337b96474cabde2e6b8825179ead3528c54a4b3384dff33' }
  'win64/uz'    { $checksum = '01e7c4edd9bc0a64ee29cc36b3cf508684c741ef8bb56927b5c8f52cda023b5c' }
  'win64/vi'    { $checksum = '50fb3b076082d5f1927116abae9a87a1747264c41f6afeaea218f1ea055616aa' }
  'win64/zh-CN' { $checksum = '494a4a6b6ceb5bfb7012eb344d8eb5837abbbbdf2ab522af33ad03f8b8ef51e9' }
  'win64/zh-TW' { $checksum = '53aaa068f8a3bac5888bb362a7e5404791e8732d045cc23096f63c09138261b9' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
