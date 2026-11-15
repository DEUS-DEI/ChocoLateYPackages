$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '162.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/11'
$build   = '2026-11-14-09-48-50'

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
  'win32/af'    { $checksum = '13aae0ae22fc769cf2bbca033195362e061afee2667f6949dcd72da896fa644a' }
  'win32/ar'    { $checksum = 'e28258d7551a38acf2f5fe85f4660c4ab06c1cb6b41b4e8be6c9aa2c0b4e4c4c' }
  'win32/ast'   { $checksum = 'bc08340e5646cef7b66406e98191c34448cc710399ce560a2cedf1dae7f6eeaf' }
  'win32/be'    { $checksum = '11c5ec26b785a5200eab78f42d992c94f57a3b9de916195bd1f12d3bda88180c' }
  'win32/bg'    { $checksum = '630f23dcfd247e6aa6d6c8cb89e0ff0c9e12fda422cdf73be16f2ce9c6f86421' }
  'win32/br'    { $checksum = 'f70227c9e26375b3f84b4c2fe3bebe7fb585df27bee3a3927b9ed2e58b1134ac' }
  'win32/ca'    { $checksum = 'bd74ba44cf60cd76fabffd925d1b33ff43ae3e1b1003e701d7ac8081088ed689' }
  'win32/cak'   { $checksum = '5a48521d26de2cba0ebc48443bc5ff1874053940300b22a60094cafbf83afa92' }
  'win32/cs'    { $checksum = 'c870d4bd6a3d11263d4337f770f2dcb8f9acde2f147f6a0cc0f8e2543ab86d92' }
  'win32/cy'    { $checksum = '786abd73fdf9924adcbf8a39805cd4c380688842d69432097f0bb467059e52bf' }
  'win32/da'    { $checksum = '63ebb5f50d5944ac9bf99158026636aa5130882631cd9f65bf55fc47464b9699' }
  'win32/de'    { $checksum = '9dcee2df12da0b40b16ebcab13946d1163227246d2a2e8695e5418be76b64b74' }
  'win32/dsb'   { $checksum = 'c3a671f796e408e9bdbb617bbf9c86ee8f0b98705ca952404bcfa95e22b93b54' }
  'win32/el'    { $checksum = '03bece15460c313cafedaab881bc39d4756f9e31bff73e4e046cb7e81e615a03' }
  'win32/en-CA' { $checksum = 'caf90b6da283654f861b674f96933dadeac76a50c7d6818bca96269d5505a03e' }
  'win32/en-GB' { $checksum = '02d4dbf73a3fda09f5acc056b80241dae329174250e1939db551cc4d85c1a608' }
  'win32/en-US' { $checksum = '744fa0b5f913e244ed2a8e63231b08a95ff914bbd01284f2360d8fc9badca583' }
  'win32/es-AR' { $checksum = '67e62cfed43c35f61602ea26e4f924cdb8897d512be2130f63ec50fba41b1fe6' }
  'win32/es-ES' { $checksum = '2bb870d488c13e767c05e020b64654ed2160dffe27b2822bd979587afb8c76c0' }
  'win32/es-MX' { $checksum = '10640ca82cbd1e8d5b76ca30e790b4948fb652023af5c2416ffc9fa5e42b138e' }
  'win32/et'    { $checksum = '1b25f24123a12410cfa8c9d03c4bd30ea4cb3b45ae5c53bb89807c140a27f4af' }
  'win32/eu'    { $checksum = '14e8e04cbecc6c6fedcf2254b6201e8d8c7743474b84a501188aa7be7313ce06' }
  'win32/fi'    { $checksum = 'e2097ed64c13385928c1337a4298dc952258c9661324906ec1135711daf6b848' }
  'win32/fr'    { $checksum = '8c37c7c8860454cc058e8dcf24aee6a8c64013f03858e6c20ede1daf22415ea4' }
  'win32/fy-NL' { $checksum = 'cb576dcab52dcb3f6b788943c65ece600328e8b36a74cb67fdbbf801c67e1702' }
  'win32/ga-IE' { $checksum = '82af1c3ce40c042be7a2583ce31d0064528847ea2d56991dbd8da38369cb1fb5' }
  'win32/gd'    { $checksum = '1dcb703004669f99e534f7b4764da000007c9e0f278e287cbceb0b0b351f8942' }
  'win32/gl'    { $checksum = '3bf4dd6b9aa343f366287dab1b83394d6c3a03585305b49a6576faa6b64d29e1' }
  'win32/he'    { $checksum = 'af8db85e46b1a8442abf56710e64992d530042341882ee7fa036be66b2daa75b' }
  'win32/hr'    { $checksum = '43e466c3d39255f4368d6cec6a7f8a7a159057a6a2bd8c9dc27735167d63ed9a' }
  'win32/hsb'   { $checksum = '60d529e6d67b422ab4933fa8cb521b25fb893776ccb9fbbef99bd49b7adad63e' }
  'win32/hu'    { $checksum = '8d626859708ad7d2db632b8e91518edc575b9c2e1c081af73712ec70d4e877f2' }
  'win32/hy-AM' { $checksum = 'aeda83c444d492fc98286e56eff7648c4ecbc16ee2643eebb79d6b9d572e8cfc' }
  'win32/id'    { $checksum = 'a7f78c2d905b0dafbb180cce8d1c03abd5562edd16b03193d1bf74b9f9654659' }
  'win32/is'    { $checksum = 'bcde20e97fc77728a0bec6a3e27b9ad4b931b89d72ed8e92f982ece5eb05533e' }
  'win32/it'    { $checksum = '3651e06bc7d882339ea16c68482b59182e6ee478a3bd59ee24932e826246a176' }
  'win32/ja'    { $checksum = '78a86e83002e2091aab8b93803eaa44a57686eacdb8e9cefb3f5eedf15fb0f17' }
  'win32/ka'    { $checksum = '95922b6b0a20108bd77f96ba2076a70fdc143f324896d55973a1923ab28d3f43' }
  'win32/kab'   { $checksum = '03c8e59278b547684e422a64a2c9aa5ea18bbb5db8637f5232a397286c2a085e' }
  'win32/kk'    { $checksum = 'c5a969c682237ddf9aedc4c9a0a11e52fb577b72359ae492e402c8bf29f0b620' }
  'win32/ko'    { $checksum = '22b4940288e126ea9a6e93e3e603417c788a168fa32ccfe1916f14b8ef1075ef' }
  'win32/lt'    { $checksum = '2653dd28565eb60e27bce70b8976f70f2525bdbd7c5060735399bbe4415f1602' }
  'win32/lv'    { $checksum = '1d06e8eb72410671f33ed0f029ec5ffa6048ba50c2a260aeaba007bd8fcd7626' }
  'win32/mk'    { $checksum = '3f60d0261972aabd8f607d740fd9bdb6af050ae261abe314fea4bd72c32d059b' }
  'win32/ms'    { $checksum = '0a008b3e4760cb6f4712747cb51a4a62d9299c69d4f9e08cd04a09ebcd96aac8' }
  'win32/nb-NO' { $checksum = '9a966bfab6f7d4e6bfa2fad6c7cb287dc8a0559c287c599c995c9fbf06380913' }
  'win32/nl'    { $checksum = 'db753b02c71a16e95213f0ef206c604654b38d3f23e9bacec3719992a61a9303' }
  'win32/nn-NO' { $checksum = '273c52e474066507168549d0e37da895d0bfee3aadbfa28493c8c8653c2a0148' }
  'win32/pa-IN' { $checksum = '941c59efced304ab7e5d9e12fc846e6dd3c4d344ee827a4e820ec477e4dbbf9f' }
  'win32/pl'    { $checksum = '4940dedb4dedde7b89d1c2b4eb846ed41ee6586b26c0612a0aebc7f91ba494ff' }
  'win32/pt-BR' { $checksum = '3e837339682f0ce4ffc014767be46fb2617b19d75e5a6169b34e4b1bfc8bf8bc' }
  'win32/pt-PT' { $checksum = 'e80fc59a21a2d6f74e4644f6edee3347c94193399afbddbdf726e3842254eb92' }
  'win32/rm'    { $checksum = '7e8040812d56d79259ec7a9f557759014c8fd627f4961cd9e3d8511d1133fa2d' }
  'win32/ro'    { $checksum = '97dd92e0ada8c06429ada39ddac32172875cac61111a9dcb51794517bd179717' }
  'win32/ru'    { $checksum = 'f28f56bf98e4f0c99b882675d0de6388115e5fbfc4feee6235c4cb73cfacb26b' }
  'win32/sk'    { $checksum = 'd5930607253638d269fd646a81c96d39ef16c3c3ef4c55b49889de1e34eb80fe' }
  'win32/sl'    { $checksum = 'b94be04f6a96f05d08f567b4a88305738daad5fb98a464a5d54f6adc2893afa2' }
  'win32/sq'    { $checksum = 'd25584edfad3f810ef15bd03bb3d4f02b341414a7a1ef7b53c1c1427a782bac5' }
  'win32/sr'    { $checksum = '6b4cbca52a611a254a862293e0fb76e4e55a5e0775048e17154c399173e83337' }
  'win32/sv-SE' { $checksum = '6bcf2a2678c4a36a9237136815f63cacada1bf955d8324e7b3f096443801f52b' }
  'win32/th'    { $checksum = '61e3868a07965c0f5dc60bdec4f9411c1baaf9b69a4cf3b4f7d8fd275da695af' }
  'win32/tr'    { $checksum = '1670d50dd819e12a56057d0600648ebb97107c631d1a7ff84f86fc80f158ffd9' }
  'win32/uk'    { $checksum = '6a43232ab8ac62d03d7c8e5b5f9d1da993c99de9a809bbaf5217743276e0de09' }
  'win32/uz'    { $checksum = '392e4a5b6b8688ce6b6d684cdf73a715f7ae9d2e5517b6853c5ac0cd6af6b8a6' }
  'win32/vi'    { $checksum = '2d3adc4682fa383a15bb9a718d7e47c25147ded7c18a840a530cfa13b72bf7ae' }
  'win32/zh-CN' { $checksum = '24fe502d7d9b973e4f38d4a6b6cda06d2b4b97450935e1555c9af92c305a8ed8' }
  'win32/zh-TW' { $checksum = 'f8b6f9201a3d5fa40a3f323225eb5044af62801ae8626315df845f38243c76b7' }
  'win64/af'    { $checksum = '9f66e0f9f71640c2ee50b3f9dc848cd3814307ea7edc0809de23356bd8711bef' }
  'win64/ar'    { $checksum = 'e22a663767964cad787508a793a9ed85921e1c25bc13ff13df9f967b7b223093' }
  'win64/ast'   { $checksum = 'da9408f8a64a97f3d2b166cebc380f2031742b4b9fb1752719838d38f401e34e' }
  'win64/be'    { $checksum = '1bdde1d238102cf3167fc875c297cf5d0bdf86b9a4e23b19027666c237cfd2ff' }
  'win64/bg'    { $checksum = 'c4f4bba4652facdf1c9fd70023714cacac1320de81fcf6cab70703bf33a20b32' }
  'win64/br'    { $checksum = 'b1154f9157a137e9a2a76abc5409f7eb0a43c834672002f2a3faf41c7db0264b' }
  'win64/ca'    { $checksum = 'b4e389de48539fdfc72e620c423b59ba502e79054733a2efdde3c03d52544183' }
  'win64/cak'   { $checksum = 'cc7dbf1373b61434705a73b1c9c9699695a94ca3e2727bddfd2c417e60d08b43' }
  'win64/cs'    { $checksum = '0ce74474b3e8fd5c04ee8042364f525a8980370862ddb1dacde1f729ad7e753e' }
  'win64/cy'    { $checksum = '42cb9251a2f3f950c0f8cef10d94fd3c61c5b44dc92fd425ab21289d19b3ac5d' }
  'win64/da'    { $checksum = 'db6098968ec1931e0b139f501bdc28e591c2fd0da21e588ff678d9a7093994c6' }
  'win64/de'    { $checksum = '878d98d0780a0093831e27ebb311a189db3c17e5d5f0e4996ea8109df91df54d' }
  'win64/dsb'   { $checksum = '8f520769096d19923ff93a360beb0bb2ce0c33760077b3f7d6fab5f6de5a7e13' }
  'win64/el'    { $checksum = 'da6afc264b682c62946c6e295c21179e4effe61f7c92a656ac64ca9d95e226f3' }
  'win64/en-CA' { $checksum = '48d412c67e29572b2adeeb3e4b6076a1e0421ca73850f955f4dc7df990540bf7' }
  'win64/en-GB' { $checksum = '7c6a67dc50a2b9b9ba6d9401fb164c08d54475f6079b5dc2df10a572cc1e7f9f' }
  'win64/en-US' { $checksum = '1627c04688082ac7d1db91732506358909edefcb5dece470bb4b4f7dbc1f2215' }
  'win64/es-AR' { $checksum = '55fbce91f60980e705389d80e64c340d315231fcdf828182de0d8e39a63c1a9f' }
  'win64/es-ES' { $checksum = '3bdac76e6943248ed9cb44dcdb02966b13de533d7053c3d80b1fd1e494e0803d' }
  'win64/es-MX' { $checksum = '9b023d31aec56e05f87bf7c8fdbfc940b6434c05c7d5cf1898098e43f752d0ac' }
  'win64/et'    { $checksum = 'db8dd3fc88a5fbfa2f456edde6a9e505cca988f9d28cb0f6bc6494c7c259f352' }
  'win64/eu'    { $checksum = '836b6197ecc5e33701f91372f3e440a854ee23a39f12b36a63f18d70326e1d4d' }
  'win64/fi'    { $checksum = '9c877ed376e70a95d7054b25f19825138797c87ddf1f8aaee8f84f0010d4a8f4' }
  'win64/fr'    { $checksum = '7d6710f42103778f3243ad23d5cb96ec1c9d4712d5a816ab748af86a30696233' }
  'win64/fy-NL' { $checksum = '8d9f953b3501ff547b9799e2c1b0a571a317ec6266201c7410789b43a2e56c62' }
  'win64/ga-IE' { $checksum = 'a0f9023a2308a3545ffda4073751dd2f84bf587e9120245385433be39e2bb2c4' }
  'win64/gd'    { $checksum = 'b3030556a53d71b93dcd0007c4bdb1e505a79ffb2fcaec9cacfb74b983734bd7' }
  'win64/gl'    { $checksum = 'c07e874a155bf51c78c2829e2a835f498e1c40422f8b1935fa5b79339bc12411' }
  'win64/he'    { $checksum = '1d94e141a656adf313aa97d67538756e03779ded3820f1380240d99f358a6106' }
  'win64/hr'    { $checksum = 'c558104cddb17621da2f27eb67863c985a4b1b0489f854ed656ba9525744efd8' }
  'win64/hsb'   { $checksum = '2404e883cfd6bd1400023595fcaacd8cb1e1aee6529e0ae747602902ca9a942a' }
  'win64/hu'    { $checksum = 'd6010c8522b6e4d1a40b65bc9829f12ef6decde72f41ca9ea0f1854e67d9e2ff' }
  'win64/hy-AM' { $checksum = 'ae6c90715d31c746afa3dceb79bafa0c8133554c4460c0e5e49ad8a78663d647' }
  'win64/id'    { $checksum = '9dc85e2b14a80d20a183edf3d86746338beabf5e956d8806a57318b0b232f0d9' }
  'win64/is'    { $checksum = 'f16d8e2540f305e7b00e8e0c3dc6c42ba6ebf5cc3e87b6cfa4538220f44b1e18' }
  'win64/it'    { $checksum = 'b311e03d8cb78c9df844107916338fabd843b606b87c12b2c33821961e725eaa' }
  'win64/ja'    { $checksum = '85b4b3ddb93e7412d7f6c8c4cbab6b36381ac68b6221fc8956fee6ca66135f0c' }
  'win64/ka'    { $checksum = 'd5fbcdb2d8eca794b74e17e48c03fad4d01da3d779223016b6200842c9c8bfdf' }
  'win64/kab'   { $checksum = '47b743f5c2f7c2912e709d13c5a6bc2eb82fea8bc2f164b99c1ac7051a2788c8' }
  'win64/kk'    { $checksum = '77c1d8973354de91813983b962bde76cbe83ac4cb46300d73bf817579a6e4917' }
  'win64/ko'    { $checksum = '9669f5a76c0ae975fda5bea5c2e3d99c508e9f32ff728d276662c7815fb51036' }
  'win64/lt'    { $checksum = '0db3df902ce29fccb14f990bf8e11b34780da931074108de01f926e43baf761b' }
  'win64/lv'    { $checksum = '2388ffc3df380717cc00afaf3bd9cf92ecb2d5ebb4a51e76a21fa30f63275ebb' }
  'win64/mk'    { $checksum = 'b509746f20c8c962e61195c78f7db8355cb13e295de866e3566701b6f3e7d6cf' }
  'win64/ms'    { $checksum = 'c8a88bca88973b7d27a579d1c62c455db035eed5c1793ca40fb7cd3492fca940' }
  'win64/nb-NO' { $checksum = 'a1a42ea009fda7552ff05a8379052a24330e44f82294a55a52c1fc2036f3dd8d' }
  'win64/nl'    { $checksum = '0e7ef9682ab834a3b4a101a4e70cc54f664e55754ed7df9e466b6f9e8223518a' }
  'win64/nn-NO' { $checksum = '537fc8bca68c8d36d686a3967b292e998644368d3944cc4808fad4fae708af00' }
  'win64/pa-IN' { $checksum = '96f8ca1dd6273413141836e5e990df2530e4a07827bf2381ba335d8e13f98454' }
  'win64/pl'    { $checksum = '9ed6de9bf87dd26f798a745769a8360c0f9050e65d2cab388c32438eff33c5e3' }
  'win64/pt-BR' { $checksum = 'b68db27e16f03388c855f4b5f8ef18695785dbb7c4c6c56207ebfd9262be5e5f' }
  'win64/pt-PT' { $checksum = '7d991e225c64d87c584e44a8ece90920ffc4c7cbe2b0fbe659f731f49cad2787' }
  'win64/rm'    { $checksum = '855e2cea96b7e1869de337b25985844df8b7ca957113b5aa7c1e9aafeef7f91b' }
  'win64/ro'    { $checksum = '5f996521d46c0ed90d27536bc893bc69dc5b6c42e8f3db119120201cc0947279' }
  'win64/ru'    { $checksum = 'b7b313697e747ceb47b969959106e3360f618a8640a1bff9cc8e42593f95892c' }
  'win64/sk'    { $checksum = '99fac0705c084f51e180a11840fe8458b3f8146a1c0157f31ef88f2823c02587' }
  'win64/sl'    { $checksum = 'f93fc90817fd7baab4e67329ef890dbf30337f57c7bb42bf9d288e7116ac874d' }
  'win64/sq'    { $checksum = '7e3282658f611a8daa68fa0803b8de87e6c53198698a823db4269c3dc44d4e5f' }
  'win64/sr'    { $checksum = '3b7a8df77b24f40fa93b6f554f5a6c3a3a5c43f258655c80c7aad00a75101d7e' }
  'win64/sv-SE' { $checksum = '355361aaa601a96d8cf918abdba72e2f45f09dd54f663d6c3bba1351bdd9bc73' }
  'win64/th'    { $checksum = '401d6437dafef4fdb3463efbeeb5cd831f9db4f5b8304a7d7ca43c9c45243deb' }
  'win64/tr'    { $checksum = '03c1c841c8c2fcdc354f04e8bee09f0e4c3dfeb4366013b3f5af161d9f4c6c4d' }
  'win64/uk'    { $checksum = 'cac61d0d091f761ae709e0144e5e1ac56204027cbd7e446dd27f871f88607656' }
  'win64/uz'    { $checksum = 'ec53d157b2c27ceb621c36210251d200955e45c6f859eb85fe931f6dcdb11ef6' }
  'win64/vi'    { $checksum = '3cba682b5072eb84583450dd74a9788ba1285e809e8a2ce731aaa80e85a16c2a' }
  'win64/zh-CN' { $checksum = 'de965fe49a411d09892ae4b095abafa8feba90d6e710c22de294ff9ff8a1d20b' }
  'win64/zh-TW' { $checksum = '45ae5e596e64fff9c01d4654858a7c127c4f33cd2285ef6206a3471041b6d4d9' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
