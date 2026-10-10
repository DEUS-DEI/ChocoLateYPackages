$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '160.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/10'
$build   = '2026-10-09-10-54-31'

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
  'win32/af'    { $checksum = '00ae0f1d2139bf682be257ff700af589ca73fe0630986a2ca4b2264e06dda732' }
  'win32/ar'    { $checksum = '1c809ebc59c0069a9f97bbece15d46e15b3f570f6f2a7a18a4da1c883fbfeee7' }
  'win32/ast'   { $checksum = '306fc82796c227030f1bba8fafd471c7de80ef61305a65d24caa53b6f69c6108' }
  'win32/be'    { $checksum = '3cc190c407aea72e6a156dc1b828701047427250358b5af8c275d97239a657b6' }
  'win32/bg'    { $checksum = '6bc85ff49c1d3f6b1884f077fbbaf0229abb4fe22738b48a6476ff73acf72eaf' }
  'win32/br'    { $checksum = 'c3ea134743ca2e67356d071d3f71ec61e8b5df49835ad497c0e0148e6bcc6835' }
  'win32/ca'    { $checksum = 'dd47f3a3337801a034f160e904948aaa1c3613e128cb2f5ee4fd59d6c73af662' }
  'win32/cak'   { $checksum = 'a372e97f5a32e88075a6424a66b5101ac3089dfae9f964bdf6a2bc5297cdb23f' }
  'win32/cs'    { $checksum = '5328e9cd49463a266a9fb3f9f61c363e1d5ba1d2d075ebe4fbb3f81379ef42d6' }
  'win32/cy'    { $checksum = '216af26a5512e26dec296e82ac9ad9aff5beb924860e909fce921d3c36159709' }
  'win32/da'    { $checksum = '4d70c496f88496ff6e9952723b0f32bce578f522fdd8f7554901af1a804e4a33' }
  'win32/de'    { $checksum = '405a1af0f15ad9fe971a300e4ddf25c5f5235d98dcbb8bdcc6bdf6a57a2e948d' }
  'win32/dsb'   { $checksum = 'b9cd3e4be58f0c89ee0577654b23f164f944d386c7c945224f315c9e6fd345f1' }
  'win32/el'    { $checksum = '4862b2415adfdba543e9f3f202e88d5bb966ec35f4fa9a283a47b3a33fa8e950' }
  'win32/en-CA' { $checksum = '2342cad95fc98c3894f3941e9a4ce714b689536f0816f965a7165290dadec8d3' }
  'win32/en-GB' { $checksum = 'b6e51ad47489ee85dbb948db4baa423879a6cbc3db5a3d8f5cd3c11ff4e664b4' }
  'win32/en-US' { $checksum = '97c7cb5faf235c233d5c82e04fcc4a63edbf4eafe35c63e3a758e1c5d231c466' }
  'win32/es-AR' { $checksum = '41f0d7fb5eab50f382795377619c175d9e212bbb1cecd7062a31bad5796047fb' }
  'win32/es-ES' { $checksum = '7f12b88149ec8b846cd69ff787d0495d3b8ecaafb607e54780a66385b275a450' }
  'win32/es-MX' { $checksum = 'd6d44e0442ff399decc04bcaa76c0ce17f112f022c7839cce3370ff26793d27b' }
  'win32/et'    { $checksum = '6e8671d08e2df585d2702261bb30b2592d06a094829442d32319817c551b469e' }
  'win32/eu'    { $checksum = 'a4c479de265c8807e51aa4aec24fcf82d58e9fae9f12a71746b8ba436020d99a' }
  'win32/fi'    { $checksum = 'c4452ca5089459a92b1a2a5d0b540ce47de6c68a8737be33837e29a3bdf072f8' }
  'win32/fr'    { $checksum = '1c1e3ba488af1df082a35502033e5b16acee3216679c7133f0f22be746289248' }
  'win32/fy-NL' { $checksum = 'fa40d7e422e324302552d1e24fe960d1093fb2802a83575e79111408ac4d4828' }
  'win32/ga-IE' { $checksum = '3e8fcf191c0ed732cec578f81ec0325df9c5a1746bc67f2e4052bd02d3715120' }
  'win32/gd'    { $checksum = '49e29e6e0133764c364da3e2e8f3bf09450ef6bc73bffce24557f7c24b9544ed' }
  'win32/gl'    { $checksum = '78808f56534c20f6501f5dd4efb59a56253b9742226a353d2c591dfafd511097' }
  'win32/he'    { $checksum = '5777fa34ade23c284983760e7eaea65137d11bb6139332f8217207cde70c242a' }
  'win32/hr'    { $checksum = 'acd05ca5d8b5dfe6da519745d59401b9de56d39438adf58b400ce73c0cf917d5' }
  'win32/hsb'   { $checksum = 'f5a8225fc762c4ebe4b7702620ef901df3b5266288bd6caa1ded86be1a2151de' }
  'win32/hu'    { $checksum = 'dc78f04e57d88e202f4288d7b87eebd921817b0740fd445ad1849cecc1967167' }
  'win32/hy-AM' { $checksum = '9a0188759bf340665f423d8872dbf25843e1926bf41c5674f7a13161611a1d2e' }
  'win32/id'    { $checksum = 'deb45cba58c05e599ab96d17bfa83f0db2441838d6991cdf29698eba64675377' }
  'win32/is'    { $checksum = 'a96e5ed374c1d9b8e245e64c6c9e7d0fa63a062aff5beebb847194a73d1701b1' }
  'win32/it'    { $checksum = '8243cbfb991ffccf99b12e6cb611db5674d69e262da4e976a3c8997e9872b62c' }
  'win32/ja'    { $checksum = 'a2a053af475afe188eec5b49a7bb04d3ed5dc38bf6de5fcaf641f91b27fd6d96' }
  'win32/ka'    { $checksum = '15ea977ae1deda0381cbdf9504f65cf0f4bf39993f2f950f005f47b0b43b7a50' }
  'win32/kab'   { $checksum = '94066750ee56f243175a81d2894eb907df03bc4cd19c53ca59817191a69582e8' }
  'win32/kk'    { $checksum = 'f4b35df587e54d4664a99a49721f339eb2b55e832578d729592c68cbc04373da' }
  'win32/ko'    { $checksum = '3123c002f0315c0d28579f56ea1dcb0a7d4eced2572576785871166545100021' }
  'win32/lt'    { $checksum = 'fc5f758552c78a139a31cc7343abb515073d318460bc15e7bda6098e4eee392d' }
  'win32/lv'    { $checksum = 'e6d9f63b6afd4e6e63d0d177d9d5a266bd1135519a8e7ef58077a1e45ac0ed59' }
  'win32/mk'    { $checksum = '85719ffc1e6c4d9068981d8d1e950e1c70c77c6d91e32139e61844b74462ca28' }
  'win32/ms'    { $checksum = '45057affe97bac5138f6c3533fdd208621be8b2c9632699a2669958d42dc8ccd' }
  'win32/nb-NO' { $checksum = '8fdc7a9628cf215912ff68396b0bdc57a0956278990a1168cb4916e4b2f6468e' }
  'win32/nl'    { $checksum = '2bf1acbe3df655e8f891c33f805f4cb43c6e03ce8e5dabc50ca776ae9b85fb36' }
  'win32/nn-NO' { $checksum = '8b0d3769f07a4dc90f9e9eedfdfd1c1f4f1d2fb4c1b3bac4944ba20faffb44da' }
  'win32/pa-IN' { $checksum = '32c464210234a0a9b095ca03ac0598ecc3287c61cd3a8e9d65a27a4ca6564cdd' }
  'win32/pl'    { $checksum = '54d95ad3225574a926d5f06123b897b5660f74ec682fb5673faee679f311a9a6' }
  'win32/pt-BR' { $checksum = '54f200e87e5e4e2da492cf16fb27de54264c5f5614c439291ae8f7b283dc5ddf' }
  'win32/pt-PT' { $checksum = '5bceb1c395d793245f4fa06817ac6b5177d0fe807ee5329e34acc746f57a12f7' }
  'win32/rm'    { $checksum = '22fecc148a74abed94cbf64f04af814898a7c1a52a1d5a1d85cf1cba793a708c' }
  'win32/ro'    { $checksum = '64299d0e861691a8042897d2c742887eda14194fde4cbe6c7ddc485f44552f79' }
  'win32/ru'    { $checksum = '5dcb16a5096fa78374c78764e2f611134e8cd205ee76d8f48f57c4d2d1c1c55e' }
  'win32/sk'    { $checksum = '6209651c24fb40f8ed3f455f7fea9093fe4b1d6d0fa2e6fa49b0dedc511b1326' }
  'win32/sl'    { $checksum = 'e8b766425f1db55cd30e9a8b507409dd231b726c9418dc78d70973024143f227' }
  'win32/sq'    { $checksum = 'afd8ff17daa77f2a08255af75162769b80962f0835b313f01ff809418dda1b60' }
  'win32/sr'    { $checksum = '8774293351bcb2824458e0a40e47ba2731f23b6a9c534c9b3f3a902b15644b59' }
  'win32/sv-SE' { $checksum = 'ae2e0a1292c10730ddce76193f3b414ffaf95722385555dffe83569b07a17bbb' }
  'win32/th'    { $checksum = '337b789e4761a04928c5a3d315ba79635e4019d910216fc1dbf0e60f53824d6c' }
  'win32/tr'    { $checksum = '03331e976d7f3d68aa987f2bc777e55c1d63adabfd31228482d45f5dee82f807' }
  'win32/uk'    { $checksum = 'ec719fec350e8a41271a87b44a9ec20882945430aa237668c2673d2be5389bd1' }
  'win32/uz'    { $checksum = '9b781cea3a9e0f6655f9f8c4d604ff6342b22b5ad95add4ce90b5bd5f9ff47c3' }
  'win32/vi'    { $checksum = 'e651007b357bf966bd59a7cd50dc4c3efbd2a6b7940c19e4ed1db77dac7363c9' }
  'win32/zh-CN' { $checksum = '91016d64377e4ba7fc69a6463a90a4c1772ae372e2915cff446c55568faf9454' }
  'win32/zh-TW' { $checksum = 'c4aff8a0b56b87cf84583fcca5551d13e67cf1de3c8259ecad0ed7c64ef0a0cb' }
  'win64/af'    { $checksum = '28618f5ca0ca133bd894c5a9de2a82c765d68f529fd958321b3bbce7c5a3e46c' }
  'win64/ar'    { $checksum = '47a96aeb637c855b10437d2dd8c9999f8b126288f3ae4c1e9a29942ae2575c2b' }
  'win64/ast'   { $checksum = '6dd1558927439a3435933f32df54c1e4b3df82aae0d34a33f02242f66dcc2e09' }
  'win64/be'    { $checksum = '229e144d7c0f1eacc90d3e565352c14111b723aaefe05314caf93190fbb5c9b0' }
  'win64/bg'    { $checksum = '363c20df2ea07cef305a8f6101c1e827dce04f7fd5f9261fdda96e7d4872010a' }
  'win64/br'    { $checksum = '9ea86e332abdd9270f0f246f17ea0f8cf8f586c3f175519d8d44deb6c5ecf5d6' }
  'win64/ca'    { $checksum = 'a3049dd921bc338f7343fac3cf6be187972b8e0b01d0cd565bcdc9394cdb3d5b' }
  'win64/cak'   { $checksum = '42f0268d1e3b3f40f923879c0b4d3f69bc841c48664e2793bc0e2b9c9305ae63' }
  'win64/cs'    { $checksum = '579d7de410f0eaa7fd40537aa586f3cdc15aa669fc96f3eab1b776d1e39c1f8f' }
  'win64/cy'    { $checksum = 'f08f1a0a61dbc2e34f8c589d8f7945f81608dc61a1d961eb40edf3208ed81a1e' }
  'win64/da'    { $checksum = 'e63dd31530e589c8f7d179be12285f77abc976c8393946296a3c984bd55936f7' }
  'win64/de'    { $checksum = '1c44ac11cfcce5a3bb7c15337e6fa1675135840f3964398f24bf36486934616b' }
  'win64/dsb'   { $checksum = 'f1bf80c05873f35906342548df83b30c97db5e6a21de65576bc796ba51cacacc' }
  'win64/el'    { $checksum = '14c58e4fbdaa18504467cd486989645782cc29ba2ff80eeb060583ff0b6608b3' }
  'win64/en-CA' { $checksum = 'cf766f6c9392fa36589655ee7fa5809dc28a890fa7f051d20d1492e48c44bda2' }
  'win64/en-GB' { $checksum = '78102b20644c43d70fb93e4315f587c8cab951b8327e335b04ddbdd33ba2e218' }
  'win64/en-US' { $checksum = '4d8f51195f573dbce8d49d28304f978a4f5403b2c1af063f544df07041db8ebe' }
  'win64/es-AR' { $checksum = '314923a94add9a1d2738e6cfdf61cf702c53cda768513bc99df668ab3953ee19' }
  'win64/es-ES' { $checksum = '3d49b1f0144efa01bae0985ae7598e21295d6ece2dbcfe1c7d13febc294fdff7' }
  'win64/es-MX' { $checksum = '73171abf49faceeeb90a7969c8f11f2e263452b56c1ac579a0f8c8c5ff3aac9a' }
  'win64/et'    { $checksum = '1acd36ebd309cc649ffaaccfc542c9820a7939eb0bf48f368d7112dc43c04090' }
  'win64/eu'    { $checksum = '88f284e76036f7739cc65372fb332429577cf2ce1a43e87d9141cf1f46c64161' }
  'win64/fi'    { $checksum = '8f622a5322b83d81c9a52d6dba0089d56d94530c5f6453b806cc3a6eaab1f5ef' }
  'win64/fr'    { $checksum = 'cbe46a20c7b492b1f824d6f0b60855c4bf2e034490302ab2944350bbdda7dc5c' }
  'win64/fy-NL' { $checksum = 'e04814181c4106382a6eef1102d82c8b86392b1fb8eda1e24e0e20774ecb0362' }
  'win64/ga-IE' { $checksum = '68ea1bb7c0fd67a29122730d94564fa1d66556084779045969367830e2791541' }
  'win64/gd'    { $checksum = 'dde852c979a4937b056f2bb184a0e8aeb3716238e07ca958d6407e50fb170df5' }
  'win64/gl'    { $checksum = 'f6d3f9edd53960e5681b03d1bc2d3ca2cea89ed8313a969f90a5672c9fc15d7f' }
  'win64/he'    { $checksum = '5359d414b696286dfb76a5da5f84a9915c385b28e041634c5d0b7f5e37cb24a5' }
  'win64/hr'    { $checksum = '188cfab7a7dd685430a0682c7df7bcd87fe51dc8db16dbc45d13dc8fb1202ddd' }
  'win64/hsb'   { $checksum = 'e503f78e87983765ab797d32588976304925b86cff2c6c8c435e53beca74a361' }
  'win64/hu'    { $checksum = '169e1db001c15ca135b1a6d28f4740fb15aeb8a1a15e8f872eccd1eb53a14d05' }
  'win64/hy-AM' { $checksum = '57fb0107a7ea5340828552fc5122b1e312d31bb4a39bf5f4e1a7ffea93d3988b' }
  'win64/id'    { $checksum = 'd8da638b68f370e9ce962eb920d6629a356f2d6de4df2e0a9c187111903d6a78' }
  'win64/is'    { $checksum = '1fc57d9566438f2cba7acf3875e47c363d587595c4b967ffb7d590ec6b92c32b' }
  'win64/it'    { $checksum = 'b78ed8ff0beb2724f132d9b50bcb363bae27b75a5d2ada9a92505412426b4b53' }
  'win64/ja'    { $checksum = '6ae05b9a7386a4219f92eda28d564a666bb41528f9d026a75a42f148af741eef' }
  'win64/ka'    { $checksum = '8f7d53dfc36076e119098272aad115c70dab05f7d7651b063eef095adae19e05' }
  'win64/kab'   { $checksum = '81eb5334154e3a8dfd7c7a50e09142e70231f6e59e18efd29b9a57f444dfce99' }
  'win64/kk'    { $checksum = 'fb13da7146b82d66d6e73c0fd53383d4a67dc52f4ac02e8470458b81875ebfa4' }
  'win64/ko'    { $checksum = '4ca678bfea199f40ee33461589f8fe40515c860928096ad17ae15c507743bdf7' }
  'win64/lt'    { $checksum = '36d4d6c7156b5d361d74b408d377137683956a2a197714123429142c06190f10' }
  'win64/lv'    { $checksum = '565968d4c0eb97b9e05701653d8dfd3f076d402374c79fbdc2eece3e92eddd3f' }
  'win64/mk'    { $checksum = '084d8876f0e460b8ac5d093d3e25110205149d12896fdd4f11647f322b203cbe' }
  'win64/ms'    { $checksum = '88f54074e56de415b509dd8830f5ff63c4b5dcbe178f91802231bf5c750a2344' }
  'win64/nb-NO' { $checksum = '54dfe89b6de0ea5d510dcce801580dfcecb7dfb7909467629ea04512b51f5e11' }
  'win64/nl'    { $checksum = '098fc244bf34befde412d793407ebf80ba2528e99d4e0d57db5c3d8229111de9' }
  'win64/nn-NO' { $checksum = '57d49c0176117032c76c751cb6e0a0df81d61d15589e23eb6a09a14d8c2ded44' }
  'win64/pa-IN' { $checksum = 'c3d799f5b153e5fa0aa9b50fbbae53cb1ff14c25915389eb7feedd2ce3246663' }
  'win64/pl'    { $checksum = 'a3f79885ea79d865c60c67012338f32bc7b9d80d4c89a9df2d4e3dfd839aa8a6' }
  'win64/pt-BR' { $checksum = '36e2dd85ef92d8252874265723e0d11faf7a3cd8c20c30343d0e9fc2a333a88f' }
  'win64/pt-PT' { $checksum = '0795c7862101adcaf17ec8860e25f59b250f9229d8bd4ffb7e3aa25e546d7cec' }
  'win64/rm'    { $checksum = 'cd135717378368ed91da304394c57be8eb52a3d44b8ec2c6d8dd22ad9c6d8f32' }
  'win64/ro'    { $checksum = '349531e0302b0473876907e5d414e882f5b395b21b465789f85e7f9931b07f12' }
  'win64/ru'    { $checksum = '840ab0df3ce204b0f95b598dc3ea26ecea658542a358e39d267fb24cb0bb6507' }
  'win64/sk'    { $checksum = '224dbb42ecea182078c36b5eb36cc90ae24489ab9e8a7257a71b57fd6cf7aeb6' }
  'win64/sl'    { $checksum = '3390f330fbf141eae84c4c62ec145a132076d8da7ddbbecd913b6493af3391ce' }
  'win64/sq'    { $checksum = '0d64771b4eb3461d8ee757d07299a52bb95a54290b36d2d04cede1f50ffd756a' }
  'win64/sr'    { $checksum = '0c2bbfc2994e8cc2612a9cf0c022a4958fa225f9c48636f6ce7b29c6822b4786' }
  'win64/sv-SE' { $checksum = '3ecddecbd990207e820a9e1508d33ab150472aed04ccbf99cd3f4926ebc2fcad' }
  'win64/th'    { $checksum = 'b02728bedde60dfe50d7e03d9ee8f156e143259286a6e37a2bd648d8c7d2c908' }
  'win64/tr'    { $checksum = 'd30f0376ad9b24311e853905f920a6400271c3f2f866b8a8a46ca4bc79855e2c' }
  'win64/uk'    { $checksum = 'ae0d099a3b4691806265df8e97415324b776268b46e39e8a01942acdbe622174' }
  'win64/uz'    { $checksum = '92920f0daf370df978f81e7a70bf69133553c1ce711901bcaae6de16420175e3' }
  'win64/vi'    { $checksum = '53222897c441cf7d6a405a9ed03d5be496ed8c718ab8a1c996faa035e3b78a36' }
  'win64/zh-CN' { $checksum = '67d700e2cc1ebba7fb1e5dcda2cd91fcc7b2b3137ab073a366550b8b1e645b31' }
  'win64/zh-TW' { $checksum = '378fc1e54961cfe4acb8f686febe4e77b464ba3527c309e2302ea1e3649b863d' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
