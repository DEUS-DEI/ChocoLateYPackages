$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '160.0b2'
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
  'win32/af'    { $checksum = 'da3c52257e0d8d8fc80a46bbce237859cb6d5227536eeffbfa92c6724db973ee' }
  'win32/ar'    { $checksum = '61321117eaece059259e4a6715996f37618ff4ba211d4bd54dfcac2ef787d933' }
  'win32/ast'   { $checksum = '715a9a3a970a5f412f5fa4ee3185d6c8c367b547528eab36ddb65cf4d4ba9a37' }
  'win32/be'    { $checksum = '55d66c4822ab3d9d1c8055f67f20bea46cc71a2748a8ba700aaeee30f9820f22' }
  'win32/bg'    { $checksum = 'c01d3f6158ee77b23a95f401c97c954d5c31989589b8836671ba2b252a25307a' }
  'win32/br'    { $checksum = 'ead3d645775f98c619ac1e3c248fc30b3ffeb92b69c481d3659ce6db6ebd61c3' }
  'win32/ca'    { $checksum = '359bf08732251f9955024a3f335682084dcd1e67cea23d16aa0eb7411e2bae88' }
  'win32/cak'   { $checksum = '80bb9906ef07c0a556d2216c98de45e9b9e001163c03bc3e9ceac51499251c89' }
  'win32/cs'    { $checksum = 'c88af2a2946a2aceddd3233e9708fae2fe1dc8f2c27f3d23274adba020117691' }
  'win32/cy'    { $checksum = '0d2a6b272b7b3cbfd00b14875c95b54ebabb4d336ade81b871c0a30127d0e9f5' }
  'win32/da'    { $checksum = 'e11565d13357eea85c51eb79b41477fcb978a910eaac47943b99629dfe3d634a' }
  'win32/de'    { $checksum = '195852fe50b17faf4cc3712fc97d6156b19522cb9e6a289453ef669805998d9a' }
  'win32/dsb'   { $checksum = '88c59df8d7414b59bee9fac08633f69e25b14cf278a0622b7b5814e54cca6f72' }
  'win32/el'    { $checksum = '7956d92933eb80bebc35e9b1a44cfcf9d43453309ebb1426612964d6bb5a4581' }
  'win32/en-CA' { $checksum = 'af5ea31b8b2956c35a2ab48868451006a0149621de16ab6cf6ba444d88efa56e' }
  'win32/en-GB' { $checksum = '2d261ecefe68d71bd2ad272bbecaea9f1e4bce28ae872deb14ff372f37ae0dbc' }
  'win32/en-US' { $checksum = 'a0071d32304e5c1305883dddd8f4da6bf660e67c6146352afd181fd94e1e33f3' }
  'win32/es-AR' { $checksum = '38fd27a2921f0a163ad7e865645ce13c8a6a9a5b307dfe4fac2f5a5e350eac26' }
  'win32/es-ES' { $checksum = '8666bd65460f404d0e8c53534ced0dc190ea83492e6cc35803d7f4ffd4a77986' }
  'win32/es-MX' { $checksum = '2dc84d25aa3fd03b1cf7ec5cdf1b435f09e76516e21c56c452bffc24e4edeed2' }
  'win32/et'    { $checksum = 'b05fba14a5be70664c0a4ebcf68b36b1ec6a93158a3a33826601c2dd6c07f7ac' }
  'win32/eu'    { $checksum = '78fdc4d4396186e64728145f3c25707921456fdcee3af60e2491ec32f358664a' }
  'win32/fi'    { $checksum = '6057bb73ad89f1b2ab3a5af8dfa5a3a8274620eacc518829c67072d43c1907bc' }
  'win32/fr'    { $checksum = 'e46914c6d0d0d81f70fd142cecf40b40d841686512b8364af64ac2fb2bde64a8' }
  'win32/fy-NL' { $checksum = 'fee174af6b8c053dc6c7de2637bc5bea5c89743f6809347e738d9c865c3e3edc' }
  'win32/ga-IE' { $checksum = 'b87bc9e9443033b97b92e37e2bd06fb416f1a42316cc0dff9f9aa955b48e98e9' }
  'win32/gd'    { $checksum = 'dc10fdc822f505201723f5fdedb94556cc9e8a28317c1e120c57affc76fa2039' }
  'win32/gl'    { $checksum = 'ae8e700a86dbbaadf614bcc8231811e0890b178890c4de9ad408e4bcabadb8c7' }
  'win32/he'    { $checksum = '11a4f5efd386cf982caa5ed7bc2f20ddf186ae1b50642690afddb119bfa85b8a' }
  'win32/hr'    { $checksum = 'a110d9acf53d933578887c66a714843a98cde746699b54a43b819a4420da6c29' }
  'win32/hsb'   { $checksum = '41f2536903735d851670cb3e9a54c53a6d41d38c7d490aa439a6da2a0f976060' }
  'win32/hu'    { $checksum = 'ce15c8fc7e84afe0a1af2ee65374030dba01aab23768ff173d8f344a27668601' }
  'win32/hy-AM' { $checksum = '0498219813ade4375ab911ac0c44cd724b0ea3ade3126533119fddc1fad86244' }
  'win32/id'    { $checksum = 'f6b03a9d6ee3c111d852e0c04c082d1df0d3a409902242cdcc820b214204ee25' }
  'win32/is'    { $checksum = '16e35b73d70a9ad6c794cb7482d29e57a22ef7ad161b01975732e1a422f897bb' }
  'win32/it'    { $checksum = '4d2660b2133e6e324b068d88b09c9394a0529efae73705accf82909e5b9082c9' }
  'win32/ja'    { $checksum = '2e9a89a20ad3dd761bbfb10d1d1a1144c7fa2449fea9581f809208df87c290f3' }
  'win32/ka'    { $checksum = 'eba473645e00bacb43c5b0d31af7fce99b8bf11f900cd031a43b71852272ede4' }
  'win32/kab'   { $checksum = '11146339f8d7783c56bbd45e79a3e9f4eae8b987c4f92820f0d7a1be43f1acde' }
  'win32/kk'    { $checksum = '37002907bde2da4a3be0f8aaa175a54aae5376b92518aff7f0b84fda2ac7b999' }
  'win32/ko'    { $checksum = '48356078f5672a8b7ccbf8763280162674f0a0de5d49d1014462026712ebf319' }
  'win32/lt'    { $checksum = 'b7c98b2a77e5f56b2da2b7e280a2dc13276c8d527c87cecce9e36f934c270162' }
  'win32/lv'    { $checksum = 'f78eaa9b173e303ffe39945e475697c61cfcf253bc5be8868d691e4f87540961' }
  'win32/ms'    { $checksum = '4cb2bfb2111c881ae951de0391269821ffc3d543910cab78ce6a95fa2b920fee' }
  'win32/nb-NO' { $checksum = '2e88bdcccf5b7fed6a35df0209bcea22036da02062577916849defc9ea3db3e2' }
  'win32/nl'    { $checksum = '3362c65db0b7418938bcc607adea150bc6829f8ce7d4f603eaddcaa36c881d76' }
  'win32/nn-NO' { $checksum = 'a1779ddec000ab4c64cefcd9a9be77df4ed18e04947729d2bf48300262b3ad85' }
  'win32/pa-IN' { $checksum = 'a4d69ad737b68fc97ba23db82b2ca7b55a0a0f03dd8312c9b30dda077771e2f7' }
  'win32/pl'    { $checksum = '5d4e67317711012c7fb1d8fbeec5d91d0e03f4fe61026ec3bed13ca2f065b292' }
  'win32/pt-BR' { $checksum = '2e71c1cd42d69b27b29b396696843934b132abe1712471c89433612ac863de0e' }
  'win32/pt-PT' { $checksum = '5486d7db6a62446f1a37cc787d1ce05c1953884166b49dccdd754259477e2217' }
  'win32/rm'    { $checksum = '769cbe39a999f4a35ef89f53b30f89f2f6ad269c64c23040373eaf34af5b6cb6' }
  'win32/ro'    { $checksum = '6c3ceba553425cd97767fb7329a85ca9db4672ddd963be9cfd8f6b698f686dc1' }
  'win32/ru'    { $checksum = 'ce1f2958dcf0acad5e643e8983f0e855f84148b1d0d662c0d04f616acda6de87' }
  'win32/sk'    { $checksum = 'e747a1df398156d0bd8dbdcf16bfae965d4dfaae90378d532e84b983b97300e6' }
  'win32/sl'    { $checksum = '08060d3742114b4e95e7a0e30b772bfbc3f873a1dcc54198c08748f9f2d1699d' }
  'win32/sq'    { $checksum = 'd0d1a0abfa32555f6921455929937ad573bec967198e8a6e460850fc3613c8a1' }
  'win32/sr'    { $checksum = 'b35346af51cecd8dfbc062f9637bb6cba3e90890d7871de310eb68403b3151e3' }
  'win32/sv-SE' { $checksum = '10fd3137f68bddb6652a2fe6f55ddb6f3df13bac29d97bcfdd0ab89a475f1817' }
  'win32/th'    { $checksum = 'd153367f5148b0077ce9239b02a6d683c69e8bea39df724b63dc6a44bfe4a8e1' }
  'win32/tr'    { $checksum = '23fc634399ed8a33c9175afa68c8f6363a6bc16772418680bb58709c6e27ff2e' }
  'win32/uk'    { $checksum = 'f321378f4cbf9f696eba9bec18bc66a0510830aef591c479b2c704d821db5147' }
  'win32/uz'    { $checksum = '86b0bfa8a88d72c2645fa89ee497baf79e75d99bb3bf946712ed3a4e5956c041' }
  'win32/vi'    { $checksum = '5b6620e51e389db2bd8e8f3f1dba3baed1cb9d433e8e98329b1bf25b2b0b45dd' }
  'win32/zh-CN' { $checksum = 'c50d7e76e46666be9ecd10a3cf7bd2f6ae9a3d03af881beb1ace460cbffc5ba1' }
  'win32/zh-TW' { $checksum = 'b5e1f88223f85a1122636fd1de13ff366abf24e1cbb3b02dbf50263bf6687b80' }
  'win64/af'    { $checksum = '7cf7645467399b182f89729e67ffca29e85a67fd52afc963d26b1e99af94048f' }
  'win64/ar'    { $checksum = '00f9b6eac5b020edafa7801311ee2832271f5a05348c6695915a240f3a187c51' }
  'win64/ast'   { $checksum = '95c2e116acb81bccb68497fbf425dfb75d5d033eebb094506c9c95334c168461' }
  'win64/be'    { $checksum = '96ec6a113d7fb6fa3fecce4ac436a7270336bc89bcfed12c3e96f2b0273ab0ce' }
  'win64/bg'    { $checksum = '78131e206d1ce4cf4e0650be838b0046863a28549c095a41c953fee65e0724a0' }
  'win64/br'    { $checksum = '7a01c69fdf104576d68ab29945b5f5b1834fcc9b0b4aaebe3731842cf0e1d720' }
  'win64/ca'    { $checksum = '9d854b9ae6229e3c1ee09cee9ddbdd8b445b48ee7a2072eaa9e039924f965269' }
  'win64/cak'   { $checksum = '2c0024fc4b43c7affd3ad15e5e1eeb99e0638fbdb63df1b2399137b2aaf1723c' }
  'win64/cs'    { $checksum = '321f222295007046f9389943f3706a02d26eb31393c4a1c8f9a775490d365018' }
  'win64/cy'    { $checksum = 'a935a6252a08a197cbcf5b45c1723a1e1b32d654a09b00a96334fa7c88e93c5b' }
  'win64/da'    { $checksum = 'b3fe0f786d340e3545c6f9893994cd24ef1365adcff009691b86eb5ab6a6310f' }
  'win64/de'    { $checksum = 'd515d557f507e9aa83f96d2a2c78817b897bd35671de9f613c2abfd3ecf05bac' }
  'win64/dsb'   { $checksum = 'c4bfe3702d340897d5c6cdf73c5c61d27d66615db35fdb7fd318578edf6cf6f6' }
  'win64/el'    { $checksum = '8158f1ec4736644fc0b5b513c7ff00c93736a1036684354d699a32cee4ea8672' }
  'win64/en-CA' { $checksum = 'bc03c25d05d0a0d800bd22ab13484ff3bc3961fdf0ab72eda95c73878767bc8c' }
  'win64/en-GB' { $checksum = '47311bbc98471fe859e8ca92f7477c3f613a62650b3e75653529317dc435a969' }
  'win64/en-US' { $checksum = 'e90c21b6a38cb2f3b94900da65f042409795a3a77dcbc3bce68b975f6a8c15fb' }
  'win64/es-AR' { $checksum = 'c227ce8982ea62ca95de00adeeeb3998663c8d05cc5c9f5df042259d738e9184' }
  'win64/es-ES' { $checksum = '2f5c1b0157850413812575b318fa4df72dfe8aea6c69d33ab8e31875feb1a0be' }
  'win64/es-MX' { $checksum = 'b55b5d841da121d141ec6f934a3822a734faa5ab4c88d2e39776d16ef601117a' }
  'win64/et'    { $checksum = '77ed5b05b4797e677cdb0819cd3e97b432d3a8b3356a51bc9cec26ac0ec31484' }
  'win64/eu'    { $checksum = '2f56b10586ea32562e8469f5f09b0cde8246acfaa4bb4f34cf3fb5686e8b0f6d' }
  'win64/fi'    { $checksum = '93fa110b9c4722ab2cab9c5c1114476cb166564e1c6af2f9a12e5d23116b5dc7' }
  'win64/fr'    { $checksum = '08861140be2c0dfefc7729b7f5cfea696fde10a211cd9c68db7e50e7d05e817a' }
  'win64/fy-NL' { $checksum = '1bd4bd5f636cd1fe7e5f9a01e890f26de72489d7d39ca7ac3fb085740e473fc0' }
  'win64/ga-IE' { $checksum = '890ff73e8a836ad7a2dc8d9a3d8a8e3d5c91cc5fd0f8089651289c768c3c556b' }
  'win64/gd'    { $checksum = '848f9313ae63a56fcc7059aa4ed04d24701128faeac35f10d9d3c8d61c4b8c7b' }
  'win64/gl'    { $checksum = '773bd8cfa0ec7d917394231f80ffbdb45dfcc036e503ff4fb513eff85d3f276b' }
  'win64/he'    { $checksum = 'ef1ed2b1043cdfe1dc9b97a0236ee495338b2da98e219d759bb04d9f4217383b' }
  'win64/hr'    { $checksum = '5560fb2b5d918c218535e66cc4f600769c739869b59a0c29718ee2effd27b0f9' }
  'win64/hsb'   { $checksum = 'f29f846449a52b5fe87aee2b4cb771b382747ac94879e4c49ac15f23ecda7873' }
  'win64/hu'    { $checksum = '01396f1f7a72ad22aeb27ea74bad7fe987b6f801b85bf3aec045e0044bd30f25' }
  'win64/hy-AM' { $checksum = '79a1ea06525aaa0d2b1b495cd6cde84c67ba7a593941bdd7878bcec178bf1257' }
  'win64/id'    { $checksum = 'acae6753c68fd11127c05544a048ffe6033b202ed93723217b2efa1029e638ec' }
  'win64/is'    { $checksum = '0f5ba0385caefb5f898e52b8a6b28948b9836565badec431c4a762c81a5597a1' }
  'win64/it'    { $checksum = '7e4e2e5ed5a4624f88e400b8243161545965adcb4b0d11bd256c579b12374eca' }
  'win64/ja'    { $checksum = '79637a8c7a48721a1328686702a0f088b9ae72560836092c30927512162a8f45' }
  'win64/ka'    { $checksum = '0197c9d975c3207c4818d684547adfe298ee1868f74eb86d34aef33c71122ddd' }
  'win64/kab'   { $checksum = '46519ecd325a78ad7023c2588d6ef79e3025888578c8db875cd4bd28be0feec4' }
  'win64/kk'    { $checksum = 'f7ec6eabcb5baef084a1421098b7a08cc41f670c3bb3fdb936074d0e6feec5c8' }
  'win64/ko'    { $checksum = '437d433d69e307ac94a59bcec10543eb52b64da131a75c7ebf69e4344b20e9b4' }
  'win64/lt'    { $checksum = 'b2bd879b6aa2c30773fde78ea039a62c9959f0c130ac2e8e9054c532a3511243' }
  'win64/lv'    { $checksum = '9e85e6456b1f0f2d876534d85792904b83d0be02ac27ea4a00c7b62e2a33e085' }
  'win64/ms'    { $checksum = '7ff4e711da0712bd589901c8ccc8fc4d57f26fd601b8881ec2189e3d2cafea20' }
  'win64/nb-NO' { $checksum = 'd907736589744d34ba5206f011975e21ffcccfb8a7fa7703aeb824e1949a12b9' }
  'win64/nl'    { $checksum = '49c3419131906644b411bc896b4d229d51023a2f362cfa7dba04bcb47cbe2d53' }
  'win64/nn-NO' { $checksum = '4cb0dba0eac92d8b7b3289954b8a757cc416cab9c71e5f586c2be9695fa4db43' }
  'win64/pa-IN' { $checksum = 'a54947d77a9e7fa0b12a6e99aa09b593b310e58612daf788a13b3aa9fcafe12c' }
  'win64/pl'    { $checksum = '9f9676737667852639351c6eae1818ef11e2b11828393eb865b8e5e285920ce4' }
  'win64/pt-BR' { $checksum = '22318ce14ffe1c4a8328e9a3dffd8f14f00588dae0af2457880ea7923e8d29b7' }
  'win64/pt-PT' { $checksum = 'bec05a5fb1bc6813068fe3d9f5d92a388425afec4bec42fba9afa7e7f48a088e' }
  'win64/rm'    { $checksum = '443848a58b92571a88edbd2778785691e757321166c8555e968448c78cb9d108' }
  'win64/ro'    { $checksum = 'bd7d3a63556b11848ad3c41ca36280831618c78acd95007bac9e6cf59ae2f4bc' }
  'win64/ru'    { $checksum = 'b71304beea1f73e1c2bf7402cc13664e91aeae38a085dcf8d550d77641414b07' }
  'win64/sk'    { $checksum = 'fd614791e038c54b0e3f645dcafb8b4fe49471429cea017bbf6f9b050041fafa' }
  'win64/sl'    { $checksum = '3294085bf5d3bff9406d4c011d1205f770ff192fc4bf7c198667bf716e724552' }
  'win64/sq'    { $checksum = '1cd28d9b0a90a2ea400aeabd09b1ffd7d36b8457eb25415ee9a8aaa1708968fe' }
  'win64/sr'    { $checksum = '7f222ccbc1be7eb245bc4c126af1a4dc7a58d4e4618e18457f0ae3fd21ccb086' }
  'win64/sv-SE' { $checksum = '4ba9ef00788bc4fc083e5e019fc4e42ea36a1ff586a21fa0ab2d5c7b28618413' }
  'win64/th'    { $checksum = '6abe35d0550568258a0ab5590296d2457b4ad9b60f032744ed541636961b935b' }
  'win64/tr'    { $checksum = 'fd72a6d853f52cce3cd7ee6aec5ca259e1401b69daa3f0776cb10006d389e572' }
  'win64/uk'    { $checksum = '30e20c4220f23e0f23e6d652f983d58ceab8004195e094568e076550f0db08f9' }
  'win64/uz'    { $checksum = 'f4856c4c787d1e9c83d59b1dbe4dd29c1b8dda37c82c6fa663ae36f234dda216' }
  'win64/vi'    { $checksum = '31740a7448b6b55a2b53c6b98dee4e1b4965ae73ca65fcbedfc25f3da1b6be74' }
  'win64/zh-CN' { $checksum = 'a8d12ae300855db5f7d145586c41723b7e5f8fb7cf16b4fbb13c5cbf1a342bf7' }
  'win64/zh-TW' { $checksum = '0021b16ec13374d57e11529793e9c6fca537a146cb2a439116c2d5ab6b126a92' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
