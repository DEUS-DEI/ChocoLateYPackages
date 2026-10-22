$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '159.0b5'
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
  'win32/af'    { $checksum = 'b5e12ec6d0367fdc1ef79d037f125b2783af47985a0feb6d7f240d7a460bc9b0' }
  'win32/ar'    { $checksum = '4207379c8d37b976f3c5e9763e8b03c6ff64e87cea5b3c545575a52bab41be99' }
  'win32/ast'   { $checksum = '10e3641f9c666adee992a2c7188631e80e7b9432d2358f4d11fd45f6ee17073d' }
  'win32/be'    { $checksum = '76beb5152e998db10d85f5ca85865bbd51b46e8378863e63bfc7aee4e632cfab' }
  'win32/bg'    { $checksum = '404616b1630bd8c3fa0f3014d10006bc95efe6b1655e5301622dc90c39b1429e' }
  'win32/br'    { $checksum = 'fc27e0ac65d2681ac6695606ee273e14a211eb622c646a1bf9b2b19f5da553e2' }
  'win32/ca'    { $checksum = '255a0dffa083de7343215a3ac66cc2f89128df6ecc1847a2e58e7921df3a92ed' }
  'win32/cak'   { $checksum = '092737e835ac2345f912c016e661f84c1d9768f73d34c85c589d06c00005b705' }
  'win32/cs'    { $checksum = '785b65fdeee2bf9c410c50ee12d8ae90dda858a6571ed04a19bf13d171378e8c' }
  'win32/cy'    { $checksum = '48b6fd1562abd7105131de7eea5a4503658d6ae0a5bcca2d8f6024bc19275445' }
  'win32/da'    { $checksum = '5cdd640290814b98dce5ac8fcb3dcb3147903bf608ec8e8c8fd10087858b0521' }
  'win32/de'    { $checksum = '80988d448131cd34bd5cdf994ba218fa8d4569c030bbb73a5f77fe4a709382ef' }
  'win32/dsb'   { $checksum = '95181ef4e3deeef17af5edd58340cc1e9fdfd70a5311a353164c6928a17e7183' }
  'win32/el'    { $checksum = '297dbc23952f41b14cd0a805a64109ce6b49e6bfaccc8263314d272eebb0d408' }
  'win32/en-CA' { $checksum = '2a686f5f60251a5313003b1b7d8438757481397a07e8a91d20a6efad80955329' }
  'win32/en-GB' { $checksum = '2382c21ba26f00b584144356a7f104754b2489b6831ce2fd8e032d96091bd3c5' }
  'win32/en-US' { $checksum = '0e6622f93e8581e5e0ad0bfd1a51af58f0d6fbf58deb351d6d848cd5a867a283' }
  'win32/es-AR' { $checksum = '1b590e137f70d42f4c1de08890ba1d7858e6be28f9b98758357c841ff2311abb' }
  'win32/es-ES' { $checksum = '52dad4a11c49945da16c5ce572c6d055469b2d29754ac5e8b265e3440e902357' }
  'win32/es-MX' { $checksum = '315ee0f1e6c8f04a4a0da55d93402b9a369ef55efc9ff3bba66d4b9036c4ba87' }
  'win32/et'    { $checksum = 'e49cf896d8858bc5d966d4a4a0ba97f11443d336b099bbd50de785588162191e' }
  'win32/eu'    { $checksum = '2ca7b1cd8d793be601b40a28f0a9c62ad01bbe1ab6b7f6ce0f026f74d0796ea3' }
  'win32/fi'    { $checksum = 'aa75e2a036a5d0704c44babab581a50d4e2006bc0799b730fc2e900a6cae047f' }
  'win32/fr'    { $checksum = '3d02e96a3502ae6625266fdecdeaa7a471137ee7cf4310bfbbe2fe1ab7e5c223' }
  'win32/fy-NL' { $checksum = '29a8b8120985a3a51f93fa11f30d208ac252c263e0877630a3f4a09fc43f755c' }
  'win32/ga-IE' { $checksum = 'fa3d3364cf79ae36699d493fc7457eda682a3f9683eec51e2b6dab8f633d1385' }
  'win32/gd'    { $checksum = '6e18a21f1c6140d4ecb238263d26b6b1daad8f72cb166a6c0c08f30d60561a1f' }
  'win32/gl'    { $checksum = '70b4074513c2a25fdfd288d2c858e38a1976fac0b6c2ce6e22ce2dee7f9beb1c' }
  'win32/he'    { $checksum = '2841ba0dddf362702a39f306abc1b0bbf87379f926d30daccf6a35392666249b' }
  'win32/hr'    { $checksum = '509007389fe34d54699dc7b18707e5b3a9afa0508590ce917cd831d25e4e44e1' }
  'win32/hsb'   { $checksum = '6368a796c786340bf787da9ceb0eeec725a390783dee7ac11d0c4bb10a9b98fb' }
  'win32/hu'    { $checksum = 'e6965c6c63de7f39598ed2c4aee0ec4d7457901a31edfa9a1a91bc1c67788cca' }
  'win32/hy-AM' { $checksum = '591790c25a3cb1edd2c6a5de638d732902872ea1494ada659fd38404675fd420' }
  'win32/id'    { $checksum = '3b5db01cb5edfe051b987701e5c2f5e3cbfe745bcf6ff234e02a8c74b002145c' }
  'win32/is'    { $checksum = '469da5cf9304deff6b59a1adabd4482983e2ad10671e512cf19eba317ec464e2' }
  'win32/it'    { $checksum = '940c3eee07ae94ea90703abf53ea0d070333e355d451a2d0b46b5f29ef850b36' }
  'win32/ja'    { $checksum = '532a17fbf2470652b80f4e0aa9ae8a1d12eee3158218e91af7606135656e2260' }
  'win32/ka'    { $checksum = '1ac097a3ce1f19c26e44bda16da7b14997ed58acf503393bf495fddb5f5be45b' }
  'win32/kab'   { $checksum = '844efc07703f85b30db11f6ea546d0c419cbcc94bd9b9d4cc837ee570f33578c' }
  'win32/kk'    { $checksum = 'c22cc60bac8868f36d08f46ff7da793c13989170a7b4f233a806b09e40617f70' }
  'win32/ko'    { $checksum = '562ffa2870d445e00786e8c92943c9b834bf9ee0c45da6c4567f7355a05973e0' }
  'win32/lt'    { $checksum = '57d88d0717a9ac0cebecd5144cbdf0a691c389d43d3c16f57b6b02b0618a4f4c' }
  'win32/lv'    { $checksum = '147ef0be068e1fc560d971660556644a3edd1f255b3271a86cb840e2ce1bb731' }
  'win32/ms'    { $checksum = '10882b8b69346797def325464c3c7d563f5053993ea9282328b01fd59e83233e' }
  'win32/nb-NO' { $checksum = '4d524ab9eb2673329677e68d2103f8b30b761431d0376747960e99398a970156' }
  'win32/nl'    { $checksum = 'f98dc08c1d0077c60c64d300b08b4bc601a9786a3bb457358bbab12c95ab1e33' }
  'win32/nn-NO' { $checksum = 'a8958d7cf6a22d2392803ed318c0241840df770289964f2de9b58013a1d2ccb3' }
  'win32/pa-IN' { $checksum = '64510c158774321884f1f13bd23a791a28f6e4daa80d309a081e2a3a78f835e5' }
  'win32/pl'    { $checksum = '9d6d5a24534bff7a525f02f570faf4d6f596b4c2e4e66fb5cbec9ecf43eee0b4' }
  'win32/pt-BR' { $checksum = '1cddc79d2cd5755845291a022b8914d1e0c9d1103698f1046cf396ea62271df5' }
  'win32/pt-PT' { $checksum = '1fb4d2ad62e8523ddb1487bff37ac1ce664172ba8fd2c80ddad5587f5dce2192' }
  'win32/rm'    { $checksum = 'a38dbd54f8270d16e25c98a3acf707677c5447828d746363bee1b087b103bb68' }
  'win32/ro'    { $checksum = 'd287a90d15e7c680ff5826627527948a778a0a774a0da6adbda4527027d59837' }
  'win32/ru'    { $checksum = 'ac448a9193e2afc9753a0c4e420954aeb454af2c51bbc02f3ae27d641672ab76' }
  'win32/sk'    { $checksum = '9435861246815c371f18fbdd70773242e9c325682c056b5879a57b7a97a79da2' }
  'win32/sl'    { $checksum = '1ceb89f83c27288888deb07457df49e317d1a51e6334aa24e43adfdeb4ab3f72' }
  'win32/sq'    { $checksum = 'de74258cf0e86b2eca9b433c3f12ae28851d46b09d3e44185a1cb48d74531c16' }
  'win32/sr'    { $checksum = 'cb22665e813948a36e89c98a974d7535e6e99f49c8dd6a3122f7be3763075c18' }
  'win32/sv-SE' { $checksum = '70ef53ba60c30242d6a28b33d1a16834ce5f498be83f2e402f69c6edd839422a' }
  'win32/th'    { $checksum = 'eae3c21f4c37186ff4449c836c611bf823b4d0ab83f082eb9e0271def782bcb1' }
  'win32/tr'    { $checksum = '679436b646f0ce15ff4944333046645135b7ca54869823ab791f27965ea8a742' }
  'win32/uk'    { $checksum = '50688fb735db16d1fb90582e85e38bdcfc6c900c8500b686e03285c54411e238' }
  'win32/uz'    { $checksum = '6e7e5389a1b11084d26289b18e56473a312eaee483311fff94ffea34563aa01c' }
  'win32/vi'    { $checksum = '7fd4f7d5972850f4fb0de4d891371193c3bd7fd4f148d1b3e2232a8c2ac9c92b' }
  'win32/zh-CN' { $checksum = '702430f28dfe8e9dd93da40a3ac7460c430950d736b6847fcec3837dfb24d626' }
  'win32/zh-TW' { $checksum = 'bab01a15e5140fd79a489995c6c9788e38199d4e0c47243ee252e66d1ece385c' }
  'win64/af'    { $checksum = '69c881e60768fe6c3564ad8ccfdcb6f29e018ed2577275b5055d1f3fc17759ea' }
  'win64/ar'    { $checksum = 'd01cfe6e49873c4090a73b081f4a09492de6449b240d35682e96c79b73726278' }
  'win64/ast'   { $checksum = '8c19036663e0d657858e771b45e175bca62b0930933f3b2b65b18f975ed70b18' }
  'win64/be'    { $checksum = 'eb2cdbde0f23ec06bba3ddf99b694ea07174776ea90134549aa7a92375adef1d' }
  'win64/bg'    { $checksum = 'f1aafd491ff8557d40dce889315b9c09d15d7b6ef9d682bfe3412d47ac4b8ed7' }
  'win64/br'    { $checksum = '25153abb6da50c09f1d4297f6a2f8c1c993d7d920f969b0192aae3cbdcf59e26' }
  'win64/ca'    { $checksum = '2de9da454f05687ffbfea0e5e82c1a4a100db3ad3b6268904498460edcd2dd51' }
  'win64/cak'   { $checksum = 'b754aac3a232b9020fd99658eac039553c51007f1418ee840dbe375d82a3273d' }
  'win64/cs'    { $checksum = '4dce8e15a62ccdf7d4317ddfc927c81a90d386279902065a998b144101992af4' }
  'win64/cy'    { $checksum = '70e8ea449e4aef65e5e1c73b84142196c5d983b1f693b0dbf4be3853bca1c34b' }
  'win64/da'    { $checksum = '908b1ab051219ea1da508d41dfd277399d9817dd402e13cd4149cb5402ac7de2' }
  'win64/de'    { $checksum = '97644ef6d5b38b25547c0466943a86afde6e118aeab6c7c9c3e169b9fd5a1623' }
  'win64/dsb'   { $checksum = 'e928870319b4e0420fd5ef5589d94b46d9f63b6df10fa9781dfcb1621751d21f' }
  'win64/el'    { $checksum = 'c876e158e159e4c028e7968262bfd3ea4b6990d757aa40144d1b5a94a396875b' }
  'win64/en-CA' { $checksum = '911f99a114c95d9b5be3426be45d60a40fe5c79669fe0b86a246820eb1d7c145' }
  'win64/en-GB' { $checksum = '3225e5511280ada6b54e25e83eab6552a42a076a79438270521f314d7001b6f2' }
  'win64/en-US' { $checksum = '0dc3876186da93d842a989d48f275da73841194c1d7ce3d49a4b3dc93d9c4284' }
  'win64/es-AR' { $checksum = '412b53d516c8cc2675b4de3777888562f4e1d65cbc0f785ac8e2cb655e1ddc69' }
  'win64/es-ES' { $checksum = 'b72230f92d42469e864e4be80876032ddd8dd02051e8d2449142bf0843cd929f' }
  'win64/es-MX' { $checksum = 'e98a64043cabb40555dffd6ecf0a5d7442591c9810b36fff34773d077f40aeb3' }
  'win64/et'    { $checksum = '9381d077e8dae59dd7c8aedb4414b85ebc2b478e1b05c06815139e59d76106b9' }
  'win64/eu'    { $checksum = 'f9f9f977c7fd6f3a46206b7c49a2c207d90ae36a244c8cea72da58362c5ad6f1' }
  'win64/fi'    { $checksum = '7a7dbe6814f9ad8f7cf3b08e13512da7733bee3857f9a94badf98cab4babe575' }
  'win64/fr'    { $checksum = '538e79c6097d8aef0f8d9d84583e77d13665d85e779a7f0ee04a096f8a12bd3e' }
  'win64/fy-NL' { $checksum = 'd2b78971f2cd4dce2498801b616af58b0e6839996274817d817976b07aa45348' }
  'win64/ga-IE' { $checksum = 'e83078a071acd73b03f0ea19edd0c9a8ff778d59f7713d04b0ffbf7fac6fed87' }
  'win64/gd'    { $checksum = '219111533bd48822a166ee756f6e6a4cf378d1a80239cb43f21cf497d958aebd' }
  'win64/gl'    { $checksum = '41f8a30aeea883e17045996a4d526cc332d2e1246bc1764a05db830a073f461a' }
  'win64/he'    { $checksum = '49f480e66384fcf6f42d1ca81ea26f25384c6a08d269ae31ebe6a3ec0f4c6b55' }
  'win64/hr'    { $checksum = 'c0b2951687cb41f70e70029b81df1f2ce186e43231228e05d7b0197cbd5382b8' }
  'win64/hsb'   { $checksum = '9ee48e095f283a2425166d9ce6adc7146b58385334986ea28b8aeab38b628c1c' }
  'win64/hu'    { $checksum = 'fa3dd7c81f5ca056e7b2fd9c91ddc46946340e9f86df3c3fe1d1e0c077279785' }
  'win64/hy-AM' { $checksum = '323e13bece41634df6e93fd2f6526dc68f90e1828adaae45758d5d27925863a9' }
  'win64/id'    { $checksum = '4a29609fdc51f9e817d1dcc9f20211f105b2d491186801015ce00a7da1547a8d' }
  'win64/is'    { $checksum = 'a14989405cb6c80cb7a8447f3752b065adf5c06ba7ba14224dc15bd7bd2bc4f1' }
  'win64/it'    { $checksum = '98032e75348b87d559ce6a2894d40164467f03bb48280c29f3c5a764b142c412' }
  'win64/ja'    { $checksum = '128893918ca701eecb0bc524b18c5cd89d75c52476702d45d316ccb221f172f9' }
  'win64/ka'    { $checksum = '12ff9683b811cdeb2de71f3a7c529ab33e8f254170e13b15def058b7cb7679fd' }
  'win64/kab'   { $checksum = '2adc0622b8512f0368c2f1d1534b5da0244e4ec58f5716e4f188006e5a73d23b' }
  'win64/kk'    { $checksum = '3c00aa1fa977386b0122ba1f2b8fd9e03e89c24b2897d48fa580fe6baf35e6bc' }
  'win64/ko'    { $checksum = '01bbdd0c52fdfc1b4f9ab0a946cd945f17217cad18a4d0a42fc4ed05c5b641df' }
  'win64/lt'    { $checksum = '49bfd21e6e652a7b1cee85b385556b63247e39d5bd19465345c67894beffa31f' }
  'win64/lv'    { $checksum = 'dcde5346a4633f0f69fe974e9889056441643ee0e5ca810c1f03bf76bcbf7198' }
  'win64/ms'    { $checksum = 'cbddc527111cd87f654d1248260f27d51dbedf48da184a16742795a7c8e50488' }
  'win64/nb-NO' { $checksum = '6208ce477d82cdd6880da299d1e2b21de3290fccc9899fe7fd1f5a6d38278476' }
  'win64/nl'    { $checksum = '44f996ced1d2a1b0a3825b977db3f7c7ec637f804baf680ddbe2ab7972edbb7f' }
  'win64/nn-NO' { $checksum = '42731b41b7e602d88e2643ab2391119a080f11fcadc705eaf28a9267adfd3943' }
  'win64/pa-IN' { $checksum = '22b10fdeed6b132e9cbb17b2c01b902c5ec33fb36626d78d5d3eea2ad7c88056' }
  'win64/pl'    { $checksum = 'aab2e22b7e4f74a8973f56e4581341381123b1427c6c36a43fb33d7f73ae5f46' }
  'win64/pt-BR' { $checksum = '113a68a4b68857d52512721f9a8b585af3d95e87145af8c36bb4d370831ca253' }
  'win64/pt-PT' { $checksum = 'd2ea74786bd235679fee87a203fbc2a99d1ee56fd5c68a3f40024623f76b3868' }
  'win64/rm'    { $checksum = '3692cf90c2ac2fb80e8d5fb33b9b00b4df4a69dd29d5e8f93f08affd93ae25fa' }
  'win64/ro'    { $checksum = 'f7e2f5c2223357709bb267c3aa1b054068f03a91bb14551ce16890332c98a78f' }
  'win64/ru'    { $checksum = '9701680af0b74f4cd261f96e687de331666560ae1316a76bb7e01909ff93612e' }
  'win64/sk'    { $checksum = 'e8da4aeef82339a2d3c519c8372bdcf1412f1b591963d2c54c2475fee6bf84a5' }
  'win64/sl'    { $checksum = '929a010ae5d6242a7e4d4a07bbbf2679c40731504147aacf402c9d3f0d08a91f' }
  'win64/sq'    { $checksum = '3c591b8715e15bbbf9e5149f26e9bd5a3c803623d5e50c018bd29feef3501516' }
  'win64/sr'    { $checksum = '80b202d63f173016bc9b5ed443e5a5f986263ca5157ccb760ec23de886e1f901' }
  'win64/sv-SE' { $checksum = 'df24b0baa088d085df9621231eb27578d67354fc309a1462952acb1e28f16d51' }
  'win64/th'    { $checksum = '38ae243654ac4ee6d68704bb2eee99ebb30b5f21b83163a89a049c93cbc6b637' }
  'win64/tr'    { $checksum = '2d8bf0107c93a20fac78b534e71cdfaf005197aed2b2d2c34d3e6db4b943c80b' }
  'win64/uk'    { $checksum = '30375796f3a7c8a47b938cbbb11f787210cf1392b6b462fd28149cec8d3a1600' }
  'win64/uz'    { $checksum = 'b5537da40510a629d9a376e8e4a504f9f206a55306b0f150d660c71a8a484499' }
  'win64/vi'    { $checksum = '1e795b584eb8a3aa8b3cb301e1787ea3ee8a79efb503b00018afa81ad0c5c41f' }
  'win64/zh-CN' { $checksum = 'ad17012fbb6842af30d50240041a9ebe28ef41324aa1e12d34a794e298bdf04d' }
  'win64/zh-TW' { $checksum = '0b3c9d3a426a946e6a2b1898c3e0159c5c58dafbfe854277dc7ea37a9c570d8a' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
