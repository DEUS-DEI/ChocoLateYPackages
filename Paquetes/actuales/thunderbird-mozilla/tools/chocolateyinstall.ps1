$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '160.0b5'
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
  'win32/af'    { $checksum = 'a756a97743da12380eae0f7146a86588bba9c6bb1107e607d0f1adce0bd87a15' }
  'win32/ar'    { $checksum = '9fc8a65fff93928869901c5ca50e81f2aa419408b09a46bedde0d7210a3e0f84' }
  'win32/ast'   { $checksum = 'ec459fdff21b6ad7903313a8cf0ad25d7f823044b88aea97b6de885a273c2308' }
  'win32/be'    { $checksum = 'a4885cdce1441ab206b6e46f2796b7ba7b5a316964ee71ae4ef5e9af771d64cb' }
  'win32/bg'    { $checksum = 'dd0001bef43c005a86db5c30cf81211f7205bc95d4a61d2743d81f63855eab30' }
  'win32/br'    { $checksum = 'ecdd19bc0bc84bb28640178f2ace5f420863e21c5fd3b6881f397a660de4e07e' }
  'win32/ca'    { $checksum = '33ee8d5e86e32eb2c907f28a24e34537836dc73daff53ae5eb8f2807800c4d6a' }
  'win32/cak'   { $checksum = 'e3f1ac153458dfff3da8b2a33174b094972c73d4a79682a5dd6219ef4596741c' }
  'win32/cs'    { $checksum = '2c435e39c1b377d52bdc3e5ec6e08e06ff0f2a448a303f125e448e508b5a3c5f' }
  'win32/cy'    { $checksum = 'd61f1b6b703d519632fba268d77064821636935bfa03db7253e91277f324b8f8' }
  'win32/da'    { $checksum = '2dc71c124b27a224b4e2ac0ef2d5b0b3df96237b5adc08d06d4191461e9d8e21' }
  'win32/de'    { $checksum = '71332b69f5180563949b5a4816d71c2a55dcd27c075ebf63ae79820c08fb1714' }
  'win32/dsb'   { $checksum = 'cdaa94d1a9c6b5a04b456c46adb8844f9de3abd2b36c7ac68f1438920bde0548' }
  'win32/el'    { $checksum = '3417756b952d9a6062c13ebeb4fddeaf03868c5a61fe6ba7659e13df52f71fe2' }
  'win32/en-CA' { $checksum = 'e625f787c912d0ff402832e146365aad2c9a09045794a2ca25c7293a3cfd964b' }
  'win32/en-GB' { $checksum = '9951bc2f117f4af968f1d2f7b6bb1f7f9d0bb8fc6c2c4d64b0991d945556a6e3' }
  'win32/en-US' { $checksum = '07a41ced283eef1a059ba256e83d706a95f81b405d507ae0616e906560059319' }
  'win32/es-AR' { $checksum = '14eed9712ec623480eb8ef7daac26241d2d0db660a554c82284f705ccf88842b' }
  'win32/es-ES' { $checksum = 'c2f7c12802d6278e31a2d9ff6de30d5dc3fc11ce625d1bd0b12d7eea8cc6ab33' }
  'win32/es-MX' { $checksum = 'ef9f7524e7bd64f4398ad0150d9389d23e521e1efd56cb117d82f7f92284b367' }
  'win32/et'    { $checksum = '9765533108eb77c6000b744bddcc54b4d756960dc8d063b755e165043ba59198' }
  'win32/eu'    { $checksum = 'b47e0dc644c9cb8ecd75b3e870f8fc6263c2e60799017c1fa1de8332116f208a' }
  'win32/fi'    { $checksum = '45c2a3c3acc277e58b00ce9883511e819b19f1a5d279d96ffa72e5d4b16b9597' }
  'win32/fr'    { $checksum = 'c36f392504e7b2d41c8815c065905ed31cccb5e754a816fab218fabb9fa21565' }
  'win32/fy-NL' { $checksum = 'ac4c9738171ad7627c7afad5ce3f4582d42062002cf41f0a1432691ebd38bc53' }
  'win32/ga-IE' { $checksum = 'bbd12bab9d7e280707855d4abe3927d939fec5958eb8a2c2ac03a67e7b815b99' }
  'win32/gd'    { $checksum = '3ab9c03f7d8878eb65c13d90351f21be2440feeb8da6ef6f14328a31852756ff' }
  'win32/gl'    { $checksum = '1162653d4f59e1602cda1e99e363fdd0ecfed02990b2653fe932231d31bc5f40' }
  'win32/he'    { $checksum = 'd1f7f439588b7dc143b9e4874171a39c47dbfb2f99445470a8a82fa9e32c0313' }
  'win32/hr'    { $checksum = 'de847df24ddefe6009d1e6beb2a3500f2e9dd78c02aad316dadbb72d2ea5eb43' }
  'win32/hsb'   { $checksum = 'd2ad65e50f8e5536635d970e8299c0fa13a80d3eaa3bfa228d0cfb46cef906d1' }
  'win32/hu'    { $checksum = '01c38a1ef416f1d9afa45777ec18018cf67a76515ac04e84d9c0c6d3c00ebefd' }
  'win32/hy-AM' { $checksum = '5ef9667b2638d34d03bd688bf54607831d98011dcf853e822945a3bb1bd6d14d' }
  'win32/id'    { $checksum = 'a850af8db9e703d0a14b235d7b528134234b648f8668393582ec360c2dcb0ead' }
  'win32/is'    { $checksum = 'ca37c59c3493797299089c437d36d85969ebd29715b30e9615775abd96252b60' }
  'win32/it'    { $checksum = '496e341c0e0e4a0bc1e7d9c6cbc7cbc6a1ca47c6d103ae216f9d5f5025560ae2' }
  'win32/ja'    { $checksum = '68c6460cd4b7e2c9b505711af1263a0e77891b57c4eecc097ef2de4cd2e00bd9' }
  'win32/ka'    { $checksum = '800d96ce5408e91f5ae88466c2960b1abce7cfc9b0d82b99ea98134a6c1d243b' }
  'win32/kab'   { $checksum = '3203e65158550b8f04147410cbd32ffc1542fae4d971adbffa820a3d4b894040' }
  'win32/kk'    { $checksum = 'ef86ee53f546b976b85befeaa066df1360e4b63493ad6226a383ce5750e7ab39' }
  'win32/ko'    { $checksum = 'a35b73546e1c1b5183a6bd9cc46ae7abafd7cc7dbd996472ab003a8b02dfa56b' }
  'win32/lt'    { $checksum = '77688b36972c8fc01d8641fa0889c68e13a5d6bb49d7ba36a6dadae18569e58c' }
  'win32/lv'    { $checksum = '144844e07d95994c30a3b22508f504c81868e4492eff04ad9a8ccbd7a3565c97' }
  'win32/ms'    { $checksum = '61e1ad0fd7e81eae94869dcda7e176bdc7bc28e06db4b1d08f4ff8d24d1ad5d3' }
  'win32/nb-NO' { $checksum = '5ced42c1f2bf50405ed5edf4ea320123ed069f28bc43ada2f54d73f5c214a353' }
  'win32/nl'    { $checksum = '0d277ff29bc0c88516590076336e9344840ceaa546b3fa97a9cc5c38e798b995' }
  'win32/nn-NO' { $checksum = 'fcec7d076d50e5552cbea168bf643444933294442f5ece89b0b27c23f94de130' }
  'win32/pa-IN' { $checksum = '8642cb908f16cd1ab75e5be08b048836f4a1f2f9e5b90acac5549fef35c5eeef' }
  'win32/pl'    { $checksum = 'c2b7620c239b6b021ed97aee9a09715b5955a3aa1b272c1db111837117510a74' }
  'win32/pt-BR' { $checksum = '468c277eee09750d6c50edcfebe93273a697062e8e94227edc0ec6ccb6fea302' }
  'win32/pt-PT' { $checksum = 'a0e773e4a077696b3fbfbdb26c041088a2272de72d6d200d11d9956eeeb4d94c' }
  'win32/rm'    { $checksum = '4cfe76e75185de0a9473b0bfc0a4f4e93687a5d0a3f13c8f92f35d49bc5828c3' }
  'win32/ro'    { $checksum = '9a57fc7772c5fed47ce3e139d2942e507554368c698d9c31386221464f7b4745' }
  'win32/ru'    { $checksum = '7f7df566f8ef1bc26c4164ceaecec34f5ff530f24e23bf38b4d5da08c7ccdb24' }
  'win32/sk'    { $checksum = '6ab8bb1eb55abab8d349ee0d45e3f90d5804d1b4a483328475ea7f600b9d72ce' }
  'win32/sl'    { $checksum = 'dd419c31d860e4af83ea7768c87ca52248eeb24e96168822860e219e433c2235' }
  'win32/sq'    { $checksum = 'b5b79613615783f36b0ca1627408c7d7702bb05b8dc7cf405621ff8bbff090d3' }
  'win32/sr'    { $checksum = 'abd665bff99e57fe163a3192bf7f5458ac18b5db52bb70b978cb9c11d31365d6' }
  'win32/sv-SE' { $checksum = 'c148813f45a931e91c4a47f69ad1d22d6761fb1b986983a1c421fe9f11988106' }
  'win32/th'    { $checksum = 'ddbd7dbcd9f4557da36f1ad8d61579bf696f3dec1c4ff215c3e61896d98700ea' }
  'win32/tr'    { $checksum = '6989b88e2357151f6c840a383215c162260561d93486340f717c21a7ff32ad48' }
  'win32/uk'    { $checksum = 'f3750d41660bed46c9b56a5a32aff1e9c578caa01e9efa44fb81d15908c3b2ce' }
  'win32/uz'    { $checksum = '97b40ad4552e50fe600d13dbac79b59de1a47235f2be418b9e04e3d6ec11282b' }
  'win32/vi'    { $checksum = 'd6651e4896bcf47401f0ce253f62f9bb7218d0eee66dd12acf14ff15695174f2' }
  'win32/zh-CN' { $checksum = 'f63de5ed725fb3449bb1280751d4302777a6bd2ce8ef73212bd37afd380228f1' }
  'win32/zh-TW' { $checksum = 'a465ffa07caba247be2d140baf3463f43fd919ec88f69e925b9b0799dce006a6' }
  'win64/af'    { $checksum = '0dd13c5e6a8d89f70ec8256aee4f7dc1a7f8f718ef2c2453f7a50063c2823c66' }
  'win64/ar'    { $checksum = 'b0ce41aafe6d8a40de9cc5ec5fac1909b65d0fefb71bbca75d436bfb88a7c845' }
  'win64/ast'   { $checksum = 'fdf01b92fd82c3796b69d2ee83550579013470dbf3740340c737d6fa06304a93' }
  'win64/be'    { $checksum = 'f8c7f91f7b707a6c68802f2ad86326a7c772852557c25bc57048e83a442dd676' }
  'win64/bg'    { $checksum = '008269371981c267b434920bdda9c2ba9b3caa8eda9b74307272205ba22f0c17' }
  'win64/br'    { $checksum = '51ffed6c4a18d8620f2dcd76e819238c01b6f970257323421ed8eaee537777eb' }
  'win64/ca'    { $checksum = 'ed4e32c1b3f0fa79d94fb078fbfd3ad10458f50960c8c0732b502e49e75f8f0e' }
  'win64/cak'   { $checksum = '3a31ac0d1dce512ae0f6066bca4d16c8954a1bc18f7a72c0dca3a6de896081dd' }
  'win64/cs'    { $checksum = 'c80ffa90b91e44cab11b0699a1416ca1f3bb75952f20ce089a6851a0615c84a9' }
  'win64/cy'    { $checksum = '786f44dc279b17885c1e2161c451269656737530b1312c48d09e7cee945c6c57' }
  'win64/da'    { $checksum = '09f5ebee81fc9b4a0f42cf50a5bedbd3c8573a3d239243c1e0718fd17905d4ae' }
  'win64/de'    { $checksum = '1ab92607ae00740ce5aaae3a8e5746db4b408c05e45ecb9bbf47accd9bfa7ed5' }
  'win64/dsb'   { $checksum = '6fc7f84ac728e0f3c382d9f9767ffe495f428f2b9b4cc49754e863d62d7b0f96' }
  'win64/el'    { $checksum = 'efcecc721a14dd2eabd6e734a4135acff738c6f7a36c1e107697de2881bdd368' }
  'win64/en-CA' { $checksum = '93d8ac40d0a941615497bc2c505b35705d3ac6612a3cce5110ed1b45d1e8aaee' }
  'win64/en-GB' { $checksum = '7941421673780e3fa0498c93974f079c28e65be4bd81cf3b7622b382f6f8fdcd' }
  'win64/en-US' { $checksum = 'a1f44c184a63dbf6936623d2656a2ce4c9e560145033c3b060ad90e9fa41d821' }
  'win64/es-AR' { $checksum = '2a25334efa2f642e0c420023cf30ccb05c357452c96d2462e7df30fa48f37bda' }
  'win64/es-ES' { $checksum = '151a1edb2a280333353672c0ca5d00ed16bd97badaf9d88afd2488c3e150d94f' }
  'win64/es-MX' { $checksum = '0e1ae84b14d2d724abab93c25b46690de2feb2d330ea8faa619817fd226873cf' }
  'win64/et'    { $checksum = '899f27814675fefc6743939ba503a7fcc85e92b6136b06641dbc14a04b98cf2e' }
  'win64/eu'    { $checksum = '8979ac900ed5391298961af0d9859a13a6391591b21613d19deed175c81edcff' }
  'win64/fi'    { $checksum = '3e7c8c2c6247723b24cc49dee42c939a351244f13502b31a5dbbb1a809fa3d2f' }
  'win64/fr'    { $checksum = '21fd47b90a111f522f994bdfe1bc1a312d0559399fb169faa29ced3fe653209b' }
  'win64/fy-NL' { $checksum = '2c101f6c4b5b618d5cb6726d9921b6b62ac4367b3d157dc220b32b96150321c7' }
  'win64/ga-IE' { $checksum = '0ea7a059e9ee4ae621450329d4dfe3da0390ca9a4562cb9ed3e4cd1ca5709119' }
  'win64/gd'    { $checksum = '89fc308bb3abcbf7f3bcc066d5a322fe6c0d279522206f5f8ad3518c80bd2557' }
  'win64/gl'    { $checksum = '1dc3501e07fc35eeeca9e66bf4fc01f96b1bc89d9d84793db6e8229d21ed8938' }
  'win64/he'    { $checksum = '42b297c3eae980334618d6cd1193729497fc877d92ade4f656763585047e282f' }
  'win64/hr'    { $checksum = 'de81aa812fe3d7a6c26fc84f8b8188f9b044679d5112a25f30a10ece1325fae6' }
  'win64/hsb'   { $checksum = '95aa285c71f3c87d3afde17d2c859b982ab8e87781107ba9052f1979928e6d44' }
  'win64/hu'    { $checksum = '717a6cd7ad29692aca9532bc1b9f9c8bd2e10599c9f7595e4868225230b3e10f' }
  'win64/hy-AM' { $checksum = 'f20ce17a83e650761b87d850e5eac2b5c8b21ff07cf1ec79fd3572eb03416ef7' }
  'win64/id'    { $checksum = 'dc8e1a2f29e4ed1c52ab06832806bf2e1a06c669b95daada81a68907c87e19cf' }
  'win64/is'    { $checksum = '33c68dee3d7ac6a1411840f8212a988f0ba537335097b73459c6902d7d349f00' }
  'win64/it'    { $checksum = 'a7b704c8e58ae52ba73ed09594f4c139dc1b49dee38ab3492a3696f2c885ae43' }
  'win64/ja'    { $checksum = '5c4358135e557df2c0da364ed6ca5d3ef14bd0228b745d9997bd55ab8b7e084c' }
  'win64/ka'    { $checksum = 'cf5c82a13b2bfc407570530e7fcd2fde97b5f65c491c07833f7c07e3e2c763da' }
  'win64/kab'   { $checksum = '2d972fe8854bea18e1e4a18f56c1011a32df4fcc9bcbc73ffbdaacac00f192e1' }
  'win64/kk'    { $checksum = '1750f8f45e6d1ffc1bea8ee747c93e08267735914fa1051c1cdbdfb753af77e6' }
  'win64/ko'    { $checksum = '373cd0be099512eb29e1e2e71e54a0b98f87fb750a22693e7e62e9cf48c6b5cb' }
  'win64/lt'    { $checksum = '9ec1d54aa724e20b6d4d7713f442ad9ba1c44c57a709a0987ff34e5ddddd7914' }
  'win64/lv'    { $checksum = '83f706db91ccf9680349a58c18f2da9f3d642998d23f4af08b4ca3b36fe62833' }
  'win64/ms'    { $checksum = 'b5b7da828c721a22ebeb2a2614b56c7872dbfa9fe770edc7cb6e813f50f512f5' }
  'win64/nb-NO' { $checksum = '64895ce061863c92f13c42ba540969164a1c3595f690b6763e72e709cf45c0af' }
  'win64/nl'    { $checksum = 'b3eda7810f500e25efb8316354e37bb3f90bb7a7c52010913c2088bdf153da8b' }
  'win64/nn-NO' { $checksum = 'ed0a76ff1c34e5d4a70ec951e42e94b0c05d2f625328ad35dcb24daca7e68440' }
  'win64/pa-IN' { $checksum = '78073e35c979b85588ac6fc55377ec7ebf777a9f8f8129b44cf48b21a7019bf7' }
  'win64/pl'    { $checksum = '612e5304a50a86108e5635f614f19f82058086592ba3abcd38c9c123decff7e0' }
  'win64/pt-BR' { $checksum = '3536d694c6ed3783775585384bba8fb9f14e46baed4a00e4a837fca0802123db' }
  'win64/pt-PT' { $checksum = 'e377fe8b692e062a5252e361de23d2e4e96378475e344aef6b9a5659005cd804' }
  'win64/rm'    { $checksum = 'c48390d55ff02057bedfc059e0eb2a77fd0d8d6ecb6027976a1ce86e5a05fd94' }
  'win64/ro'    { $checksum = 'd0bde43ef7e892eb597ba6dc70086818fd1476e5a025a6b0f71575cb00090ebf' }
  'win64/ru'    { $checksum = '6e81b708c394456660b100badb1a21ea563cac55e16e9ffc96f51893f57889d4' }
  'win64/sk'    { $checksum = '8ef67a58872388038d13e4d20d465c14c1d518ab9254b0aecc9a8f61e0df9f01' }
  'win64/sl'    { $checksum = '7301e4dfc314ae1d27e122434b443ed6f1fcaf0e282038cf9dc4dbc24566a47c' }
  'win64/sq'    { $checksum = '62ef33b8f8746fd72faac9ae3abab3c490e2eb9a8b9d17ac9c8718a5db3e30b5' }
  'win64/sr'    { $checksum = '31a9d32f4baa3189bc204e3ddfd6846dfa36dc9a75ecdd75f3ee6a2c56c06049' }
  'win64/sv-SE' { $checksum = 'eb235e2c584f1fa4069265032b3670b8f856240e1d4406718aff46b25be345a5' }
  'win64/th'    { $checksum = '19603c6ca5db5215088deb86b6d3300e811fa7026f723efc33b093e603418563' }
  'win64/tr'    { $checksum = '06264f549e2131e49c08a61845f8d4d1ab788e71252794ab1d421be44d54fed2' }
  'win64/uk'    { $checksum = '569c603e467f32c39c6e26e861e8b46403db2e8b8dc49ccad764a779f852d509' }
  'win64/uz'    { $checksum = '5670d6fae6f413c229d05a735c72b49993a46b3d603f1cbb3c6e71f2e3226678' }
  'win64/vi'    { $checksum = '0c453a5aaaa151a5a04ec836cc649e0f8e513ba7fef306ad68c989148a9d5574' }
  'win64/zh-CN' { $checksum = '8c0aa4217674a817e527e256ede9e51b78cffd78f82e62133853537bc5b9709d' }
  'win64/zh-TW' { $checksum = '7c2bcb4e79135fb756c51e0158ae69ffb21f02c9ffebdfee586d85ef0a90e563' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
