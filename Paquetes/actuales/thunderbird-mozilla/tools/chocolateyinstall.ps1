$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '161.0b4'
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
  'win32/af'    { $checksum = '1405b319f2f0fcfd1d4a692a24d4944d5ace284d20848bb3d63a63d7489a137f' }
  'win32/ar'    { $checksum = 'a82a00d049ab5129b798335356e674b6a030d7783a0f5d6b25cfb229aa4fd419' }
  'win32/ast'   { $checksum = '27b57592ee46d65b909e47452a3aee6bf1d969d7e7889cb6d6b7470ee73475f5' }
  'win32/be'    { $checksum = '9320de97bbf23727198c8e75a37c04c183e4a7ddbee791a8a31c2313bc5cfb9c' }
  'win32/bg'    { $checksum = '45442edb7e083bfad2d354328b8e3139c2a85d8d66804f87c8abd9ca09907c90' }
  'win32/br'    { $checksum = '0f1f3dcdf6da0c7b31bb6557fdc4d69bcf7a28c60beb7cdcca99c85198461ce3' }
  'win32/ca'    { $checksum = 'c0891e62b164baf39730061df18435a3de976c9381baf37687c8dc9046aa1253' }
  'win32/cak'   { $checksum = 'a9f8de60579ae62bdc2aaa2bb0c37e04d320e9bf9dbe4b0fab7569f64d7dbd42' }
  'win32/cs'    { $checksum = '4b19130357bd890d9181074ddab4688cab40b9305060a51ba1ce5a541fa207ca' }
  'win32/cy'    { $checksum = '8b53c3bf7c47ccb4c4420806649ce541f960d0b1a77ff9045ff67edc09f258b8' }
  'win32/da'    { $checksum = '6c7a5582f126ab8d84c458180385aba745a859dcfea48ef9f9fec89eb9f8ec40' }
  'win32/de'    { $checksum = 'd3a602169f34d6b041dc4c5768ebd63bda96a65b0a595ef4243d3543862620e8' }
  'win32/dsb'   { $checksum = '5cd603bcb22007b45ef466e181be6275cb9d0f7576437608a973873ba08b75a5' }
  'win32/el'    { $checksum = 'be0f534546acc6f942f87bf2c5163eb21c1465fda98c23b90d8353e9f1ee8b5d' }
  'win32/en-CA' { $checksum = '64f03516dcfcedec0a1734763d1800860eff6ed1e7593e7abcbec9668639cba9' }
  'win32/en-GB' { $checksum = 'c30d3e897ff47388733ced64a7f22e9f7871f8f9cd49314b60cd9d28b5040d4f' }
  'win32/en-US' { $checksum = '1fe716efef1e235de4cca67aa7a267b1b0c863aaa5a437554e4e865d818cbee6' }
  'win32/es-AR' { $checksum = '3ab4c117fc225a2bfc87df5d5635b7e2d5c74eaabd50c6795848ed369a73285f' }
  'win32/es-ES' { $checksum = 'f2d13e9fadf9ed2647734444a60cc49c9f329a2753f86cdf2e5516e10744c869' }
  'win32/es-MX' { $checksum = 'ed1aec723697e1c3f6e685429a9eba16ed6a131f83571fe86df2001e542091a2' }
  'win32/et'    { $checksum = '1e41ada9528e6225e4fdbc90d1703ea1ef42ef0501eab676ed48d6f0d84e812a' }
  'win32/eu'    { $checksum = '7fb3da3115b1014b75e86b8c3952a45bd7beea054795ca88a0cbc7b793e404f0' }
  'win32/fi'    { $checksum = 'b830b06035f738e8c612ad5ab1a1bcbcb69f5e0925542bdab9f83ee0a969247f' }
  'win32/fr'    { $checksum = '882f75d376d4e2e9ddcc443d6ad45df50713b32e3d8452178d37caaad6aa22c1' }
  'win32/fy-NL' { $checksum = '60d5b27b8a6bf63eeaf107d2b181558596e9e61796eafdb4a5357fc2227bb9cb' }
  'win32/ga-IE' { $checksum = '7c70426ccb3d6dd51ffe179f9d207cae446663d66e0a9e01413998d9ae57d27b' }
  'win32/gd'    { $checksum = '5e275909953ffc274179aea0f76d2e353c077856f65a990b6423374960c7e46f' }
  'win32/gl'    { $checksum = '15a1d139f65fcc4869f26d3c6b0a4cabb9c77ef50cae87405aeda89d6d5becc2' }
  'win32/he'    { $checksum = '478637f7e5a0bf1dbf9416ba45b4cea48e79bfa01eadf3073159f420f77e4a8f' }
  'win32/hr'    { $checksum = '2b870b7db933768840ea76c026ac27aea2d475ac85c367f02af6a84a49fa1383' }
  'win32/hsb'   { $checksum = '3e27c21286195d5c6a4503f7cca21982c1cdf74307d9e15d9bf53ae0ec39c106' }
  'win32/hu'    { $checksum = '0988ac507c12904e69596c62c9a7dd126560179700a5e00827a43a2a9a5fa126' }
  'win32/hy-AM' { $checksum = '3216c0bd3665acccb9e0ba049dc411829ef755173c0521f14896accf02cbef33' }
  'win32/id'    { $checksum = 'ce45b54079d3966101626fc5cbe19251f9f06afce007c2e6dc6a2b44bb355dc7' }
  'win32/is'    { $checksum = '1c43780fc779b0677f81f1353e322d7d6e73e86265074a74bd995ec56f3143c3' }
  'win32/it'    { $checksum = 'db75fa7d002e86ae2df201ad0e3120d5fcfcb7ed6952356347414f39d8ddfc23' }
  'win32/ja'    { $checksum = '50206f30240a85118b100ed5ab92eb800737097e31a7d47393c371ea180a52a4' }
  'win32/ka'    { $checksum = '95899c1890beb3bc03232a4ae624a4fc53a04a1efdd537eae809e00f126cffbe' }
  'win32/kab'   { $checksum = '8c4482d5943f84157f88f8089397f54bb0292d58c8e7501c6c6766cfe9b88e8b' }
  'win32/kk'    { $checksum = '5149ae6533cdb86e6223ef0cb932c8251dbb53b57cb87dce90dc9e5c59ccfa59' }
  'win32/ko'    { $checksum = '4306623a0f4912bf9303f4ac9636a5bbc807f8788336d9316c4afd101adea056' }
  'win32/lt'    { $checksum = '4eef442e323c7789bde2aa22f03017dedccc13d858e6773df0e6a2329608590d' }
  'win32/lv'    { $checksum = 'fe665c9bad3dc54d321d26cd2f9998b4e5198fd639838e7b8a7bdcf7a3559a4f' }
  'win32/ms'    { $checksum = '4f0bd4e02ce805c77f28847afa39ecf87db063c419078ce94514098a04f4af73' }
  'win32/nb-NO' { $checksum = '776a8ab488a49c756cf34ad2e15d588e627af1a5d4f7e9d1c366b77e91f1d74c' }
  'win32/nl'    { $checksum = '7bf43b1c8f3c8639875b2c8cbe6661d0a124e8d5b8520dcb0401b41c11f05cba' }
  'win32/nn-NO' { $checksum = 'eda0a610bcc5575de28b92659b648d68b7208a6e371d5593a6535eb9fcde457a' }
  'win32/pa-IN' { $checksum = 'c8cc2b930b9f7b8e6b620051c6b0c9282767b1f11e32be600d4d60e7db7311fb' }
  'win32/pl'    { $checksum = '8c07f70e4b6080d439431193a32016496b6da8d31852be99558b82d2e4881b31' }
  'win32/pt-BR' { $checksum = 'd8d6c643b73c9c8c8e39834c637f8507fc912ece4750f6ff41ae92d62769c055' }
  'win32/pt-PT' { $checksum = '027ba949de367b6c863e156e232e47d9cb449d1a7f4b4f86eeb51d4444c3b19f' }
  'win32/rm'    { $checksum = 'df2e1b927161f315e3e24e99ecbd6fea5069f023d4503a6b70f7bd6941cebe5e' }
  'win32/ro'    { $checksum = '066d3b738534d8b801ceba828f1fda84ad2624d3bfc7450402fb68d6652552c5' }
  'win32/ru'    { $checksum = 'ebedb52582e816aa09d1f04a6ed94810f89ba2775d41cb6c5b96b125e33e9970' }
  'win32/sk'    { $checksum = 'b52237600eda1c975e776d03a83684adfd45e2ee075eea4c6068329637bf5e60' }
  'win32/sl'    { $checksum = '0c09671986f5b1403ad144220e429e1ac40702a6020bc6c689ef6a5f24a04343' }
  'win32/sq'    { $checksum = 'b4a5dacaf61041b4c28aef7b9f6cb44c2cb1f379ccbea23f2a98793606bf1146' }
  'win32/sr'    { $checksum = 'b07dce93b146d690597b068f14674f812b2acfaeb38727c2d127322aa21d2975' }
  'win32/sv-SE' { $checksum = 'e86c22a7abfa2a6caa78dfb08c6626e1a3230e26d5a529df0299c18b3e5bcd5e' }
  'win32/th'    { $checksum = '6768578b4ecab59c4ab7ad9868f1e036d492cf3900ee9ba895e0658dc3f13ece' }
  'win32/tr'    { $checksum = '79e4af878526d0aee89ac93c31de10c3d883f7855525a9fef37c6236eda2eada' }
  'win32/uk'    { $checksum = 'eb6e3a0fedb897a5e336074c4b336583a0fe76de345d4f6c9efb989534b1658b' }
  'win32/uz'    { $checksum = 'd05ea38e299c4b0a7fa679a8144ac0c2b706774ec0cf170c8d03649185a0b71c' }
  'win32/vi'    { $checksum = '24f4a01f91cb059301d99d359351996ad5b4f1e56e5d3fac1ac29b0732b31909' }
  'win32/zh-CN' { $checksum = 'fada1832d8db050e3469ca89f010d799a911eb8b0443452d508f7ae8b75c0857' }
  'win32/zh-TW' { $checksum = '527258478f14abcadff9bd26f266c937f77afaa62de6e993bd7b5d41c3098082' }
  'win64/af'    { $checksum = '829b35a43be0b115f715ec361ab15a2eae68a387035b3c6d71685fc3a5d9d032' }
  'win64/ar'    { $checksum = '0ac9638edd2b61b07735397068a0af8f082e7b8e613eb044dbc33ec58894af7f' }
  'win64/ast'   { $checksum = 'c7cf01dbfded4f723e984a6041f3c96ce64e5e0445c78515c4655f32ac60a79c' }
  'win64/be'    { $checksum = 'eba62b085c5e79e0e05dc87b094b915780b5cf03b4ae73eb06d7f3f2f28d9e12' }
  'win64/bg'    { $checksum = '78ecb5da84bb0f29eb57a3ec150b8fa27991b5c8f3abe5601f19826943ce656c' }
  'win64/br'    { $checksum = '7b4ff5a8abfeab1b0107317b01df818f08d3a2b92ccf935bd89b7ec440c2c320' }
  'win64/ca'    { $checksum = 'b3a9799ca52c1ffa0b3d5093619c01400f595883ee4c919e741c4efb0a5f432f' }
  'win64/cak'   { $checksum = 'f9496b6449c39123dd4efd4d6e3267513f10aa7937cf51ed32fdccf630ff3fb0' }
  'win64/cs'    { $checksum = '7ceceeec0249ea205cee39dcd22f81bbf824c0732282e72f0b93d6f652f786ec' }
  'win64/cy'    { $checksum = '53e5614c5f273d044a0abda67363d9a2821a3b74f508d79378ab8090060c0a89' }
  'win64/da'    { $checksum = 'c7a9af88f03401b5f6cd4523e321b1f54f8d77e1dde529803d34a7938e6c0448' }
  'win64/de'    { $checksum = '31b5b99390693f3dc7058db3e646087ba5c0662b69e04596fc7c6c98f0a33a7a' }
  'win64/dsb'   { $checksum = 'fd97fa1777a92b2b2fea3ff3fdfad981a71c0c04e9bd4c27ed48605bd2e48739' }
  'win64/el'    { $checksum = '28bd3afcd7cb0779eaab5fa97b2c12290818881009c118bdbba44de4fb137b30' }
  'win64/en-CA' { $checksum = 'af7154628bb43943c11621aefaab849c1a9c95dc27c3acd8622d33e720a9835e' }
  'win64/en-GB' { $checksum = '6b1a95d7617af8e6919cc78e689eeadc73c4d10de3c4da32fb6fc20f7c9a5b02' }
  'win64/en-US' { $checksum = '85e5458d7915eae48ae36850d50a6cf3ceb35c8ac45042cdb63889e3f416f06c' }
  'win64/es-AR' { $checksum = 'c603fbffb8f6d6f7d44063b8ed4d4f87958dc5c1f13c6d98da09503687b1771d' }
  'win64/es-ES' { $checksum = 'be51c85fbbe0c78152d95f64613e48f27be0301d4e8c599ec4a01abafd4ec97e' }
  'win64/es-MX' { $checksum = 'c714d012321b69d7f6760604157ab094e19f4a9910f2ae8c7dbfa2923ad71055' }
  'win64/et'    { $checksum = 'cf3a933284c58c3ce1d84e6f1b4211739f98c6557348efa86a798eb1030c54d9' }
  'win64/eu'    { $checksum = '1cc5660f6408d3c9e076fc783088c57eb8d53cb3ab121155a42f4d03a134d305' }
  'win64/fi'    { $checksum = '6eeaea479c06955a6eb83290ac8bb56ed6062bdb53d395968aed8c964e3f2f8b' }
  'win64/fr'    { $checksum = '72184d983724324fdcb1dcec1ff1b5afd32830f9bd8f61a066e578a9c4255a91' }
  'win64/fy-NL' { $checksum = '6ab9a80d165f0896446ef2fabc14baf40e376e2412bf7b12c7b30e79177150de' }
  'win64/ga-IE' { $checksum = 'cd07b04bf2d6eaf2a155b16df6c1906488a2c652902fb2bccaef51c4ce577e32' }
  'win64/gd'    { $checksum = '22c8ed894eb67fe5b2b3fff1e55b87a0201da951ba1297e20a8cdbc5a76a4bec' }
  'win64/gl'    { $checksum = '1d9e7fc6e512cc67b4590e4584c8fd13641a0535fbf0daf4720bb9206a458c1c' }
  'win64/he'    { $checksum = '5d83ae225caf022ff27a343c61c961a764bf6e9a59195ae631d055cc1583ec80' }
  'win64/hr'    { $checksum = 'a06cbf9b7867b35926752a7483558b46701619a220542b2b215af8505f189653' }
  'win64/hsb'   { $checksum = 'f8715d9bd372735c9a5fbe15cc9ead8d9873a033d4b0794fc068c3ad5b4de534' }
  'win64/hu'    { $checksum = 'e2b977d8e220925aaebd8a19ab16553a14a374ecf308f3db2095e8ed7523da7e' }
  'win64/hy-AM' { $checksum = '986a83332affb721b5b032048976b35c606ede9e1501aec17ba114b62c965e50' }
  'win64/id'    { $checksum = 'abe7da7f6fb27070116d011bf824f97e56431e9a218c3c444e5a280c958ff8a3' }
  'win64/is'    { $checksum = 'cf73c3ae7ea00b807b4cb640918fb8fd027684f1fe882e41c0e6f9df689c5b40' }
  'win64/it'    { $checksum = '4e20d35acb8d95df6b2ea608ae5b5f87e5773d975671140db5c6e23a85994305' }
  'win64/ja'    { $checksum = '42caa2f52c186de668fc0e79b95b35fc48bbc80b93277f686f46048df271a152' }
  'win64/ka'    { $checksum = '2f62fd96ef5dea30e34029ee52b8db0549776c766bccd7755861d1ef18af7c5f' }
  'win64/kab'   { $checksum = '37bbd5085b85ddbfa21649ea886336174a5df59a0f2a3c02b4346f9c15ca5162' }
  'win64/kk'    { $checksum = '64d3ca81896acdb8573818848c327bf78050f2e1b293fec5604eabcc80720937' }
  'win64/ko'    { $checksum = '29a83af4a5e98ce746ead45210f3386aa4baba1301b8370ca0af2a05760220cb' }
  'win64/lt'    { $checksum = '321667cbb74e5f6a23752ff5b3a65455a465f89d546cab672d193f16afc71e4f' }
  'win64/lv'    { $checksum = '77d81198fbd59804f8edeac71e4c2951a3fab4723ee9c8ee50a65151102c5721' }
  'win64/ms'    { $checksum = '2e3932c9c99b0545707cf5334fd2cd296021b9369c1a8fe92bb4a2b309905c2b' }
  'win64/nb-NO' { $checksum = '1fabef3aa307100c538da6bcedf9d4d7e5b88294636f64f51e07540c29a45dd1' }
  'win64/nl'    { $checksum = '5ca297f23d8e1e1cc799b44c77e668ede3147dd07703f84413f4a23f6cd53402' }
  'win64/nn-NO' { $checksum = 'e064333808eca4fdf5085fb09f3860f90a9ab32451c774caa002eb8b072918a6' }
  'win64/pa-IN' { $checksum = 'd20c294eeb7e25770fde11d216235e236ed5f40d1fd8422e92f69f09d0d2302f' }
  'win64/pl'    { $checksum = 'a9428a49fe9bbd6ea74ef58e4535c08a6c1e3172eb1e2df59aa214699b1078e8' }
  'win64/pt-BR' { $checksum = '7014c4f1fa7f34f4223b320b57d4ace14ad3210afe94f8833f36825bfa184717' }
  'win64/pt-PT' { $checksum = 'f6cb52db8bdb671e028621cbba8807317a6f5f96316a43f26c643572408844b9' }
  'win64/rm'    { $checksum = '7b131f246f2d3b877cac2e4632928455130aa98f8bf7ff593bd2936fa132d135' }
  'win64/ro'    { $checksum = '49fd27feab0713254f53dcc8c2733a5aa4e982ccef3958806ae2063ab94246bb' }
  'win64/ru'    { $checksum = 'f58e017c18e4eefcbdc708283ef24fbf376af93d52f2206f7297076b5611e67c' }
  'win64/sk'    { $checksum = '7036d63ae7c004348e67d8016efe9e186d4e7b2a82a8a5e4a6af6d8116561cdd' }
  'win64/sl'    { $checksum = '5dac1b1b2e6478ed82fe218a777d2bfb6d22fc8051510d45b129a02626562564' }
  'win64/sq'    { $checksum = 'cdb31eec90549a99ab76a83b41b175f52385e03f49d89e59b034426f70ea8e02' }
  'win64/sr'    { $checksum = '37acb288a448a4cc606ec254da65190ec57bbcb0e5ac09ecb0cb9734ac0e534d' }
  'win64/sv-SE' { $checksum = 'f50dbfb889104ed7bacde794bd4fa4c954c55d84f54521f6e290e1ad1d3456cf' }
  'win64/th'    { $checksum = '96b3d18862b800d87f2e182b2de62e9380de4b45e6ed98e5afc2f814558da067' }
  'win64/tr'    { $checksum = '49b2ba9c5f65a57fafe3b3e46fcf5d654424d5f3ff201f18e77e028a7e6f09ae' }
  'win64/uk'    { $checksum = '10db4fa42e49761d545ba3341231996e50c7dc9fd046d718b7a7be0e6ad5bb7c' }
  'win64/uz'    { $checksum = 'cabc070cec3e967d923e2df5cc39069293522010153ebd79c79af83a8f0e0c5e' }
  'win64/vi'    { $checksum = '7b034895771d35d05040ed7f6eea85c6ee3b6278b9e178a4297cc15daadfc858' }
  'win64/zh-CN' { $checksum = '724125844f4843b8d9816e1d2cee53b0a294b82cfe8ca571648654419e11733d' }
  'win64/zh-TW' { $checksum = '744f00203f1adb480219aec56a7d5417387b310ae7b8a5e58ff5283096d9de98' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
