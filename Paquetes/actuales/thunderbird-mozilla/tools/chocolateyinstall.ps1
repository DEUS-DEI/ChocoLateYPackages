$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '162.0b1'
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
  'win32/af'    { $checksum = '189676ac455037762294b4ced2cc0ccd8e97cd4a9f27dd53b6c8662eaae1f1d3' }
  'win32/ar'    { $checksum = '64563fc8650e4c71ddcf03f3303e24d5493bf63f99b8870131a3ecc66aa5f63b' }
  'win32/ast'   { $checksum = '446c6c0d965f8d29f96f63123a1a73d84604173c220bf1c690c2eeb03cefc1c7' }
  'win32/be'    { $checksum = '9700fd29f0da3d5d6619830a3553066bc569a2e80a67795e6caf7d5a04e41029' }
  'win32/bg'    { $checksum = 'e8616fed47d882980b7c6a1f21e60ed916fea5d89bcad89a604bcbb711291f25' }
  'win32/br'    { $checksum = '229f07fc44cea8f917b3262083085e087813f82cc6507079313afe3945848cda' }
  'win32/ca'    { $checksum = '89ee418555c61cfaa7953dccbe16566855c08f54524938778b155dad1cd3fc32' }
  'win32/cak'   { $checksum = 'e246ab5bacdc35d04deced61f734faaaa98097a539d9bc638d80fe1b574f3fba' }
  'win32/cs'    { $checksum = '921b775fc20b431fe444a70744feb114f2b43994e8d10fc8519e70fdfc57a43c' }
  'win32/cy'    { $checksum = 'ef883904565855c597e2daf537cee7a6eaf302a28a4cc6725bf5748b78bb522c' }
  'win32/da'    { $checksum = '3492b8ca9a996e4c3408d1e9ab6febcabcf979200a689484d21a39737020df61' }
  'win32/de'    { $checksum = '3b839b82c0383de4e5e72d7428996257ae1bfd30ab7f2e9dfba88b8dcc2cb391' }
  'win32/dsb'   { $checksum = '339ecab5408d0906d8e3ba9ae784239307ccf33dfd738bc78f361d602b6a0c1f' }
  'win32/el'    { $checksum = '76ae236a747a544e95bb87b764c3d1a4fafad75ecc7b0119504e6cdb310a3ac1' }
  'win32/en-CA' { $checksum = '7b1b1f8914e678390c3f321c1815582a9c7e6ec4ad79dc162d432a3607ae74c9' }
  'win32/en-GB' { $checksum = '3eec5ef6e8c0763d66c625c439e5417de2cca54b9e6cc7f4adeca0c860e92e50' }
  'win32/en-US' { $checksum = '873f3e7b6debaa421959fd47e8f874b5360633344c2cea9643cfb7ee80a38f46' }
  'win32/es-AR' { $checksum = '3bce55543f359c5b8bc88d6568599a1fd7b18397e3f650dd9b75f7ddff7f22c3' }
  'win32/es-ES' { $checksum = '35dfc419271926b60bad62c30d61284649550efff20137f11cc930d7dcdf28e8' }
  'win32/es-MX' { $checksum = '83161774ea45687dc8c38fb4b42b9888163748931ca1e51eb882e2f9869018d1' }
  'win32/et'    { $checksum = '2cad84a3aab8bdc1f212c67f1f99dc0ade21758fecbbfac7585abcdc4e7f2fbc' }
  'win32/eu'    { $checksum = 'fa713dd4b6d6cec26d712175b5bbf09fc76a5aad310f85dee4e08354ade4c34a' }
  'win32/fi'    { $checksum = '6766017d8e7686680e292b0f7a0c81c73660ced0b261f87ef23a86bdfc71fb85' }
  'win32/fr'    { $checksum = '9dfa6bb890e119d85f0dd12c9270352eeda3c53a0d1193cb5a434878eb159176' }
  'win32/fy-NL' { $checksum = '880d7ce0924f9012d0aa2e1da322ef324c6684542551c80273c1e9d67c3e257a' }
  'win32/ga-IE' { $checksum = '6b21323127ef036c819987d4c2cbfc47bca28c2fd321a8ced72db1fba6fc9ac9' }
  'win32/gd'    { $checksum = '733537d138e8d22f926062709e1063fef084ec3fbaa7270d7b18bb1d6a50b151' }
  'win32/gl'    { $checksum = '967ffc050ae1c919e5c5b54030d16467deab9334dc12cb67970a827167eb2924' }
  'win32/he'    { $checksum = 'ef4fcb77a24d3cd1261804aca771acb4eb66b432aa7efbf9b3b479a471269c8f' }
  'win32/hr'    { $checksum = 'e399e1043c73e3bb311df3d4213bc0da55c4f85b0f2ab14e5ff4b63d7c313e27' }
  'win32/hsb'   { $checksum = '4c81b67b75d24afcecfc927e82862c7bc8da78ed7ac498d559027dd802c1ccdc' }
  'win32/hu'    { $checksum = '43e3ac35480adf3b84d91cfeb858040012db849d8938375d896b5d8713d1ae23' }
  'win32/hy-AM' { $checksum = '4bb8523d6836d2ecfec92cb66d1e3d930d83968c5031e48facaa1c75fdfd2b83' }
  'win32/id'    { $checksum = 'b7a916f398b2cb34e4c4f18fefc272726c9ed194ab7bc23e18e0b3345a39dcd2' }
  'win32/is'    { $checksum = '77d406e5d7deeb536e32caff54c726dd1d04131ecb7782c10de32fba6fd25402' }
  'win32/it'    { $checksum = 'd7b32f7376ec6e832af04c77db4d5c055ba9ff2929d6cf0a458790d4ebd0e836' }
  'win32/ja'    { $checksum = 'c013d8418ef04882f5e502708690e36b880a7feeb391d90d289d12c7bbd20175' }
  'win32/ka'    { $checksum = '6988d3fdb8f48c669dd04112be3253e492b122914c35278245bafbe576670ee7' }
  'win32/kab'   { $checksum = '6636528f6ae5d200cf3f024e5e824beb96c53801e6aa6784bc579a9d80b6eeea' }
  'win32/kk'    { $checksum = 'be57c5e325ab38ff88a4a4bdc7280e28a72d657fe7df23e8c91897de6a991517' }
  'win32/ko'    { $checksum = '89d84de6bfacb546ca2acfd969f563ce4d60509ab66da2a706cf5ff840a5efbb' }
  'win32/lt'    { $checksum = '5366118bb5b7cfc28c53b3627839b334a70b2cdd2521d7e765290b70e3d1892e' }
  'win32/lv'    { $checksum = '43c5340152a7857d0f3e4dfca535df7c2252687e3154e33372abb7ae67eb21da' }
  'win32/ms'    { $checksum = '45e3376dbb5890d1f19e5589b3ffd62d796794b9a2e8fb80b9829de4c5013168' }
  'win32/nb-NO' { $checksum = 'dfe633295731aaf9ff1cf532fb0569fc28278078f2d9591a59a19fe071784dd9' }
  'win32/nl'    { $checksum = 'e5d242217970723bfb0f9348a903d06b642b4071f4d4b1368a7db77a9d67529d' }
  'win32/nn-NO' { $checksum = 'db4ea9fd523a58709b5f7093b4ec5556fb6db46814bf4747f4b5050fe22c0b6d' }
  'win32/pa-IN' { $checksum = 'fb085dac37b65e21a450cb866cb3456a137f2bcdc94d039203d618c6e8f93415' }
  'win32/pl'    { $checksum = 'be6e123be7abb5cf22b47609b1b3bad5733fa1eeb51a2543a709a5295f617c62' }
  'win32/pt-BR' { $checksum = '148ba732747ccbf2eaaf15c00381a4f580e2d04e7da3d56d3be45ece2799a5b0' }
  'win32/pt-PT' { $checksum = '491121d903c69eb58811e5b4c0257733c929db7626d132dfdaf028248a70554e' }
  'win32/rm'    { $checksum = '741601245587d567999bc7d861ea01cd771436898f2ee493adbc1223c24c8506' }
  'win32/ro'    { $checksum = 'b18b043f2b4dab530a85b4f45a6a902a21623f380b66b77df34b00ce32f37c33' }
  'win32/ru'    { $checksum = 'bf4c3aad7b73d6de0bfae7c4c70a7f09452fe752f07d146bf12585f7e59a5144' }
  'win32/sk'    { $checksum = '56e1a66c27af83ee786bc147af1bedcdb63c30318f20a04153e18f846d17fdcc' }
  'win32/sl'    { $checksum = 'ea973effb6bbef0caa161051d1eebc6dbb0fc136d56d1b05df89da1df10b99fd' }
  'win32/sq'    { $checksum = '8265f47d6ada4acb512fbee071498eff00f578d140cb6a9e92965d582d0e917f' }
  'win32/sr'    { $checksum = 'f2caab4eadb2bdb12ff43a13836bd6f61beedae491d58631bd88ff22c606a8d3' }
  'win32/sv-SE' { $checksum = 'f09ba6e2de2fff3e9d90c1ca86558111d1dff260d8b43b57a1842ab3a1297a86' }
  'win32/th'    { $checksum = '65b059ae8ae528a80a23c1b44c668b62b0e65f149bd541c9c6d42ed0d25d688a' }
  'win32/tr'    { $checksum = 'bf45c6e144fbf8a5eca125663f5451277c0b519b9a33afc315487c4518217ab7' }
  'win32/uk'    { $checksum = '98b63b014ed05c4ace0cc5d03d543db6d3263754253a51c023bd1dec19a9b8e1' }
  'win32/uz'    { $checksum = 'cc8adf367d80e7be92895c2a5bc78e423d83481114c7ba622a0f5743d42317ee' }
  'win32/vi'    { $checksum = '1721b136fd1a90e6313a96996f318bb5ea22894f085caa3f9f84f04911740556' }
  'win32/zh-CN' { $checksum = '0089a72a2367d2a90e1400072a2eeada2de38f95993d69435dc86ec4b07e573d' }
  'win32/zh-TW' { $checksum = 'cf9cba44d5f53759f54fd3f2b7dd4e0774d769df9c39d666b8866d8fa254a80d' }
  'win64/af'    { $checksum = '152770c101a54bd6a15a7d14984bf30d74f5dae9c710d0107a4bcc227b972e02' }
  'win64/ar'    { $checksum = '41934a18a80d25db63d7fc3b578dce4aa5fccbdb1eff0f4d5ea9dad8c8c4c3de' }
  'win64/ast'   { $checksum = '5d5735bd6d130d6f0a0ec1c799308a611af99a74517f7d654168a66c2951b49d' }
  'win64/be'    { $checksum = '5903fc22635a104b5a3231a46f6b4891215c8c939dd2b1320ec29f3ae49ac60d' }
  'win64/bg'    { $checksum = '847a5683dd4f0bfbc9628c7603d0422206a8df7e02ccc38b84aec896ef490d46' }
  'win64/br'    { $checksum = 'd85b3db19017bcf73747f47469fb4bc4e0fcad2c9a00b53edecfcc7aa232f09a' }
  'win64/ca'    { $checksum = 'b99e4c2664f730ab75dc2083526ae2929bb5f1c4d3fcad55740f7da29f3fe6fe' }
  'win64/cak'   { $checksum = '0db710b789a6b8d717b985766893fa4f7320b5a62a639d4b45622fc9c4967bc7' }
  'win64/cs'    { $checksum = '8033fec7c1100d3eb54616ecc6c2f9c7d09eeab71350974b55596f2b96deec4b' }
  'win64/cy'    { $checksum = '7d7af2bc7143101a979bb825ac8c91190cf4a4107c00f8dfd2f1ad0c8009eb6a' }
  'win64/da'    { $checksum = '2b438dcdaffa398610e96a70740b6c8196b8cfb9c714460327324731291e557f' }
  'win64/de'    { $checksum = '6dd5aeea6cccb239080bd4851051d849021022d21e13a250b2771d5b77d0cb54' }
  'win64/dsb'   { $checksum = '94d7587a233ee68c306e3459d84f9b247f2a2efe66b881efc6a927f3693b19cc' }
  'win64/el'    { $checksum = '821c43654bb731054483821dd390bdf466498af752fcec0e57a741d127d3ed8c' }
  'win64/en-CA' { $checksum = '0329405916d3c66034602ca6e954f82abaa561d214610e24fa696611e63372eb' }
  'win64/en-GB' { $checksum = '01051667903e9910cbf13106536baef19876179d99bc5fb06d8ca142c75ade43' }
  'win64/en-US' { $checksum = '30f0afce4b524d2ac7943603d2efffe20e3c6038a079342efda2a909d92250c3' }
  'win64/es-AR' { $checksum = 'f22cf0c7ee9b1bab0162ef24118c8fefd7f05c7a6b79c4401e71944f05ef2600' }
  'win64/es-ES' { $checksum = 'c03f1e6717ea7cd91f49db43e5a10fd84b0880eca6bd255f6af28c1bbb172209' }
  'win64/es-MX' { $checksum = 'fa3ae8cb0e43bab466a5cf30e7818b36f21509771943dc682a4cb837982f40a6' }
  'win64/et'    { $checksum = '1d6a13d11d33c9ea4c159fd4f485091d1a043b719c5efb5f01c10909f4bad19b' }
  'win64/eu'    { $checksum = 'e672508ed05a7b9d3df12246afa3d5b2b174d7a8e970771029a48b0738318262' }
  'win64/fi'    { $checksum = '81007d6308715cfbf1fce2e2955329094406432d429a378031ff7fb35052e3b3' }
  'win64/fr'    { $checksum = '1c6eee7936202599d74e863596a46ca096dc3f6a93ec75d821906154c62da807' }
  'win64/fy-NL' { $checksum = 'da7c0ef790e4775c079eadaf58f20f57db8a1401ff6a476372458f6db9375427' }
  'win64/ga-IE' { $checksum = '780b28296381c0971405202fdc03270db5fef380307f171652bfa2e82f1cc2df' }
  'win64/gd'    { $checksum = 'c69435f9cf8dbd92b76ce1062d0286729f8134c6a71ba1836200fbe13df85bc6' }
  'win64/gl'    { $checksum = '41f357501b944193e6be9ad99160d476794aea757d61d7ee13cbf6204d197240' }
  'win64/he'    { $checksum = '3ff542d84ccf326338f30429c1a83bd2868fa61af30403631876c97bb08c876b' }
  'win64/hr'    { $checksum = '54c952fef40c1abd8632763f34fee7e00b426e0736d493997a69afebbcc1eee3' }
  'win64/hsb'   { $checksum = '2866f6a3448edc99cdf0380ce9496b0853e095dd1dc18a700534166724928311' }
  'win64/hu'    { $checksum = '3093de78673eaa22d561eaf0d1abdf70da20369d8b7eefffa6674b547f9a5388' }
  'win64/hy-AM' { $checksum = '17aa48889f8889f10b859658e2b913da07b8cf839a04cd57f8e9b822905e6761' }
  'win64/id'    { $checksum = 'ad8f57e0b729010887e0287bbfeadac591a3d5691008fd2c4f3431cfcda74270' }
  'win64/is'    { $checksum = 'bd02d86571be54a69be5503a4137fdc0234381d910891111df00a7165b5ebe96' }
  'win64/it'    { $checksum = '3b675bad66a241c3d556f41379c3eb88f1ceb8b3946a7f701ef943f3f56b54a6' }
  'win64/ja'    { $checksum = '617e1991efcb692e9f016005a41f6f8b66b56e76863a8cd3c587cc4e28534a99' }
  'win64/ka'    { $checksum = 'b65a6846adfa4bd5ec568abb5de8ea1ab9731fcef6ae4d6f668ea393c27672b3' }
  'win64/kab'   { $checksum = '8a4a622c2f8337b55c4d80b93644302dad3a8418d10bb99d44fc42aa7b84084d' }
  'win64/kk'    { $checksum = 'b9b529153078019a5cbe22f28d542e11a05638bec36ffade9852018ba04ef859' }
  'win64/ko'    { $checksum = 'cc1fdc3501e789c03ed09bd284575abae715a369049f5186a8025de594da14b0' }
  'win64/lt'    { $checksum = 'c3614c113f381c997e9a0f2d8704f4dd4d8a077a8693ad61e02523c592e038e4' }
  'win64/lv'    { $checksum = '51e869a8204a32acc0028f5242da4fd659f9911b296b0bee6b0f0cb972f98482' }
  'win64/ms'    { $checksum = 'fe48e41d15859bea364d290186130c18b34c7020505fc9613d56d3f9259ca35c' }
  'win64/nb-NO' { $checksum = '5dc5b18e606a1c931f2b72829d5fdfbe886ab91f4f26a2fd24724fcabaeeec7b' }
  'win64/nl'    { $checksum = '3371b5a6d0c2048bf05fe5b22397fbb89debb9bc8af089fa8baf5317cb9f7858' }
  'win64/nn-NO' { $checksum = '84185147afeb7d0ef70bd7919e27ff779474a6ea299375f4284e37f1d85c4a99' }
  'win64/pa-IN' { $checksum = '4bbe5a8e182e30ff215782b77d49e0d903098850661732720869d2ff4f8cdd9f' }
  'win64/pl'    { $checksum = 'bb066d46c11245ad46834b42bd67c1022809f820e330a0e44612979624e7b5dd' }
  'win64/pt-BR' { $checksum = 'f2d9c924ea69435624ce563c05a4440500ef3286b295ec384494da20d57d0b1f' }
  'win64/pt-PT' { $checksum = '6ccdff9a27aa84ecfffe33118d833d88d8a682c99ff69a3bd67444393b77e381' }
  'win64/rm'    { $checksum = 'e8f5b086e8b9f2a49b56b0a5dd5203db622afdb7a5dd45a43f076e8add9905bc' }
  'win64/ro'    { $checksum = '11d1535722e366bfbeabe4515722fb3ca9ecdbbdf15f5ec104b8b6e9e5e80b02' }
  'win64/ru'    { $checksum = '6204d539e4047fbafcf40654f8ff8c7d2eccbabe8e0e0a629883d80a21c45d4e' }
  'win64/sk'    { $checksum = '291ebc36728c0a728abd853bb5449681b357995f82869a2b937ace2e73aa5b2e' }
  'win64/sl'    { $checksum = 'c1062b3557293f1948aee0a5f173afe4afc80cc1d5fab4e96c52b98bde93a001' }
  'win64/sq'    { $checksum = 'f404aaa9235b584269d9b3ed4fa96c56a775be4a33ec1771b8df7b8dfdaae7c4' }
  'win64/sr'    { $checksum = 'fa6ed7135e7a4bd35d1b89ed0e87d8d4a05941ec7a74a833fe19bcbe61f7d1e7' }
  'win64/sv-SE' { $checksum = 'bbe1fcaf955c8e097746d3c04d9d28e017028fa2d0c8cd47784bdc98ff0d2794' }
  'win64/th'    { $checksum = 'a4ad1e0c16034d44221f4e494e0860d33791d8eda4d3a90b3f01d9eb0723c99b' }
  'win64/tr'    { $checksum = 'cedeb7d3c1c88f7ecb5be337ad765a30419770b72cdfcc99fa18c144a26113c8' }
  'win64/uk'    { $checksum = 'b5ee5034161b48480bca4437e2d3c73b762306627aa8745283c74f3139dc74a3' }
  'win64/uz'    { $checksum = '6f04422b881d9d249ecdbfc93e387175f96e822439648955c917737ce3cfd182' }
  'win64/vi'    { $checksum = 'b92dbc38193ccb73537e5e45c85c4ea66def7ef256edee8d7530ebe42eccd60c' }
  'win64/zh-CN' { $checksum = '0a2d9a4e9c08a45283a15112ee672ddf6b92fbf593cbec445fffc6ce8f24241d' }
  'win64/zh-TW' { $checksum = '10a3adfbcc7b25202f9b39bd00ccbbe5ec975f75fa750adb2edac37cb95d11cb' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
