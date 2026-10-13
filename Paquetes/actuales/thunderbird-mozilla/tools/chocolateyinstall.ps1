$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '159.0b1'
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
  'win32/af'    { $checksum = 'fc983ee4e38fc61dd4f4b62099ad0072ce9f96e44c094ce8f075f93da3fa5029' }
  'win32/ar'    { $checksum = '5d932fe779f56af3c7ef993baf87c5b0ca3ef658f8f189526e58c9caa52dc871' }
  'win32/ast'   { $checksum = '26f496772c09ebd55f320186b630638e84b14512fe21daba718c1b9e0420003f' }
  'win32/be'    { $checksum = '781873412fc49a8430ad00dd481fb3b1096f4be4ad8b805d28ba629f4579f38f' }
  'win32/bg'    { $checksum = 'f27fc9e3b855e2794893cdf1221fc7ae1be7b3358ee86987a193af3de67ebd5c' }
  'win32/br'    { $checksum = '359230a6232e7fac5fb206b0a5eccf329f40b02340d69e12d6d83228883c0b29' }
  'win32/ca'    { $checksum = '4aab3d94cc31f97a20630bdf5a562c23aff5fdb0e9e36abdddce7e37ff25fb53' }
  'win32/cak'   { $checksum = '0f4bace8030d656ebbfb5e6147474e25c1b4fd793a912f5a0dcd3e25987ba065' }
  'win32/cs'    { $checksum = '357528735ab5eaf30d5b01347028e51ab0030c30e212fa99d90eafbcb3ee1b63' }
  'win32/cy'    { $checksum = 'a2bd653c91f925631a0415d4ce95dd3002f3d3ed7e0012e2646551386ee75eda' }
  'win32/da'    { $checksum = '9b686076d1c7a476ca04bfd4faa84790858cac6ecf3234c7ab25a022499ad796' }
  'win32/de'    { $checksum = 'daead529c81fc713062138ed8041307b494913ea3aac3a7b3b04312fd9f32bdf' }
  'win32/dsb'   { $checksum = '66a9f38a4a92e9caee28f79233ec97e73e926386e97f35553150be242a464ca0' }
  'win32/el'    { $checksum = 'ab669c9f69dabed12d15e8622ca04f6f9a18159010d68b811fd74f254ba449ff' }
  'win32/en-CA' { $checksum = 'e9cb679d62ceb9ddea8019902143b971a4ba212321d8aac24d465d1df1623ae7' }
  'win32/en-GB' { $checksum = 'fb9e969c96d2b71fa37b92572f0f1b43dd496f685d8409ec7cbf759d283b0f1e' }
  'win32/en-US' { $checksum = 'e6e44959c997662eb25722978c5fa19a274be9a0ccc7f27c89bd878a0a06ecda' }
  'win32/es-AR' { $checksum = '524c0d02206dddeba8cd0771de662f3f86e3224a4f0cf859ded006150986b1a9' }
  'win32/es-ES' { $checksum = 'bc92fc9a743cd51fb40f8fe285e148d2eb8d3ca7cb3644f418ce3c5e3b753fd8' }
  'win32/es-MX' { $checksum = '57424bd8c92e0c117cc9c78862b1adfa2fad727ea02b775ac8289459f78331c9' }
  'win32/et'    { $checksum = '581a97c39f72ea06eb60a3a8c6ed804164832d85e69eba717f248dc1d40540bd' }
  'win32/eu'    { $checksum = '2b736bab53c659533eb19ed77da2c0fe47778cdda3a5a4f0741d1ef1698ef77e' }
  'win32/fi'    { $checksum = 'e09cef57c3bbf3a98701ebdc391f2f283e23a238fae9a236c006af61813aa357' }
  'win32/fr'    { $checksum = '227689e8182df1cac5b98e0fe694332d1a1e1092477857db841ece0434319c0a' }
  'win32/fy-NL' { $checksum = 'd77d840ec0ea45280a5794be82d822bfcb6c498e843b97431837d0ffa41df906' }
  'win32/ga-IE' { $checksum = '3e1d78f3eb40e00ff7b2dbba78dcc3b6dfdfd5ddd011730d3b4683d8b3be5a50' }
  'win32/gd'    { $checksum = '101477094232340488ea60526ac8a97ccf46eb302dbc51020af59ffff0530bc2' }
  'win32/gl'    { $checksum = '615b40c757c2386ef4c147e53ef253099e3fec9a3d0700d0ced79ae80c1b3705' }
  'win32/he'    { $checksum = 'd21207ac0da27833b286a2200efef8afd953c98975d629036098a0d3afa69376' }
  'win32/hr'    { $checksum = '6b048b6e1c2c80299de1b06b027af703cd73cc766226be72d6101fb89c3ea784' }
  'win32/hsb'   { $checksum = '2789fac462682cc3641dd28741d81d4122cf380c530e00e36d735c3e607cf1df' }
  'win32/hu'    { $checksum = 'b02601c09141f1e3ffa60e5af56b0121e4d8efa3ec89b34a6e13f76f424fdae6' }
  'win32/hy-AM' { $checksum = '70329936868db9ab6965ac35334f547922b85fa289ead11ebaed7bfbd41e9c0d' }
  'win32/id'    { $checksum = 'f4843a170b0892407f45b7f9cd97b752c722a92fbaadfb6f8f241fdebd2fa964' }
  'win32/is'    { $checksum = '13f4d9fe5cad0418d2aa15476783bdb6609f5b854ac4a11003075c5a1d3fb04f' }
  'win32/it'    { $checksum = '2e50cb5bb67d0980eba0cb96ede3db7693eee3499c9722abca7afc1d96a4216b' }
  'win32/ja'    { $checksum = 'ac5e99b7b39f22b1d559146d595af4855298542aed79287301bd3702ba9e08e9' }
  'win32/ka'    { $checksum = '338fb9d673860ac08e640c82166c7127ddbf5ef2c886ac9f5f93ff2660bf4a48' }
  'win32/kab'   { $checksum = '2af434f4ad1425b160bd755d10a89bbacb95bc7940f0acafe19fac913c4242b3' }
  'win32/kk'    { $checksum = '9986dc8faba97f3f8dfa1fc354996aa763c5c0285908dffb8c9bc72b2bcd35c1' }
  'win32/ko'    { $checksum = 'eb103d3bc213557ddde3bcbbc3b380224fa6be9303fd9f5dfd5fc8518eff1e93' }
  'win32/lt'    { $checksum = 'e2ce88a9745b53a216be9c04c34b2250828f0d2701fb1e28fcef24e6c7263169' }
  'win32/lv'    { $checksum = '40507e9ed106b59f23c756e06a5abf187f2e54cf5bb4b7402d959e4c0207f718' }
  'win32/ms'    { $checksum = 'f354a87d733b4f533720697e417b08fd0cf73d6b33cc35cbcc273a6eebbddff2' }
  'win32/nb-NO' { $checksum = 'b056be2ecce460c895532f63a6330017f12b736c787bc23c006bee1c3fdb0fb2' }
  'win32/nl'    { $checksum = '8a7cb3d8b26632fa82d75654adccc10235759eb7204bcd2ef2ae50878fa1d309' }
  'win32/nn-NO' { $checksum = 'ebd7aa96328b7535c4b7d83e1b11ee3db04d5734243e05422bca373676854fdb' }
  'win32/pa-IN' { $checksum = 'd8850e142d5b11cc48c6aa746d4a2f5d5ffc49bddf32bdb58adc4f04ee1226d4' }
  'win32/pl'    { $checksum = 'b5791fefc50a0259208ad6b39ce8b559d49f86940cab324b08dcbc6c22cd2e8e' }
  'win32/pt-BR' { $checksum = 'af1f9471e87486bc43c1cd53ebc43ddc03fa6e142289f318b5b70fd0d1f4e48a' }
  'win32/pt-PT' { $checksum = 'c9649d0110cc26c26eb2f055af23f929f758ff3dcf7af4a726120317514261df' }
  'win32/rm'    { $checksum = 'bf2acc3a3d67c57bbce4220d45366adeb8db86064479db6aead5041c455e8f15' }
  'win32/ro'    { $checksum = '9780de5044f7556019f4228a63638ce200ce740ad05995b9cbefad57c72e535c' }
  'win32/ru'    { $checksum = 'e4da1867cfca00dab69a89acbac6cc50ac6dc11f1a8d2f4e8e93ecb85292a4a2' }
  'win32/sk'    { $checksum = 'e06e85b820a20b8e66c6552cf4192832111906822f2c6eafd4b6b2a60e7b512a' }
  'win32/sl'    { $checksum = '5958695371664dfc72b8522a40e39673f52a5c4e52f2f02210a277779ff006bb' }
  'win32/sq'    { $checksum = 'f46caf00de4a9fb21f6eaa7c50255b695f7d76cf4a4e0a7d124c1d8f918f36d9' }
  'win32/sr'    { $checksum = 'b6bd3140004e2ddad6475db84774c249dcf0a5e7530c38ad2eb97789cf445a36' }
  'win32/sv-SE' { $checksum = '49457cc6d1775ea2e183e00f5a801e726eb9fca4a28451837e08e33650056634' }
  'win32/th'    { $checksum = '86c175a44c01196b64e699b0839aa3cf0488efd50eb05d907d3bdf51cfa4acf1' }
  'win32/tr'    { $checksum = '9a842b1eaab9c0985c171a9d70c1e585f5f6c4cd5ae466d9b53bed38f26e321d' }
  'win32/uk'    { $checksum = '2942ab6fe37cc691a3d07644d57a2363049de08b52e782795f4f316caf72e409' }
  'win32/uz'    { $checksum = 'c96b8e7b54b499f1e45e808984b15390d0250d8d4df98eb2f2943cbc131d06af' }
  'win32/vi'    { $checksum = '2f821e826b3b510212137bff99b1a3b992192902cf4d2ed10d0fc180fadb5208' }
  'win32/zh-CN' { $checksum = '742fde68c41c0ce1ccc8b52cf2e5e47476d55185d8614bb520ae48db3ba82896' }
  'win32/zh-TW' { $checksum = '9f2e4cb966fe3ffa109882cf781d8a1e8a6e2b29aaa2900f46fb67ae93093cc3' }
  'win64/af'    { $checksum = '9fe102839b686d1fdd34ae5037dc8ddeb4fbfcacba4b9f065f55e1074406e8e2' }
  'win64/ar'    { $checksum = '3f7018283bced3942a928ade43354ff0c5cc9f0d1576f4edad8a2a52ad90c84d' }
  'win64/ast'   { $checksum = 'ea3c9337268e8a05704cfe5a994d12dc7c3ebc3735de207587f614e4beeb4fea' }
  'win64/be'    { $checksum = '81c744724b88afbcb6487edd37b8017315e5d8736bf25e8cf64cf2d06d0f7c5a' }
  'win64/bg'    { $checksum = 'a0381673c2306d70092eb53818640ad05fc2cb38db85eb1738c89f717a66293f' }
  'win64/br'    { $checksum = '71b06357fe26d49542fed9d03160e644c313b71f40e8803620345cd9ba966bcd' }
  'win64/ca'    { $checksum = '6964965ec12cf6ed9a24909f604b934ad16f1549321c9a4955881b81473b438e' }
  'win64/cak'   { $checksum = '7559532450ee233f500c16f934a51cac1298206262530bce84ff26494c0bf36b' }
  'win64/cs'    { $checksum = 'b6da5c017f3a45e4f6e5088309d54b3999f295eb72132a3de58c3ca8936aceab' }
  'win64/cy'    { $checksum = '8b7106cd4721b8c583dd333fa789b7b2c9dad4117f118ec4d6dae32c91fd2bca' }
  'win64/da'    { $checksum = 'd13dd9170477f739ca24812acb31a6f4006506d9bcb7796197415a22c47e35a2' }
  'win64/de'    { $checksum = '3c6da7dba65ec241112de0d28c318cfb937298c29edf2607bfc19a0e1d821c24' }
  'win64/dsb'   { $checksum = '5b746ad48e4ddd98c55a1cc92cc60f636a0ced93dd6b3e0f2b7c6dbddf7358cf' }
  'win64/el'    { $checksum = 'f7e51b24fe2c41679a8779e8e8f50556a3293ee894b34b0399a878df2c1592cb' }
  'win64/en-CA' { $checksum = '56f0cbb7c0b904c98f43aafb1c166ac1962922c066789481a93f3f5fbf26123c' }
  'win64/en-GB' { $checksum = '154f4e8ddffa990260ef10a257ac48722c6bc0c239f93107b7aafa0dc7af4857' }
  'win64/en-US' { $checksum = 'c73f8550540fa31a9bc74fafd278bd955e61eb7a193d986213f6cd23454107b3' }
  'win64/es-AR' { $checksum = '83f6965f7d900b859ef178766b470de65d6da2156f816c2934a62c46d98a4af4' }
  'win64/es-ES' { $checksum = '0ada5fe66ac1cc7958848698c882c2bc789d6adb8f3e1a774e0b7d2e7b11edb8' }
  'win64/es-MX' { $checksum = 'a70d323b7d86d3ba516e82b23fc27888b3458ba20fe952386b5710aa203aeb9e' }
  'win64/et'    { $checksum = '5a90329f2dd38b71106907ccb03247c184ef2351e7475dba0a87e7c6d0c6ab86' }
  'win64/eu'    { $checksum = '3f200077b3042fb169d7db2d71e9a8f96cb1f737f30a3db768e68510261c3e97' }
  'win64/fi'    { $checksum = '158b96d8018cbc0edb03102dac0b89ecbc116277fda02cac524422d19c45916c' }
  'win64/fr'    { $checksum = 'b67b320fc2504e888727a1b0d11a02e66b2198f41598d81c4fe21b55601320a1' }
  'win64/fy-NL' { $checksum = '5f57c396ef417b4fe65f937aa300e3c210d6d2e4bbe575cde8fc85a36d2410b2' }
  'win64/ga-IE' { $checksum = '5af91b3e3194c447d54c26859f6f3546d20ef8f9b947253f0f7c0ab7acae6d01' }
  'win64/gd'    { $checksum = 'd84f5f1956345948912cf725ac55ca004c465e38a3fcb105ef7987a366565748' }
  'win64/gl'    { $checksum = '6984fd88ea5197cc6e74344a20d74f3f31d41593e2f5ad025d5cae516ea8cc80' }
  'win64/he'    { $checksum = '2ace316ce158856901842ef8d1fbac1d4002893af62a5b1616d4327c4f87f62e' }
  'win64/hr'    { $checksum = '71a24996b8264d8a501398471d356f14d97ce296b29b8d074d37aff46f806be4' }
  'win64/hsb'   { $checksum = 'def0d26cd03f2975b1ea7297e3b67f7afe5ac2ea183d9a694feed9f27280ea3e' }
  'win64/hu'    { $checksum = '9337cfff60994e13dc0723e191467296f2653272bc805e790b8469b95f8a9a84' }
  'win64/hy-AM' { $checksum = '37661cd1f29d1b03bc72bb2217c9d20934d2181d11ff48cf5d58ea9c462d7d52' }
  'win64/id'    { $checksum = '28e10ee6bd867d33f15a950b69570bd5eb90e181e009419034a22f27378e366d' }
  'win64/is'    { $checksum = '8b3a4510bf018482f53d527555047c5a68da4d83ab7d144c83b4ac74a486fb82' }
  'win64/it'    { $checksum = 'f57cc2f7c0ed05276fc6cfca699f5221404343f96a4d39cd37824ae26433fdaf' }
  'win64/ja'    { $checksum = '76a546282cfcc83b731fdeb491339e5762c73f96ed7fc375259ee11d6fc3e122' }
  'win64/ka'    { $checksum = '74d3b81f4e294502f644d1318ed252e1bc896966ad6bb9ab2df038791ceedab0' }
  'win64/kab'   { $checksum = '74a13b007523d44b8c51a8e75d596d8a383febbf522387fb811a06f2ea5d43a7' }
  'win64/kk'    { $checksum = '56a39a552e4e22a2c7b2a6e397a25513ac302dd7a347fa7f228e899f6672f647' }
  'win64/ko'    { $checksum = '88c26c457b0197406b7992380e59929d13b66edbac2615a55169dd141ce1649a' }
  'win64/lt'    { $checksum = '19a68d33404a83244115aca2a7870c9d47b4f9e773b086b913f6d621d2f20193' }
  'win64/lv'    { $checksum = 'b8b58e67af0f13a427c069ff676cbe9eec7a6e856c19a5fcb2dc0e0c738af6e9' }
  'win64/ms'    { $checksum = '07032f77c2d9c49d1b4fd378a94212fe59a574a969be9e11ca9992bf08068421' }
  'win64/nb-NO' { $checksum = '3c492e6e0da4f892fb693f0df490fd92cc25c81292e697231221d01156b7183d' }
  'win64/nl'    { $checksum = '3cd8b442d792db2bc72572b4fd17115b4c09817e9f2e8da99ab8e4009330c76e' }
  'win64/nn-NO' { $checksum = '1796c7d145dad42ba29f84ca5b5999487250dd2b659f1628fcba82ed6a39d3b6' }
  'win64/pa-IN' { $checksum = '5f4176f80ce8cedebc245b68333df08ed17a3f85c34dbdc5daaba16f64c05bf7' }
  'win64/pl'    { $checksum = '9ced0c945d4c2f98ce898a447bbe05da468e303cb0780578cd5ba832acdaf37b' }
  'win64/pt-BR' { $checksum = '144f57193b22f30d7e819c9146d4a51107fe78344575c62b11aa8fce46da502a' }
  'win64/pt-PT' { $checksum = '22107007d1079ea7f9214785fc7e3c863d70f0634d63b42d9d30e73fe91226d6' }
  'win64/rm'    { $checksum = '1c962d0e61673568ddc46ae2ae53d82368ea63177da4ac7ce2e427143d469301' }
  'win64/ro'    { $checksum = 'b3efea9ef43d897efab22d9ad6dbb20a1ad03c428396d593734d058ff61eef9f' }
  'win64/ru'    { $checksum = 'fe95d6707ecea3163aed2ff2bce3ff40007b0809780525d460329b632136c729' }
  'win64/sk'    { $checksum = '860fc56b57f43dac3e74e1616c4aba8d07bde899fe92c3f5b6a8e628076b5a4f' }
  'win64/sl'    { $checksum = 'd59a723b70301a22811b8a4d450712239027c084386c0dda435a019647857017' }
  'win64/sq'    { $checksum = '5e280147e7fd782688f35d5f98461abd85f9fa25870c5095d7a5b8e8ecb98db5' }
  'win64/sr'    { $checksum = '5239ab1ee3a109157dbe394f0f386da106c039c9910636e3f4e69bcb08831090' }
  'win64/sv-SE' { $checksum = '5ec6160265015ee8330a9a5739278d311761a35cd246a2198b69e43a32655ceb' }
  'win64/th'    { $checksum = '43de96cd89c3fd4c3f0375f2026acbaac51e8460818ae8afe78819449d1f797a' }
  'win64/tr'    { $checksum = 'dd62f1df2592eea69cd48c8d0bca34d18941235496451546f7bf56efd6bc2e1f' }
  'win64/uk'    { $checksum = 'ed691b747acf918be1698e9805310091c3be71374c490a212c06fd81491744ac' }
  'win64/uz'    { $checksum = '41919ec5a1f17481b78aa465acf7768bfb86b90663048756cfdd22ea93d5abb8' }
  'win64/vi'    { $checksum = 'cc542471ee28b50de26366057c4ead3ee1dc5937d49d2af1b34e9b5fe03cc1af' }
  'win64/zh-CN' { $checksum = 'a1933d19ae6161e30a5493b9ae8e9c0157961f2a3e655cfc5425e54b8ddc2bae' }
  'win64/zh-TW' { $checksum = '470f47f960b0e2fe58762a9c26422401255a3634c573077867a3bcffcde8408f' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
