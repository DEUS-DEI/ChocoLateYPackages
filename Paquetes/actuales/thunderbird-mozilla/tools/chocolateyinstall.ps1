$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '161.0b3'
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
  'win32/af'    { $checksum = 'b6e9be164ebf1a092e1e4e8708469634325909bcf8bf0b5aa08c9f1127c543db' }
  'win32/ar'    { $checksum = '1ddecb6e3ae994a5814d9c5e474596560d32e0f547ff519244176c53d63020bc' }
  'win32/ast'   { $checksum = 'ef8aa31195b511874f0a60ea1cc528d04f5fffbf24b2f153b4d7b01b1dff5c3b' }
  'win32/be'    { $checksum = '04c94ade9bbc6b4d934bd88b0a2ffc65289d6ab6c6d05c3366c2c532aab17ba7' }
  'win32/bg'    { $checksum = 'ae26c70aeec2908b6b68eb36f0dd20b0cc15b331d79587ac456decf71681e4ec' }
  'win32/br'    { $checksum = '2f9240f3c075f4510584c1b376e9e02f0a92cf8c1d883863e456478b1ff9d2a7' }
  'win32/ca'    { $checksum = '03029d8041a411cd0f2248f918eb8a94400bda6d399e906eb9466fbcd50d067f' }
  'win32/cak'   { $checksum = '1aba1e5917cb92e4cff7c32ea763bbab288b84a590a521ef56cb8f5358368375' }
  'win32/cs'    { $checksum = '200a6e2e57daa380f3e3d5e89169c3d63675073f62d3dcf2ba3ded2b00152d50' }
  'win32/cy'    { $checksum = 'c56cdaa99a6b4c8b27e821e98afccf4cf88ebb8d82701d1a067eea74a3a06f09' }
  'win32/da'    { $checksum = 'fb0086d1c179189aa7f169fbc5647f072fa99aa87925bb42af0153216a33d3fb' }
  'win32/de'    { $checksum = 'ff5389eea85fd9520833511f99daa886e89578435a8674268200b47a797bdd8b' }
  'win32/dsb'   { $checksum = 'bf6fdddab34bfc8171e1de9e95594d099d3ea38994d608ce8b513bac6f0d7f83' }
  'win32/el'    { $checksum = 'dee5c89e6a7c480d1456a84d158d45242089cae7dab8f2151ccc30771afb7c3c' }
  'win32/en-CA' { $checksum = 'b9ae6505a915de2e548490be553f1ba9a0b905c5775501f6b1b52cee836cf024' }
  'win32/en-GB' { $checksum = '1e5836781e7eb9481a7eb57e3108e70663122707ee0277fd5e0455f1dd2a99da' }
  'win32/en-US' { $checksum = 'eb66ec8936b5e67f9d44d2c9562903cee2af398c1f199122827bcdd59c9d2916' }
  'win32/es-AR' { $checksum = '7ab05bfc15ac17da0515b00ffb02ea59b9b2358ac544da84d5035e91631910fc' }
  'win32/es-ES' { $checksum = '10fa9ee886a12623ccf1a93406b0064e16311c25c469087f6c039e20ec1a154e' }
  'win32/es-MX' { $checksum = 'f5efe62a7c09a02022a148cf86d42955b07c19520b0d016e2ba9a18c3ade752e' }
  'win32/et'    { $checksum = '3efbcadb25459fc12483ad9ca03499fc999bf0fc1d540dbc5e134a644265185f' }
  'win32/eu'    { $checksum = '3b0154a579c2d8e8ff61cad6649bc00ecd934fd847905fada954dacd2758d868' }
  'win32/fi'    { $checksum = '6007b115819c0ff28aad5d6238d1d0ab5cd84387c596b8c9a2b154351f8524f6' }
  'win32/fr'    { $checksum = '37573c23a6f33e94c3f96fc67e54e8eb62560e5ac8e6400919ea20ee754453e0' }
  'win32/fy-NL' { $checksum = '26bb98c4cb2c8b6390ac7ee7eeea994d12a77569d740b0a75b0e29417d75dffd' }
  'win32/ga-IE' { $checksum = 'e274a778c2f6d4f99bb8fe01dde4f977dcddbfe4414a9d8587da6dc149d7ccc1' }
  'win32/gd'    { $checksum = 'cbb8a2ff4444fdbea4eafcde6919277069df52ddc79f1c20486308169982ea60' }
  'win32/gl'    { $checksum = 'b846f58e9ae438973b512d5465f70b4f4ff6e43b507c5c634e0c224fe8ae8ffe' }
  'win32/he'    { $checksum = '7938d8902827838d98a01a0bb7323a8f6d02dc40561c94338ab98eec6f2399c1' }
  'win32/hr'    { $checksum = '89f8dd278ca3f0e5533fb06cd3e9a525bfa815936776e6d902af4482b26ab78d' }
  'win32/hsb'   { $checksum = '685d55450ac698b6ca67dc863cee51ea8b3325d775d6890404e8ab9111ee76b2' }
  'win32/hu'    { $checksum = '190bf24b38b6b18637c73df6f4721c48776a09a90c36c75b7657841f1f34604e' }
  'win32/hy-AM' { $checksum = '0b087778b324eb85d7f06db597c63c4eb1122ec9a3ffbb81ce74a12c50da3876' }
  'win32/id'    { $checksum = 'ff09bd2a09994b6f1c782615249275e337afdd6fec056d6c64f5b9a1891a32ce' }
  'win32/is'    { $checksum = '01e825379af546b3de0038f0ba7ed68703532b665de3d12199e451a655d334fb' }
  'win32/it'    { $checksum = '1f51a4909eebb8f1ea3580e6b42ba6ab0cc2e64f82bf53f6ea39943e522478d3' }
  'win32/ja'    { $checksum = 'd0e19a9cc15964a43214571f0c302f11a0bd672d8671b11790d23fb4eca7e5ec' }
  'win32/ka'    { $checksum = '658c645c917bb501200b85af9445e616a8837fd642e92f0118ae5aaa3c1c2b48' }
  'win32/kab'   { $checksum = '0da98ed2e63ac4db341a82e9a8d842c125092fbad20d83d49e7feb3eb15e1d9e' }
  'win32/kk'    { $checksum = 'bfb6ab7d1aabb4e21feb8bcb909ebe18b01f8ec1b00977a1851264d6ca152dbe' }
  'win32/ko'    { $checksum = '68ab200434b55576aa59ed5a5c3e8965a8d9df28611259b0115a323ca2201231' }
  'win32/lt'    { $checksum = 'f3cfed9fad662006db4ace7d7ebf06fddcb25bb56b01561f89b51dc9a83d194d' }
  'win32/lv'    { $checksum = 'bb67639ca9318c874a9917280da4c807024c5f5845a3448fa64d5ab8797bbd36' }
  'win32/ms'    { $checksum = 'a94bc3327d86a729cd70a183dcb220139d60756f0b766e9df9068e76f5096627' }
  'win32/nb-NO' { $checksum = '466e5936614e8ac55f3f92dbeab387507f8102b6e65d3b964b3bec3a571ea70c' }
  'win32/nl'    { $checksum = 'd1929261fbfffcaae003638122b46da3462af0f2c25ba378ec117bd19335f880' }
  'win32/nn-NO' { $checksum = '4c6d6d3f5ac398e81d1369a48b548755e2a7e6f906fba06d6caea1eed6cc1d9c' }
  'win32/pa-IN' { $checksum = '9caac2c2f065525489e7b8789827e66ff18d106acfc3768f56c7020bb4991e57' }
  'win32/pl'    { $checksum = 'db54539e8696423b2cceb407930931ba50af1ebbd05d891c403558b0ae274c6d' }
  'win32/pt-BR' { $checksum = 'ffc3dc3a725844cb7c52e316a9b3451ca015b2dbc7ada8e304d64f0f0dd47ba3' }
  'win32/pt-PT' { $checksum = '473318b6c20e9540dec87562f2a59676ecf52a7e9010536e53a17008a6e6c2b4' }
  'win32/rm'    { $checksum = 'a1b5e8fbf935c6ffb373eec2db615143022dcb143d0d17fe6745e3cbe3d9862b' }
  'win32/ro'    { $checksum = '80a1136c15795d9f92fe41df3bac163c9383707ca56b3bf76af37c1c4d741fe8' }
  'win32/ru'    { $checksum = '22bed3744bbd46a6f141deab582807f403fc56c4ecaf98597d2ba41e18f20d7d' }
  'win32/sk'    { $checksum = '1d9384cf93bf1ef9aacbd57e94b288bd6b0890836a389e1b2f482760d8218232' }
  'win32/sl'    { $checksum = 'ecfc11a394a23e237ac41d8bc30851484ebab760924892621aecbf33699dec1f' }
  'win32/sq'    { $checksum = '89fcd940d7f96a3e0b869373deed9a9dc58a9b591f3721ec16b3d2fb454898a1' }
  'win32/sr'    { $checksum = '0bcd595902e765a776c9693e4c869d6d0a8290f2585c86f116945ae486b3333a' }
  'win32/sv-SE' { $checksum = '8374a9079873e6de8f7d67d6132f36666739e217e635de8aae2b7529e200dd94' }
  'win32/th'    { $checksum = '7dd54cd1acc2d29a3bc58b5518df4529d47c0394abc82d7b22c1a90a441f3887' }
  'win32/tr'    { $checksum = 'f4a8c8023a49da78533b82afa7516e50c43c69d5479ecc201c26a50159003cd1' }
  'win32/uk'    { $checksum = '9506b2530c063e84eebc2ef8047effbd8f0ee19dd336485862eb7ea60e7944d4' }
  'win32/uz'    { $checksum = 'e6771d49db7a7f1379ddfd85ae0915fa311997664380ddb9ecfb8a79f51652c7' }
  'win32/vi'    { $checksum = '621593b33de4b8a5aba9e755ca1f2597942c83b958552e0da6ea9a6e576ec908' }
  'win32/zh-CN' { $checksum = 'facdc31ddc671f44c40e46ed536754a5624a331fe2c0597f39e7db4024b46704' }
  'win32/zh-TW' { $checksum = '439f7a6e3743240b9ba042556dda8e6e6b5fda74c29588ae95eede561794b284' }
  'win64/af'    { $checksum = '2a0d979019bb2add0253e3ec85554d110d29b7ea96d989e6eedd2011b051657b' }
  'win64/ar'    { $checksum = '7f439da42796864f473ed96c9950a2bba7160564b425acabf6c4f21ea89d48f9' }
  'win64/ast'   { $checksum = '22237b8cd412ec6b4f9ffb3a703b58045a65ca99294f89525dad13d785a520b1' }
  'win64/be'    { $checksum = '0586af8768cda019619a7a61b6d2dbfec678c5e32544cb4478e0b003f37f3d82' }
  'win64/bg'    { $checksum = '5e83b81ffb5ff0978fa667c3acb4388a7eb0c4755bf860b6531a98a106f657ad' }
  'win64/br'    { $checksum = '2024489be7db6925f6295cb01820e4bfea1eb9ce636016022cccb3315d403785' }
  'win64/ca'    { $checksum = 'f8c0354e091d64f837fa88b48e87c86cf70be64773cc8ab246c1c8b967174544' }
  'win64/cak'   { $checksum = '03cf7e2de7ac17e802e1bdaf447a732488e498d4e905d3659afdd48030130933' }
  'win64/cs'    { $checksum = 'b11c9486a4b156e86708226f8feee5314a0cd7713310638a5ec759f31735288c' }
  'win64/cy'    { $checksum = '6a05908c7478c3677e1c85a34aad2f448b44787e6f9e73e463dbd26c24c82dd6' }
  'win64/da'    { $checksum = '17df96241f30a64cb45fc66f001996b3d3bcd6e4406a749ebbdae17579fa8a8b' }
  'win64/de'    { $checksum = '339220347df5ec85ea8375df0ab11b688d8d753c661aaa712ec7ff7e090bf54e' }
  'win64/dsb'   { $checksum = 'ceb6afada47b13e4e996a61b94fc0b0c9492396259f8ceebcf72618fd70478fd' }
  'win64/el'    { $checksum = 'fbbe85026db72f091c738dc53a48e61184c825a64f3a8af8498c10c73d1d9fcf' }
  'win64/en-CA' { $checksum = '4dfe44e54ccf62bbbe5f8a12f52f1047e43753d99d0a26838554b28173ebcdab' }
  'win64/en-GB' { $checksum = 'fdf19f54869796474bf217c1c5b1db71674c9d6c7e05f90731cb8accf78251b1' }
  'win64/en-US' { $checksum = 'a72e12bcf225bfdea31f2b967bfd725cba3e4470a045f5c5413ea8cf80d791cd' }
  'win64/es-AR' { $checksum = '15c6976703209005dfe125b63e1ccc5a8038ba3fcabb5c6ed9e96b85789b2547' }
  'win64/es-ES' { $checksum = '62061c4fcb05b45a89059cb581485ea38877cce5b6c5cf8fd6c9b768654cdf5d' }
  'win64/es-MX' { $checksum = '630cb5a3f3c2685e5274a76d638d51f52692a950d6d058304b65fdd473d42d1a' }
  'win64/et'    { $checksum = 'da6efb76c0a8589f812dcfa66f407f8b1723dbfec967013b8972a0a3ccce3025' }
  'win64/eu'    { $checksum = '153768820dee7d522c9b61fca3de84d4c7596b7244dff32c691b8dab0323a469' }
  'win64/fi'    { $checksum = 'eef26a2fef5d128847a3d87ea1883f78019b64c165e51d5befe8e2da8fcbd845' }
  'win64/fr'    { $checksum = '4d9752c66fddb66415700b2e3d36996f1bd350d6bb02c40e11ffc9e545d7dadd' }
  'win64/fy-NL' { $checksum = '36aa6f1ca41ff707e4cead8fe2bb9ff2a78ed0ae257b07c5eae26f91ff9ff743' }
  'win64/ga-IE' { $checksum = 'b75dc8867481406246d0ac4a25f9d0992488b5a31ced048fdf58e9e394d7725c' }
  'win64/gd'    { $checksum = '06a0a7f02313779ba356f443f5f017d7910b340c50de6aca6338cdc9315a966d' }
  'win64/gl'    { $checksum = '2c3e3ae28407050871e0c327d65f011faa3c0f4eb46cb5c6cf884deb0029d065' }
  'win64/he'    { $checksum = '98ca569ba9607b1f3d75302a67e243fb18014000e0601b080fecfd81113a7ef3' }
  'win64/hr'    { $checksum = 'afa67a609ae411c9892db0b45c3a697e2e766fdf90c13828168a5c9e09cd3840' }
  'win64/hsb'   { $checksum = '7f4d38bf8658f5872632d363d2b42f4f81ba40da050379f4d2101ddd3a7d6f3e' }
  'win64/hu'    { $checksum = '5d7bf63063963a7621e515896669c6788523d8e0217fa1ea623330fdaddc0fda' }
  'win64/hy-AM' { $checksum = '2b657239df7def690cafa99bd2b985388b0a247b6dadd4d56661f19d03db0775' }
  'win64/id'    { $checksum = '23e98234ff464c064e99b7c53ce3438b980e241e33b159816506cfe9b003f6e0' }
  'win64/is'    { $checksum = 'ae0065afb9796bd69778a6408aaa6105fa425c429ff1fab684610e278700cdd7' }
  'win64/it'    { $checksum = '0bbe94ed9ffdc33bdab7865e1b20773262de5b58535b3a4d36bc9acafd9392ce' }
  'win64/ja'    { $checksum = 'f302109a6c97005d3e5e3a9e93b7f40e3f687efd4b223060e8dedc0e4d869143' }
  'win64/ka'    { $checksum = '0c63c9ad2d80b86faa3a5c0e42e05dd6aa0ac1a1a6cb8ce4445450dd8afff66d' }
  'win64/kab'   { $checksum = '139b5f16b872030089eaacb5addfc29f48126e1ae5e38a98eda639cfc033239b' }
  'win64/kk'    { $checksum = '12eeadae42c5ef0ce0ef628f2b3257c85ac8bab65e079e7ca387301cc4c9f8df' }
  'win64/ko'    { $checksum = '800af8be8f03e18c1ee328d73313ac3a43a152c645d3ab5f7fb2f750d3a6cd64' }
  'win64/lt'    { $checksum = '6cb7bab10e478600d781db7de52782d4e2a26ada4b93a8cb11cec150f6b7a185' }
  'win64/lv'    { $checksum = '6bcac6ef8c4ef2bcdf2ece3c75ab61bd259c2d529cd0f09685e9af0273dc57df' }
  'win64/ms'    { $checksum = '0b69097c9af9b1d3c9ba34d1b6bda8a37f74dd21adcc3e5c475d8c512b7ebe17' }
  'win64/nb-NO' { $checksum = '0aeea2580dd08ec37cee2b35c202811784b61569d5f0704d2448fadcbfebc950' }
  'win64/nl'    { $checksum = '3205f0f24a1349e6a05abb23ffc995d7bf62ff647266dbf5e78884e385071645' }
  'win64/nn-NO' { $checksum = '7e5bab9c4c77244516368fd9a23fabd4774856c6484d6ddaf253e40463dbfec4' }
  'win64/pa-IN' { $checksum = '1a7a29ebb58d6b706322c917f0fa01e42ed6f91cad7b0ad7b15f3fb66af2f773' }
  'win64/pl'    { $checksum = 'b4d21254eb5f05358944ea17d30e9edc0a6159acf28f5d75e6734ef26ccc2216' }
  'win64/pt-BR' { $checksum = '168b8ff8b624dcb77b298b52870595812e9fec9cba1845737143d18ac454114a' }
  'win64/pt-PT' { $checksum = '66f926cc172c08a97ca661d40b21e174512420f86231833eb6d58172f607e15e' }
  'win64/rm'    { $checksum = '527a7357a2403134231901b677f489faaf3e84de0d0d1a8a7c4ebe79e5783b1d' }
  'win64/ro'    { $checksum = '0e6ee494d8ec32661f669157ced1955cf042eb1eb074c9df15a2444b254564c7' }
  'win64/ru'    { $checksum = 'fdd539eefb754e4c258ea027f11774da3e5e550886857dc439e1f61c91a0df48' }
  'win64/sk'    { $checksum = 'fa0daf65f7cbe2e41c0c649d6b231afbc583044565587d860cd58f31094d0073' }
  'win64/sl'    { $checksum = '5c42334aa9971b559c935985a78cad730ec3c318b4c0d2bff4c9808fa9400726' }
  'win64/sq'    { $checksum = '0e340d7b192e4c834f57318117c1604afd89be52ada61757eb55d0aaf0c67d49' }
  'win64/sr'    { $checksum = '9957ac41821b14f007c2844f1237f0e2455544f292d14c2e7c9545d7db1748ce' }
  'win64/sv-SE' { $checksum = 'd8e6353fdacc3d2d1a2354264d1125b5bffcd14963d1969e06f8463b0af1cced' }
  'win64/th'    { $checksum = 'fb4aad637e521e0b0e55f8255967c87dd3158bf94ed39c08e64890b9724668fa' }
  'win64/tr'    { $checksum = '09f08d544e14a71cf93cbe5d9e3cdcc6731ef734b6b54368dad2520475b90078' }
  'win64/uk'    { $checksum = 'b83ba3eccb253f500cbb4b6c906067845347015c986162635c12f3af5014b64c' }
  'win64/uz'    { $checksum = '3a933deed6e084a60edd6def1b2e9850c086fcc8da8a6c65b690d9c93d97ec54' }
  'win64/vi'    { $checksum = '49009e98cc85cb29be38e2055652c56808b510532e641e7ec32e37d509d92eb0' }
  'win64/zh-CN' { $checksum = 'edaa179d150fdbd3d50bb0ec2618c486f54c98ba7abc0d25f0523b01495222eb' }
  'win64/zh-TW' { $checksum = '48997049906440dbf6bd59dd8161848edc4275b52f697c2d344b611826dd0d2b' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
