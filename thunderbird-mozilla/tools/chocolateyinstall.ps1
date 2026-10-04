$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '158.0b2'
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
  'win32/af'    { $checksum = 'a470f22dbbf983a723d027a62b3a65052d421f30605cecf70ae23f980ce51abf' }
  'win32/ar'    { $checksum = 'c8d48c1d15f0c2e9577d4c73f628a2da0f0fdc27845bec6dff855d3ea7bfe91f' }
  'win32/ast'   { $checksum = 'e4a0b0b4c5242fe7a909811f9b730aa8f699f9f6d8397ae842d635d8cc9eb3a0' }
  'win32/be'    { $checksum = '0ff6f0c8aa717e89fcbb0388a3ef927fd92808ca2190d474273457383e6b1e1d' }
  'win32/bg'    { $checksum = '240ed9555b8c4217db9d793012fe9d37d99cbfabc2b4f1c85f98753b2be33d64' }
  'win32/br'    { $checksum = '96aa423e9d6e44a855bebe38b4bb69f9bcb2571c1185613b0f201076cc109701' }
  'win32/ca'    { $checksum = 'e925bc17aa05ed2dc8597f8a7b7870bc2ee8d560d1740547b9d01786dd95ec1e' }
  'win32/cak'   { $checksum = '6fc7380ee13de8b271a4f7a7b23c0d4576900c5362ac72720720ba019901ea97' }
  'win32/cs'    { $checksum = '0e3824b3a69760d85a1109687edcc5826010f2db40891efaf1d6cf23b476d24f' }
  'win32/cy'    { $checksum = '2a5c0ed15367bf9ac42ba790a665ba61df49a804177c90e99289823522604b53' }
  'win32/da'    { $checksum = '4453cf17de9ab3a92fb370059183defb191b821fcfd9d23d8c728f69fb5212c0' }
  'win32/de'    { $checksum = 'eceec01f14566998c122fcb6e11d499f26d30d938574922a440c52e592d35a51' }
  'win32/dsb'   { $checksum = '51f4273c9ed92d7b891b25340a0b5d5916c0a9b7b4a2069434f4c94e1cb9c2e6' }
  'win32/el'    { $checksum = 'ffd72969ccfc6fff901b111b579afbd7aba5561bd947a6073ff96514a83e87c0' }
  'win32/en-CA' { $checksum = '30932a84089e8b2bc3294f31e64b1d1e388fe91252da37315509d34a4924555f' }
  'win32/en-GB' { $checksum = 'f50b99632dcde770459dccd89a145ac0876b1998a221864d4dfa376703f2d480' }
  'win32/en-US' { $checksum = '0209f1fa5af9dcf350fb34c244d41976a19eec84440edd32c420e54a3631db9c' }
  'win32/es-AR' { $checksum = '4d508e3e4a7c4a311035803afdd184d7c9aaa38edd86ec61c44503c7e2251d0d' }
  'win32/es-ES' { $checksum = '960a4be5f4cac97b6760cf5dee3c214da28cb66fcad2e12de5cb523f7f916e3b' }
  'win32/es-MX' { $checksum = 'e9c90c7ce29fa9c87c5d87765a6cb9f844f0e27a958cfc4e81edbe4862fca9a2' }
  'win32/et'    { $checksum = 'e1f2004c9c19b1be30141725e958bbe42ef102c42ff1f5e4317dbdde722e4cda' }
  'win32/eu'    { $checksum = 'c87373748e75cae5e1e8fa76c187081186639cd0e14cbf9e8826d86f1d0e73e4' }
  'win32/fi'    { $checksum = 'db1dfa9fdb83b45fb479712176a9766800a3ac6189112f06f3b16a351550f81e' }
  'win32/fr'    { $checksum = '2e199c50fb1119a6c796aa57fed9450d73dc219b3f241ee20d96d95ea8258426' }
  'win32/fy-NL' { $checksum = '8c38ad49525cab6e9d3153a618a800a818384b770e390f807d8773b58e5ef13b' }
  'win32/ga-IE' { $checksum = '88618862ae74f848ac774ca77b0b3470b65829e0f92b9ad6b7c77d2042eb9580' }
  'win32/gd'    { $checksum = '0aca96e4265a90648604aaa198deb870d7432f9820ac6ea72742ca31776cca8b' }
  'win32/gl'    { $checksum = '7266e8bb44b1045699673baee480c439dca11256620981bb310d9c4117b5bd07' }
  'win32/he'    { $checksum = 'bd37a33436a67e0dc13a4bb7f5baceef8bc11a91ed3c0c4d7dfa7a4f232c1156' }
  'win32/hr'    { $checksum = '3d27e0d6362e5a295bff5167d218bb4ba7c8141c3e72f5abe35e3ed47be7fd24' }
  'win32/hsb'   { $checksum = '10aa8b51a579ec459253ba70450a74647c58f854de2a17b8c56257cbbcb5b490' }
  'win32/hu'    { $checksum = 'b9f3d0feed44b7027a11428183ca7410ebc2b8a61715d59f2b0aad2eadc2960f' }
  'win32/hy-AM' { $checksum = 'c74a3bf3c83c96579662172c5abb0a64bbb5c9b1ae4b49ff1ba4d6557da34552' }
  'win32/id'    { $checksum = '978cca1378408d3a3252c794563bb703bf08a919ab3ed83bd67832a49583d960' }
  'win32/is'    { $checksum = 'e2cccfa8fb9c289459d4207031070a3c6d167bf8bf25e47d0d93f2855738747a' }
  'win32/it'    { $checksum = 'c55d7f6f7cf89be6a286e7014bc29dd97938dc9ca1c95a98a8e78b46efd5b96e' }
  'win32/ja'    { $checksum = '918a7ba72694bf35734e118009ce8ff74c77975d70b69a4b233f717872c315ff' }
  'win32/ka'    { $checksum = '386c378aadb58fe6af79d0ed98692ff59332bb70a37a326e3f15607d6db9fbb2' }
  'win32/kab'   { $checksum = 'e2996d5cfb6666eecd3ea6a729a565ce3be5695013fa7fa5f1effe60f4074288' }
  'win32/kk'    { $checksum = '53050ccd7052d190d71dfd18c821a08fc1d5625dfe27ad24eafb7b66f357757c' }
  'win32/ko'    { $checksum = 'e90fb9ce3f62665622a8786d58a8da2239a4b6391de8721ba18064281edd859a' }
  'win32/lt'    { $checksum = 'f473d290c7a90826b8468db9a414fd8564d853608ed2c82f401d7810133c6d0e' }
  'win32/lv'    { $checksum = 'f1974eca8633b834f33697002eb114fbca60b5b1cfdca50057c81ae2b01aec34' }
  'win32/ms'    { $checksum = 'f8f9eb2bed5185ccb6d7c57509f678ab1c465198cb69d12001298cfa7bd86e2b' }
  'win32/nb-NO' { $checksum = '8c45a0aeb66f9444d01eb437ba1054d414454c79ea32cd57fef05a48c74e3ded' }
  'win32/nl'    { $checksum = '5a6dec0fc113fd19782bbbdef8477cd2c848f15da683ce7facf8e55f8374bf6f' }
  'win32/nn-NO' { $checksum = 'fbe1e590fc6d3cb675c5c55adea0169991db76f384434ad2ba32c1bba36b7997' }
  'win32/pa-IN' { $checksum = '34200ac2c221d93be03da27990169ab4e4e6c59a9001b7105ffb7d07217b3e0a' }
  'win32/pl'    { $checksum = '3241dbb5bea3aa2c02e2a187fa48b65d2b15757e49d4c91f47e3c42283d1e746' }
  'win32/pt-BR' { $checksum = 'ead4f327645b70dd742f2c5ab8edf7bd63514415f85f736dd0a30012fd9a05f3' }
  'win32/pt-PT' { $checksum = '411f0851839442b341953eb6e3f5acbc383a336188885d63c25f210fecad93e2' }
  'win32/rm'    { $checksum = '51e4fb78df88125765f6c2274a7d614fa727f947c64657bf217bb842be0c1914' }
  'win32/ro'    { $checksum = 'b930cb0b3c4c9a968872fed15185ccb8c8dfa7547bf6b0b34649def6da8e5eae' }
  'win32/ru'    { $checksum = 'b66dd0176ac772fd2d3fe1f97a4bb5d0c6176ca0e0c566f411b9f95c5d029d2c' }
  'win32/sk'    { $checksum = '834dc8753dc4e0fb4311e0cbb0dc3cc786d519029d7419497ba53b651a651860' }
  'win32/sl'    { $checksum = '28492459d339b2b426037f72fc333a5c726f0bc05a4f4b345e1d8414ed8b4f4f' }
  'win32/sq'    { $checksum = 'f26994572d1f2808b6235a71612488bbc4af39f5ffd3599c1bf4d38f280ff4a3' }
  'win32/sr'    { $checksum = '1f4ce5d07f91edc54d19ff69538df82f2bbf0294d9970cce356b0309d02658f9' }
  'win32/sv-SE' { $checksum = '6b390952cd56ccc51acd2f97e70e40bbfb157f11a9967c6fe0862998ff279a14' }
  'win32/th'    { $checksum = '1b775b1334aa8375d03a6d2c21d8aae101423be90db50aa684a14a1e42218148' }
  'win32/tr'    { $checksum = '7b39fe0d5cb7790587e4029d0c179a54b741e64b02c3f75e8b56f301cfbf6cb8' }
  'win32/uk'    { $checksum = '977d8094ed7d45bccb5df70b9ff60f60ebc8cbef8ff2a13b8df1c5efd129e0cf' }
  'win32/uz'    { $checksum = '00b0faa8c529dda39e83e25f017439be2aa5d84f7436cd144147ec7e75dee341' }
  'win32/vi'    { $checksum = '313523eedff3c2c6e0f77ee6f6a37cb8098061f1234b307ecc3122c8bfab8aa1' }
  'win32/zh-CN' { $checksum = 'cabd12ff736d41eedd8e7f3409c97402b2af51cd59b8f656641afdd96441fa74' }
  'win32/zh-TW' { $checksum = 'f72e11d96ba6cd2d4887e24f704bcb9b5c30a6c1630e417a6e98dd47f70b9530' }
  'win64/af'    { $checksum = 'a2fe888000e450952c0fe932fec4a2fa65239844d641219d5cdfdcd469599a38' }
  'win64/ar'    { $checksum = 'fa0606eeb046f2c470731318735aa4ef410beb098fbe794bd5d3d50e0cf4db96' }
  'win64/ast'   { $checksum = 'fac6025c0dbe0a9030af5ff8da69fa5d32d58f7f929dbfb0dae0790adf79cdbe' }
  'win64/be'    { $checksum = '929b0dd4d8a06e66cb2d71dda5502895616e97e7e2e90e70c604bcd1e2c2afda' }
  'win64/bg'    { $checksum = '6e9cea5466ceec86257df6c95316f306aee50861368ae2f3bbfb777ae1a5e363' }
  'win64/br'    { $checksum = '68cdc414fb5c0497304340b14c4cfcdee994507ecd139ab05e8fc82f7dc3626e' }
  'win64/ca'    { $checksum = '5e3f081235505250d1c824d97dda053a1bcb4d244ac6f8419d95c228c399c2ea' }
  'win64/cak'   { $checksum = '37822e12de42c788d71628f0674e983e506605858b165351fa1197166b7f5a09' }
  'win64/cs'    { $checksum = 'b95c5603c20b9721c4598138242d4959c00cf16e879d35d856be6375e5b666d2' }
  'win64/cy'    { $checksum = 'e5e196d570090033eab4bea3779e7e902513d0a96b7909c1718814f7e6580f86' }
  'win64/da'    { $checksum = '9e1b6782722bca9ba0c7f1f2e2ffe5ca38d85825c17af24bb9b783e28f781e1a' }
  'win64/de'    { $checksum = 'c4f6cdd8d1d5670832c094932d4bc202455450c87db65cf5da7083d532713b00' }
  'win64/dsb'   { $checksum = 'd60d17a27a546572e07263dee93575ef99a13a81341385f0c7339e5507cde000' }
  'win64/el'    { $checksum = 'e89e1701b7149427ad974eb28a093804d47b2a5341cb4309b6fbb4f3b8030e3f' }
  'win64/en-CA' { $checksum = '49772ed99d200e5978eeff71ef6fb2d4732da064c544b3d33296d6bbb9994812' }
  'win64/en-GB' { $checksum = 'c6844362b3649e8a8fb0dc8b7ba091bcebd35c9b5b30f6390bf5ff32281a062d' }
  'win64/en-US' { $checksum = '8756ef32a6be7782d1a0268586d36f79910342a1bae1b607c8fe021989c5202e' }
  'win64/es-AR' { $checksum = 'd11b7ee91c83129951c7c86053c9c1668f23fd68991c84d52e45ea15a4652ed2' }
  'win64/es-ES' { $checksum = 'd97d827621f300be63c6adb2dfbea370efe792ef00688bf231181e24cb77eace' }
  'win64/es-MX' { $checksum = '53586117b12d461756029c8a7b6c876fdbeef0ca9d0a8eae11c8269c307e79bf' }
  'win64/et'    { $checksum = '80fbd434108c65c1e4014f2c30d1771e7113b4b722abef3d65ffa41f2e2361ab' }
  'win64/eu'    { $checksum = '83bddda7307f333b59e78d042516f896be44626f033f790604add3c843f88617' }
  'win64/fi'    { $checksum = '29075abe7ccba3cec2b335400c0c08a7f3a8559b9d0fa0739a6e2a5924a3a0f3' }
  'win64/fr'    { $checksum = '072b32f8c9c1d6d76251c17c08201cb21b5612e6170508c4a4d8df493acb3dfc' }
  'win64/fy-NL' { $checksum = 'af5ce7f2787961f1a31f3e8eeb3939b8e288259c2f9254c0cfc2be38dfef1d95' }
  'win64/ga-IE' { $checksum = '433c707b52284672e03edf7df2f76bae7a093835393fdde620d9d18f2641207f' }
  'win64/gd'    { $checksum = '743907c7c0d646ed658a01e8efc3c751089d135593feab35a85dcfc69095df37' }
  'win64/gl'    { $checksum = 'd00dc6630e5619bc18a96887c77c2474251a9a5f0afd7cb594b3e1296020f10a' }
  'win64/he'    { $checksum = 'ea9973f1fb876c3cd1acac1cffde02452eae406c7c5570043a29a4598f5e51bd' }
  'win64/hr'    { $checksum = '8d9794216935a430362aa0b33c9eddcfe28ceb2759b1f2a3322259bf03b05798' }
  'win64/hsb'   { $checksum = '323c923358a51660f177152fd90d7915e21464350bbed3ee2471ed79b664e8b6' }
  'win64/hu'    { $checksum = '447173250092f2e8b24d04fd50d42a9c06815eb6ce5efc11c3943c3b07b8c4be' }
  'win64/hy-AM' { $checksum = '156bdf0eb9b44d98a7aec0be015a298a7fc15cd700d25dc44c7449b4bdb353ac' }
  'win64/id'    { $checksum = '8754e50381f0106c57b8746c35f6cb75ef0f24802f7214c6a990e0f842daf7d7' }
  'win64/is'    { $checksum = '6588219de31e027bef17c86a54415e490b491ad267a0c19c738b9a88261d9ade' }
  'win64/it'    { $checksum = 'bb9bd406354dc233b37f6fcec253ea4bfe953d52307683bcaa1ecc93f2970921' }
  'win64/ja'    { $checksum = '4cc0c13a3662f257691c9cdd2fdc00ebac988dd9e2ea96a1889d7e3d5f66c1fb' }
  'win64/ka'    { $checksum = 'd39a390c6fef2eaad05581d4d60335f272a5de4534b73ef05fa9c9a2cbf2c0ba' }
  'win64/kab'   { $checksum = '98f9ea6fa9f77a4c0d3bb6fa05a57960dc26dcb4c0e597cbc43426c5707cde3f' }
  'win64/kk'    { $checksum = '76eacfdcf7ee48bb0f662707beeb923f8e4c3bd2b2f1a697787ae84cc2b93ef4' }
  'win64/ko'    { $checksum = '0345cfd174ca48501285d3b0d24c5c396caef88e8a5daae58f91e48024579c07' }
  'win64/lt'    { $checksum = '7c58aa5b28a46cd810b305f50b8df0340bfca184466dc52061b669813665c80e' }
  'win64/lv'    { $checksum = 'e364b306a43fc7baf8d3ad4f31f279f8114ae6c156e56476792ada28562d8e8b' }
  'win64/ms'    { $checksum = '7fed3194c21915fe35f90a03017ca446acb2401bc0ace7b96f95911cd16ed00b' }
  'win64/nb-NO' { $checksum = '0e64e02ab273927a112d9107158adeb44d80ec9610464fd0d84510b3edc76ef3' }
  'win64/nl'    { $checksum = '44dc2c65a148d2dd7bf16454c36bf111f43c9b309f0097bc12cb56c6a29b7ccc' }
  'win64/nn-NO' { $checksum = '96765a16059ca30e9fa531f4cbaf4a60feed229b090929c07c9673566656922a' }
  'win64/pa-IN' { $checksum = '83682a09fff36d8a8ee3aede3e79bfc533a1d338445b169cd2a308c3707d15f5' }
  'win64/pl'    { $checksum = '0737b1d2571b00df433bbad0854957562463bc41c4c188d2ba88db9db8a088e3' }
  'win64/pt-BR' { $checksum = '5492074061893d419b58065ec18b271bc8428a2ed91cbc577c32ef3121c1be7d' }
  'win64/pt-PT' { $checksum = '3ab812bc65816ba1c93879c73474cd2a2c7f253ac3668225ee87f1dd2dd755ce' }
  'win64/rm'    { $checksum = 'bc607927225a22e8a2eb04e8141d1487dd1c8dfcfbeffb28fea04224b61123bb' }
  'win64/ro'    { $checksum = 'abf22555ace6d3a985f5d23711536cb64a6786995be67a50e1241dc47ece411e' }
  'win64/ru'    { $checksum = '766aa549b93e228ee68d0849b3f28d98224affe2a2df1bbfa5a2064d4a550963' }
  'win64/sk'    { $checksum = '469414b770eff13dd0c7f7db8d43db57fb3ce3d4e356ea8915bafb6df39193cc' }
  'win64/sl'    { $checksum = '52c3d1515e1db9f9098e29223688411655ad019eb9560dc3043448542cb2e302' }
  'win64/sq'    { $checksum = '52368f09668d2f5c1b526a463aed8e5480c6bfd9937560c8dc2142a634755495' }
  'win64/sr'    { $checksum = '59a99ac001dd4bb363d12bb4a1c7168cb76c24b78bbdab0f8d52d40281595992' }
  'win64/sv-SE' { $checksum = '0761e7ca0d9e3b254b37773c15c88f5711b84779d98a87755ee392cbf711300e' }
  'win64/th'    { $checksum = 'a4f73e07d72dc1281aded013a332febcdec6e9826c255a2dac7df81e970e8e17' }
  'win64/tr'    { $checksum = '3a9fc1e33c15c78f69752107357e268eb8687474facb98f9f677e58ef3cd4621' }
  'win64/uk'    { $checksum = '0c83f5a03dfcba55352e754b48bc0d090c6120974eb024c9c2bab2df0c1865d8' }
  'win64/uz'    { $checksum = 'b0897517f9b780b7f440bd8478f4229bf53b549684421decc068816a864eaa4e' }
  'win64/vi'    { $checksum = 'ffd7d0927ec9b33e848a8d970952f80ac51759f1866b373d315449bd6d33288c' }
  'win64/zh-CN' { $checksum = 'c0760c807c38b75280a56f0c18da3960a32aa1d9c1f5916fe384444a8e378f31' }
  'win64/zh-TW' { $checksum = 'e4099ac063f40c53a21a5ff425c08e9d359117d8f052450b701a3972b38ea30b' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
