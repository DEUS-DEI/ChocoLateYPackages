$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '159.0b2'
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
  'win32/af'    { $checksum = '46a777fd93187c3a5537216c26ae2ad0e318b5d2e5b712da4675a02f52b58db5' }
  'win32/ar'    { $checksum = '497e7f28a29e2ceb60556519d1c63dea1647925a6270817f9aa7aeb221e4091d' }
  'win32/ast'   { $checksum = '3bab134e8b07cfcccb6c422396e56c32aafb71e2abc638b1887888364284cea8' }
  'win32/be'    { $checksum = '054b88789620fc3637336a6e7905ef24da4868b8b3d0e97115c4bbb5b3f89686' }
  'win32/bg'    { $checksum = 'f12b7a29b396ff19cd2d6132a1b3eaf482fd273c6528ba4cff43e940fcda4fe7' }
  'win32/br'    { $checksum = '47b7d393d6e4bc866315e628bf6855849c5767aef0f907ac3ccfdd72259b8031' }
  'win32/ca'    { $checksum = '0e0af300ad805c5afbf99a73f1876d007fe7870af9de381f302433849adc1a03' }
  'win32/cak'   { $checksum = 'f6d5ecb5656bc3f3fc90ad99265931166d9a388db31600234835a09a299602f3' }
  'win32/cs'    { $checksum = 'b28909754a0dce9e9cfc33f7fdc307f79c72fc12c8373ee1c35f4a3f83a3f68a' }
  'win32/cy'    { $checksum = 'db4c7ba02ea3ce26a6fb0f7c671dc1f9df3589cc34a2c3cba8db538e143f045a' }
  'win32/da'    { $checksum = '08c3a85974ae1f06a99ef69cfb09fa1ba8c5ce0451a4087fa0bbc085c65cceaa' }
  'win32/de'    { $checksum = 'dda73f15e2951365dabfe687f5b018d2c2ba5ab0ba6acd5e7570268678077209' }
  'win32/dsb'   { $checksum = 'd107a73b1936f61020c13925df68240437912028ab669798aa84c914cd5684b0' }
  'win32/el'    { $checksum = '20f8a0bfc5419f6b6d15c59fe2fee542a6aab042f77f92bd24dc197f5f58b329' }
  'win32/en-CA' { $checksum = '1a3f497e9529b419896f819e2a43cb991d94bb2c75a8111b7fd0ffa181769f9e' }
  'win32/en-GB' { $checksum = 'e084d5646d24daca0f6c7de8ec83a602a4cc800e8a4fda5ccd6d838d24b95f31' }
  'win32/en-US' { $checksum = '0e8db28224d417a5274a5b3c762e66e1b937676e15ed86c8c8fb001a044dd989' }
  'win32/es-AR' { $checksum = 'd8a0d0b75caf7212b97fb0bc21a503186a6a35ae5b781ca1344688c96c6834de' }
  'win32/es-ES' { $checksum = '6de3159185e150fec71b457b16216b1cf6ee75c7342243678f13d6f39ac34295' }
  'win32/es-MX' { $checksum = 'a5d3dd1a3894fc265e8ec3cef4dd2542e21ce202971d57ed8821d32ae15fb5c1' }
  'win32/et'    { $checksum = '88cfc0fbea4a3ce854aa592a19a7d1f34b110e372ac7891f420a0db71b0c3fc2' }
  'win32/eu'    { $checksum = '802ce954b674783b6689111ec2ea253fd8004555158ff5f974e3e28d14d4c647' }
  'win32/fi'    { $checksum = 'ff9ff53102cf5ac3c465e5eb1737763ac80eaf2297e5d19b03d2be33f8686690' }
  'win32/fr'    { $checksum = '58522a9e926a7dde8098358b3f84face06ea6cbf93e94c740cab07a38459a946' }
  'win32/fy-NL' { $checksum = '32985c89fd2de627988ef40c11bfe01d18152c14fc4036ed850a3d88f1a56081' }
  'win32/ga-IE' { $checksum = 'dff10fa33d74e099d8b85cd91b194e8688f3fa2ec4fb9a8e7466cdd53d2de106' }
  'win32/gd'    { $checksum = '4ed2ea528aaa4e95384ce605fdf5befc2a350578939d98d5afdb8ab9696c703d' }
  'win32/gl'    { $checksum = '0838e1f7e68c53dee0ab3d081c94ff2bf2fa4f21e6b0e0db28e48ba59646148e' }
  'win32/he'    { $checksum = 'dcf8809581a57ad3dfa8bcb6589f09208c09a40c44e09198092244a93d040c2c' }
  'win32/hr'    { $checksum = '0241fd09e81564764b9355914ee7ed1e1a9e639169a339cc6260ade47b3a117f' }
  'win32/hsb'   { $checksum = 'a41b48bee65a4f71411fc94f51982a9ea1202b8622a99b4cc28846af0e527f1b' }
  'win32/hu'    { $checksum = 'ac0add6da6bf2a1096e3b6d9f6ca112bcf3e95d5ee829a436afe599b9254f022' }
  'win32/hy-AM' { $checksum = 'c2af1bdfb9f7d1d48f2fcb3e91e61777d927d8e745238d01e9651ba2b43103ff' }
  'win32/id'    { $checksum = '9c5919679a5d4163afd6eba398d0e309f9a1f45631b815959a91dd209be704f2' }
  'win32/is'    { $checksum = 'f27f7c2fbf5206e911bf032ed5410c07297bb71a98acc6b41fc0d1fb86900ae8' }
  'win32/it'    { $checksum = '26d32e2d05a3e0eef518dddea1fa44c1fc9d0ed037c6146ab365acb91fb16cf0' }
  'win32/ja'    { $checksum = '13d49bd9739c128dd40b362b5952aab678bfce2fefdc774c77ac63f89227372c' }
  'win32/ka'    { $checksum = 'd0eba425187bf788f8cae7c77676a39cd2da4026b76adec2f5d484619fc800ab' }
  'win32/kab'   { $checksum = 'a4fc16a15fb9c177fc96a430a1d7f2ce158ae75cd9e69a89705c843887d8ad03' }
  'win32/kk'    { $checksum = '6a3d598bf137008c9a3ce94fa713cf35159798a3fd333caa87b39655647c7260' }
  'win32/ko'    { $checksum = 'f9468c465e2c6e4eaa2862d371b8159ce9b60651abd0b2ef362c080b33d7bcce' }
  'win32/lt'    { $checksum = '182d4f46f29d3b95cc6f8d785ae1f2c87ae28be23526632b0463c3eecc2af351' }
  'win32/lv'    { $checksum = 'a3d5ce2707afb78fe8522fc0d27ecf797fa1a7670d169fc0ad72d05faf940d80' }
  'win32/ms'    { $checksum = '33a82686eb00a265cacd6df71989552736fa53cec2cae2fbca0eb7036f17f837' }
  'win32/nb-NO' { $checksum = '6b89cac622885bf9404b38b187e71d47e73012d88a2aadb647f6aa17af19ee6a' }
  'win32/nl'    { $checksum = '85943e47e4c2f7a89961a8b3759dd6c2489f6a311bd9cfb43b95c21c606c0f4d' }
  'win32/nn-NO' { $checksum = '030d01761941f76a7d03a5b069c4fbf29189de31981579e120590fe3345b00d5' }
  'win32/pa-IN' { $checksum = '293d61409f9acef2c47bf51e2b976bf4a3fe25bb4a8a5cca4c3933ecc1e480bd' }
  'win32/pl'    { $checksum = 'e5a593d2d5b3344691c65b9ed58bac275d0348715122bbb08924376c9589256b' }
  'win32/pt-BR' { $checksum = '2195ef9accbe32ba75b69cc59f50e2a8c891e6e20d80af95ee73ed60f4b3bef8' }
  'win32/pt-PT' { $checksum = 'e5501044082e55f13eec2d323f312fc91f97fb75130768cfa549c0ee1f902b73' }
  'win32/rm'    { $checksum = '6adc11b40f308996d49855fd4e2dff7024c3505d8d1110a2abcceb167d9f3a4e' }
  'win32/ro'    { $checksum = 'f3b896522c6b3352ce3b8eaca1b1fa866e5cb91f4175e5d6304c4d290c32103e' }
  'win32/ru'    { $checksum = '76073aef7a2ca07dc83f5dacb231b078b8dcbf3cfcd297c72f3e269e3cd2c915' }
  'win32/sk'    { $checksum = '902505a45b1d6737020a51fc268419ce386dbfabdb2eb54749682983dc1543aa' }
  'win32/sl'    { $checksum = '152eb165ab6a9f248232e6e704cd6077885d8c1a2ae7dafe8561018a4dd795b5' }
  'win32/sq'    { $checksum = '8e707a62286e0ecf1b67467049cf5cbac7f852fc7060b64bcfbac40e878400ba' }
  'win32/sr'    { $checksum = '94b83819e028f94d8e12d6a35879f4574756a65caf60767676c237dbdff702a9' }
  'win32/sv-SE' { $checksum = '41ee2d082907cfd08219f75f8eceeeca4dd67f7af1a89263acd7f96c0de33588' }
  'win32/th'    { $checksum = '1a2ecf4e9067facba5a7fe5e96c27867ef5c038da9f3bb607e1c23a0792acf88' }
  'win32/tr'    { $checksum = '7e0e71f98df08bdbeec4b384df8510e7eb586fd3f53f0aa1dda9a82c73fe5dba' }
  'win32/uk'    { $checksum = 'd2368cbde7f966f549cb71e4ac0a64ca32b85ff4714392f57795493bb89b1f93' }
  'win32/uz'    { $checksum = '0223b6bac5edde3f13998d649077e3c1720736a4353c2ac8b58749395cb5a97a' }
  'win32/vi'    { $checksum = 'bb97b429485a58003815dc3979c126063dea0d6860e4674ae4d7e6ab24f958f2' }
  'win32/zh-CN' { $checksum = '6e1bad4c1062fc2a6d53f29448f74edaa1127e082e1328f70b6321fc7fe92f1e' }
  'win32/zh-TW' { $checksum = '01fc2926eebcf418e84de3fb2a5b585e70d922bdde31d63e177758130a3f731e' }
  'win64/af'    { $checksum = '350f69dc219bc5be82c937e1a319e1b5f7f3defcfa416d17da7c89c73d493ed9' }
  'win64/ar'    { $checksum = 'e2c968adf0b03380e2b482d16c50e9344bf79b6c290e00def889017665d00def' }
  'win64/ast'   { $checksum = 'e88a9f35e3d8477d12f65dd3ea7124f5161fe16f77d6f3aa2d521c73063f5114' }
  'win64/be'    { $checksum = '19023e3923cfbc91cf798bfff8bbe12d0a9ba4b53b235f37c780cfdac515cdad' }
  'win64/bg'    { $checksum = '923de38bb610b24fde11f8de038ace7c663a201518ebbfc0030dd28c9fed335c' }
  'win64/br'    { $checksum = '403e976c942f1c957c3355e45d04a59d416f7b536a9b27aa928e24da16ad1bf2' }
  'win64/ca'    { $checksum = 'e0cae143f9895be4a3bfbc1e340ef89faac24cb5279e9d6936376bd4475873ae' }
  'win64/cak'   { $checksum = '9f3d215cad929282db90c3bbffd05352ba71d7b2ee5a67632d74b83eb35c7a36' }
  'win64/cs'    { $checksum = '5fd5917eac09f207db3d8c8fec0865fef51b0858bc571562a9b9e9beebcbcbab' }
  'win64/cy'    { $checksum = '65b08279348afe9c506adc0d7239cfc2f90b211ac488590d31f8ab7dfe8a4375' }
  'win64/da'    { $checksum = 'fac048482f8dacc1e485f4045193ec3ebc05efe5c794852728598a06fbeea861' }
  'win64/de'    { $checksum = '7d7decbcceff77a6394295af54ef813e7e033859b974994245f2db4004c0f004' }
  'win64/dsb'   { $checksum = 'e33a26f673d1de109e6e621429a0331503bad2bf8323f499ce9064984c59bfe1' }
  'win64/el'    { $checksum = 'dbe1e0f0ceae647075a38be6927f73b3bef2e417768e073ed78e739ae3e7dd7e' }
  'win64/en-CA' { $checksum = 'e9a9c92265a6992f9277e84ec3a45e16d71b744a5f5afac5333267498d8534fe' }
  'win64/en-GB' { $checksum = '7190bb2253b1da7cba93ed898825b98c22ed8193084a891c1079b262a8466e30' }
  'win64/en-US' { $checksum = '8674c04211aae30c215d2e1cf2147b0a720d022b4ca0b6ab040a902767ba6d49' }
  'win64/es-AR' { $checksum = '28801af809a12be2427d64a6046b1e14cce50742867fb8bedd96ffb431720c34' }
  'win64/es-ES' { $checksum = '3b42cd99ba1a55616e2cd3d895ec9f27929c59a6e855a616981d8e9b057e77f1' }
  'win64/es-MX' { $checksum = 'ee2e3d7420744666d916e45755742bce29013c15c51e4093f583bf2d344809ee' }
  'win64/et'    { $checksum = '9d8477c2f87b5c0e294a1b54a180a86c7cd08ebebdecfa27ca916e4a726bbd94' }
  'win64/eu'    { $checksum = '814403893616ac90608fd9e1545a05de2803aacf7b07d4fff2c6a7d8dd175f36' }
  'win64/fi'    { $checksum = '93bc9871fc61974ab2f05476a78cee5a75d7f6932859606e4cad60331d712dc9' }
  'win64/fr'    { $checksum = '71a197cfa33305ffcc5da167187cf9938045d9d70366685f92314c6ca3baf8c8' }
  'win64/fy-NL' { $checksum = 'b1039466d3198eefac3fe3f75ef327497375d9ad03d11c7d268256e7158cc5f6' }
  'win64/ga-IE' { $checksum = 'e98fe5aa6018197621c990bfe05c2e82b98812ed534b4cea5f85eacdf8d474c8' }
  'win64/gd'    { $checksum = '18f2af75c98a46e6c67064a13162416957771642180d3c54fc7dd7c1a8dda6d2' }
  'win64/gl'    { $checksum = '19b4ad6cd1ed2a8db5e5564bdf5624a5674c9d8d9e11ecf525fae53282c08f3b' }
  'win64/he'    { $checksum = '4ad15fc6b8d41a7cf3514c821a43bf61067a080fed2edb4de3d6f5bbd74305b8' }
  'win64/hr'    { $checksum = '22fdae2341b644171b73994edfb5cdd02eb4586995e70a8381aab30034db0169' }
  'win64/hsb'   { $checksum = 'abcefa4d2ad418df71bac04c7bddbe7f663195b785cc2d460d8490885b451c27' }
  'win64/hu'    { $checksum = 'f3dc9e5434594c739b1c9d4b638984a50067998a8f025ca8e2081df8cd5db302' }
  'win64/hy-AM' { $checksum = '4fd6756aca66aee16ac4c902d5cd6228244b3a6f1b4a901f58db771190347257' }
  'win64/id'    { $checksum = '0d0b473f0c2c8f66260559884daeee8473dbbb00fc7304bbd1bde4970f2a46df' }
  'win64/is'    { $checksum = 'd1f3cf06f4de805ff5faded9e1722f35cafa87836a8cccae1c8def204150b07c' }
  'win64/it'    { $checksum = '5fb8569001cf7eb212b3de2316e7fc33a76ea839f5cbe0c5c44cb83790243afe' }
  'win64/ja'    { $checksum = '3890ead1912570c67497caf1809dc2f8953b9065a447f9699bb29f01af165d27' }
  'win64/ka'    { $checksum = 'a6e2dffd0c27e85640473399ef9c629c9ff98d63482c87943bdabdaa22a09d9f' }
  'win64/kab'   { $checksum = 'b09b2039c797247c8d31495b62a626a36230812401aaa08bfc63709dd33d5932' }
  'win64/kk'    { $checksum = '9dfab36124ef6d18ad4852c05258f6638bde4ae9c30c2699bad8f28eee00edff' }
  'win64/ko'    { $checksum = '30c8d22f0d477d0d32022a50b5c28de46dfab9709c89db38f40895e10f27be5e' }
  'win64/lt'    { $checksum = '62ab2758332c0cb854cd10c1b8418ef68a6371ca58673aa3abf85a78c4481c25' }
  'win64/lv'    { $checksum = '67972b40a5e67c234bdf209e04e1ea3b5c2712282e973cb0f20b6e0b5290544d' }
  'win64/ms'    { $checksum = '9b40d4ceebcc2b1b30de36efe7a136db20d0e8478eeda85f5724d4887d2a8e7b' }
  'win64/nb-NO' { $checksum = '7527d99ca56149db9167b7194fb598b57aa53c9feb71ba0c5b3bc467aa256f10' }
  'win64/nl'    { $checksum = 'bd65719ec997881268c76145d63a9c2fb6c4a7f24a616b0536535876f81d056e' }
  'win64/nn-NO' { $checksum = '1f12f1d0233d82a6385270c7bd683b219022537805246d3bc15d6a7347394e3e' }
  'win64/pa-IN' { $checksum = '59e8363d07b24403078277f8feeb404690da7254d3e1933d7f6f471ce22ddec7' }
  'win64/pl'    { $checksum = 'd3cd092d1269b3f90b11cf0ccc41257ab30126d6a42ee0514a7d15f0b48c2962' }
  'win64/pt-BR' { $checksum = '626f004c96ec42fcbd117b19c3b2ce274021b019658ebf78bdaa639c33df3a1f' }
  'win64/pt-PT' { $checksum = '393e33a2ebbd9f74ea533869994e47b80b2c754038d402a6f2f2716d3f0ae2d6' }
  'win64/rm'    { $checksum = 'f6e139157c1e474160cdea89a16c6441fb7cc7737a0fecbbd2d6beca7a1a4d16' }
  'win64/ro'    { $checksum = '0da225060bbf34ce8be3dd5721ead5ab16d37f1f336362e244056f03ef1d4b39' }
  'win64/ru'    { $checksum = 'e102db232409b738b2aad7e1c30c858a784ae844f0e4c15fffb6f29ec71273f0' }
  'win64/sk'    { $checksum = '0a0f05578d2e13714926d0bcc5a21cacc342a8aa01ec970dd34e283b571c19d8' }
  'win64/sl'    { $checksum = '0a66d77665f3921adead3a9b5782b2f1d802c557a626185bb8d2c3802c93188e' }
  'win64/sq'    { $checksum = '6f06a6fc57fa33e5b183580005a5307a5a92f06717a6bb863bd25788847c8457' }
  'win64/sr'    { $checksum = '5ca3117e425626ddf41e4c681ab2cd180791fd6a124b287469cc7334673f67a5' }
  'win64/sv-SE' { $checksum = '9efa07339c9f00933c1782e1609522dae514e136fadd8891dde83684c1a3cf22' }
  'win64/th'    { $checksum = 'b3db0024b9a98c33332ba79dd3b23b7e9250b824db1272972c226c4cf607fbfb' }
  'win64/tr'    { $checksum = '7641e3c209ce8f846bf8e5eb68f2ad220475caee4a8b12a261da69b4eb7e1557' }
  'win64/uk'    { $checksum = '14ba93f913910da31b3b9eb58c8ad9f05a425b4e71a8686f7f6e187ce3f4d275' }
  'win64/uz'    { $checksum = 'b84bc1cd6b6867126ff07038bae0a0dc814c04a63e1d85182f9e852935f1faa9' }
  'win64/vi'    { $checksum = 'ac37bad9e1e024d7f1304df36beecc2b33eaca4e3f60ed88b37ce3b403ebdd9e' }
  'win64/zh-CN' { $checksum = '13a6e83877f33d0e333ee3bd1f7f9d3ec1ed4d1ff9136be6fd741bf7316f2096' }
  'win64/zh-TW' { $checksum = 'c9ff5026227a47d62211a9925dd77b30b0f94b69a5e95c0ec639f3fd4c7155f7' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
