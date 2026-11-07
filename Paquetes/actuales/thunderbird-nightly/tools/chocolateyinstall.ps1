$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '162.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/11'
$build   = '2026-11-06-09-56-54'

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
  'win32/af'    { $checksum = '0fe221b672753d1d5ea4cf9a5ebb9916d85d92fc6b1f596fc6a8ff3049713389' }
  'win32/ar'    { $checksum = '73f0acefbaa38f1e123f517c3071bd64b5b6915e5347e0c92c875a9f6248e09b' }
  'win32/ast'   { $checksum = 'cb3ec5c9497727854c624808641a72c62aaecd33e6446dd3d3e8808270b9f8ce' }
  'win32/be'    { $checksum = '22be5e205ea92ef05e8d77ff79e63f5c309b004c5fcfef1f2c4d30e0c68353aa' }
  'win32/bg'    { $checksum = '29de32034cb6f4b637720d14f0b2b7ac766235169f92db5018f798eb57d98497' }
  'win32/br'    { $checksum = 'f467becdcf9297bba894c697643ab7a5394c115a766ff6cb187560ac2ea4a318' }
  'win32/ca'    { $checksum = 'acbf8f82b41bf6667e84be41417eeafed3cdcbeaf86e2abe9ef8e6c546dc76d8' }
  'win32/cak'   { $checksum = '37ca1141a4b629f71a230382c73e00a1e070e5de3396d3d4099b118a541da269' }
  'win32/cs'    { $checksum = '009fbf9b9f9363147bdbaa6cd2080abd164be2e50a94889dc71423075c7a557c' }
  'win32/cy'    { $checksum = 'dc5f428f8c1791e61fb37fe9faf79a60560f229b1cc68053257b7d693de3ed02' }
  'win32/da'    { $checksum = '1fd526671e8a454cb4e4395d4f004d5b388520d11fd22cd14c52ab2a483a185d' }
  'win32/de'    { $checksum = 'e1bc2b788d215782bf60d913cfcf24f8667337fab5a41de3fd9697e945e5d64f' }
  'win32/dsb'   { $checksum = '408844f0606661d5b586c799ea7c33dd5607ec26c79fee1b40b05a02d356b670' }
  'win32/el'    { $checksum = '37a1e8b668182144e219ea1ec9c21a322354ab918921938cd7909328c7a4cc6b' }
  'win32/en-CA' { $checksum = '62d042d4244d327d8ded7f6d7859bd26ecbb2b069875121c6a66d67f51efeeb2' }
  'win32/en-GB' { $checksum = '47bdd7424a8e10868fc7de970d7f62f0a553f269e350bb1c48d2665ae34d77cd' }
  'win32/en-US' { $checksum = 'd0ecdaf42a926a8befe9b62443cbbc0712a6e2cc416158a0b62e7bd6fcc52e8e' }
  'win32/es-AR' { $checksum = '0e952e6bd26c94f3775117b99e3f2b3f0e72220633376149aedb4623b4145bff' }
  'win32/es-ES' { $checksum = '3a79f4d27f9ed560b6f49d3158de7fdd7ece0b8804aaf697187f1ef24a3f6814' }
  'win32/es-MX' { $checksum = '1a8701fd6846837433b2dade923a62be64fa1eb3f32e9d3f05d622d5e70223db' }
  'win32/et'    { $checksum = '61e143a0a1f9048667ae9634e75c41c359c8d6c5bb5d5712b5da22db81ad290d' }
  'win32/eu'    { $checksum = '8b6d0f9d780920769f973778338575b6e9e418b28105abc12df871a9ae526c89' }
  'win32/fi'    { $checksum = 'ac199aaa8c95b0950eaac1e06964db25033c16bca5373f5d6c76242481490b0a' }
  'win32/fr'    { $checksum = '522a5c8a8ec541e8006bf08e4bd52e59b7384517741a9e4b4b1e05f4835fea69' }
  'win32/fy-NL' { $checksum = '0d0789f10ae5fcacb164cd7f5540761884aae3ab05782356dc74e5c294cdac95' }
  'win32/ga-IE' { $checksum = '1109c2f52dd49972b43d515e3719af85a762ca16f4a192facce75d9136868e41' }
  'win32/gd'    { $checksum = '455d63bdbe7ec7161bef285ed5d80136deaf7d25c5b3d25a6b241fc035893d24' }
  'win32/gl'    { $checksum = 'bd7e84511630361abdce5dfcd2cd65dd9d18fd8665c37aefc3e8ed8a73d397ce' }
  'win32/he'    { $checksum = 'c900cfb264c029d1dd527d68b036b61d7feec02dbb305b010b0fb5095cb7f5a4' }
  'win32/hr'    { $checksum = 'e30f0d2ce12874d68d74bec1b41ddbf350321dbca79b871d6c83b7a5c3740a41' }
  'win32/hsb'   { $checksum = 'c1ee6a57029f2cc2d5fe81d47e77743f5c74aadf26632fd9dd6646c23f5180bb' }
  'win32/hu'    { $checksum = 'c2f50430b887d95102e4dfb25d966b004c21503dee23462a2ff9f01d80b61847' }
  'win32/hy-AM' { $checksum = 'ed4d9d82432dd9246276b06e8c5dc85a3bb22490a75d4fefaa398de79e4e7099' }
  'win32/id'    { $checksum = '53a7b8490aea344cc67ae42ec244d765b0ff8214ac5c0120f8a0e1d3e712b7a1' }
  'win32/is'    { $checksum = '5081c08133883dbfa1f90e5cf944f5fd0bbf7c4552f700541b47295e8b3ca09f' }
  'win32/it'    { $checksum = '78cd6e86cb28c30a0f3d7c263466a37e95dfb926d4d41af183298c18a769b8a3' }
  'win32/ja'    { $checksum = '093a786aee258d4844629b98d5d66a7225f405ea83e144c69395e16de9179a1b' }
  'win32/ka'    { $checksum = 'e56e905b38d1be28d9b9fce36af7e0aec325796e8081460e061c6c7b19b75f11' }
  'win32/kab'   { $checksum = 'eb15c92734e3108fd473fffec1927b36d80992b3895aa994ae51757b4e6766f3' }
  'win32/kk'    { $checksum = '2cc56c4645ef601bf9718be77a46e953e6d0f07dd07b2336401145bfdcf584f9' }
  'win32/ko'    { $checksum = 'd633b501274a96243864a871f51338dfb63389e4d9729bfa99f16ef680321757' }
  'win32/lt'    { $checksum = '555a42d7766110cf2d117ede7a46ab02b5c84d459c0ae77dd04740ae5858fd9a' }
  'win32/lv'    { $checksum = '1fe90cd2a9c52ecc078f187e7fa9299dff369d66fce900adc07831af9921538d' }
  'win32/mk'    { $checksum = '393d89afca67e917f640869bd5a6f51de5abadeea1082bbc07e8604fadff7180' }
  'win32/ms'    { $checksum = 'd4125e12e0d22e6ea4f834bdf760db2e303d3f92291e9aa22c862aa774c98c00' }
  'win32/nb-NO' { $checksum = '935826a053f1ad1fdf9cc9eefb4d20fa1423aaa8d7677ea83b5515d02c5c179c' }
  'win32/nl'    { $checksum = '70506fccc510c34b1e9d77f41376e36b62b668d2c0cc4b869ac14529dd186b00' }
  'win32/nn-NO' { $checksum = 'bcbbfe6221ee7e255fd72ecaeb473e8ddb8063a483544d92a5044952f1504b05' }
  'win32/pa-IN' { $checksum = '9d9c5caf71362ff506d165f3e4cacb33b98d86b82cd4edbc38a247200abd0d37' }
  'win32/pl'    { $checksum = '8aefd47d6678825e2fa691f39ad11d56ecac5c9a522010772b898d231833e347' }
  'win32/pt-BR' { $checksum = '33d82f9f05a35cd46bf47671924812123919d1901e23750691f242fe58e63d02' }
  'win32/pt-PT' { $checksum = '6b3305d0de90002f3c7df5ea8276eb7a7c7aab2f394e372d8b5ab544cb80f159' }
  'win32/rm'    { $checksum = 'ac80b2d785180b400aab5842898ae0bfa9647ddd383c0d3816c979f3e1044a81' }
  'win32/ro'    { $checksum = '392387254c9655545fbf4bd5a5324ba357cacf515600820e5dfec3f6a12280ba' }
  'win32/ru'    { $checksum = 'f11145c3bd8b197196111099ccd6c1c541834b5289a27fb750f64aaf83340c7d' }
  'win32/sk'    { $checksum = '9b8dc80f58af6136e117cb4304f577a0077bbe4393ab2df988c9d5836cc04b7b' }
  'win32/sl'    { $checksum = '6357e0c4dbed3384dd68349affbfd6446af0fcca2a4ac2df4b10c106dacf6590' }
  'win32/sq'    { $checksum = 'c2f6c3ca09bad7ae028d5ffe1c4469b910d22a05687b57a27ccd061513a150d4' }
  'win32/sr'    { $checksum = '8efebf6d5f45f4887e6d3e697f125b22ec59451d62b8ce65d279d7e5aec24152' }
  'win32/sv-SE' { $checksum = '167bf198ebff4c235572866768e3847398f0ee3da945cfd5aaecc5344007d8db' }
  'win32/th'    { $checksum = '05e1a34716e07e6c109a0b28d0c98cf09a9c741f78a175a09723fb72fe5b1063' }
  'win32/tr'    { $checksum = '3fbe5f842b5b88f638c867844693696cb0d9356eeb97c2755bea140573727a4a' }
  'win32/uk'    { $checksum = '114f6ab99b9d7107af735f78947d3ed0649c4252608ddcbe328f8ee28be8f6ef' }
  'win32/uz'    { $checksum = '2031637081185b5564b6ace9471bc914ee082ba323043fd5780ab5649bd31271' }
  'win32/vi'    { $checksum = '5f3b2327d417f12993a63c7791f849c2319f7f5b2f552a5c7a0d5a83d4751eb5' }
  'win32/zh-CN' { $checksum = '41eafb280e9c8514120231cfe1ab4838a37d5126b8374e08a3ebfa92cdffdd4d' }
  'win32/zh-TW' { $checksum = '77a4ce4621c1fecb29e51b1884811016cc418ae92bc60ff76fc0651af086ac29' }
  'win64/af'    { $checksum = 'd9ce3844e413c30a46be742b00ecfeb3fe7679c272e6f7880d47db81ae865478' }
  'win64/ar'    { $checksum = '49c7705bea6a38635ba24addc0366166656264e2c3ac3d294e564c3ad43fa693' }
  'win64/ast'   { $checksum = '9fee4ef36cc348f774cc8eb08cf078bd8b48486dd9b35541ee4399e55737c67a' }
  'win64/be'    { $checksum = 'a2faa1f4c16bbd16cbe52a7d8910106bd16d00992905eebe15e2af08a9616e5a' }
  'win64/bg'    { $checksum = '1647bb570ad0197c6d2bfa9112fb9a868e1258e05aabb922bbefa811056249ba' }
  'win64/br'    { $checksum = '4eb8ae225e7544b0db7b8e94c9d566dcc87e12a536b4e1f3cacaa3b92dbaef38' }
  'win64/ca'    { $checksum = '62d56fe95e5884db584aca35f94371f0187b7829e4da62d433084ccd47bab305' }
  'win64/cak'   { $checksum = 'e499a2a6427ecb87857368b6999fd9a18c660f80189185a2da9aa2afbf71c68a' }
  'win64/cs'    { $checksum = 'aa28c87d94f864965796e13048ff2d2990ce48ddcc5b898eb87e0697bc0ac41f' }
  'win64/cy'    { $checksum = 'adf712b31f692d532e33fc07a5b3efd84de5cec8c7e8f2ef19ad3c6ad0db5ccc' }
  'win64/da'    { $checksum = 'bb3a79e52bdd7cea1574f427f3e6ba27d2ee8969ef73b1672323cb798e7dab43' }
  'win64/de'    { $checksum = '2a186d72a041234a38410f40c842eeddf74e41a60a49401fdce3a8a3f56fe331' }
  'win64/dsb'   { $checksum = '140a899dc2b94f3364cb4b62bc362961f3f16d75714ad26edddbb74eeb268dc6' }
  'win64/el'    { $checksum = 'c3902450411946c4dfa242ee2c8cbfe53e430b95c93ad2fcc7c1cc69f9e778cd' }
  'win64/en-CA' { $checksum = 'c0566fd0e977790d6ded04475f37dddd498a48a8f26d6b7c4adff60be164f868' }
  'win64/en-GB' { $checksum = '8aa43c5e011594d6dd947307bde92ef36c4ead875ef2f3f03d440b141e4d7cf2' }
  'win64/en-US' { $checksum = 'f8d756b4d7b25e1dcd7a99ec26a449a6cc071d06602bff2686f19ff295ec4d8d' }
  'win64/es-AR' { $checksum = 'aad4382158170c1db8275f9d9c60d98f70080433e464919a12cefa687d27c347' }
  'win64/es-ES' { $checksum = '19cc924bdfa055ea625c3291d44309462c441d45a9954b5263fab7807b490aed' }
  'win64/es-MX' { $checksum = '80b5972e859cff0356fcea02ebd3e88662cbfe834da1dc7dfaeeb0d7b0f6a5ba' }
  'win64/et'    { $checksum = 'e261579dded8aae10560be883b67a7c58c62b7cc766a38827f788a00b7a66f89' }
  'win64/eu'    { $checksum = 'cd97991f11e919b2b93f60b47f9295f23c00f7a818ccc4ff0550c974da1434fd' }
  'win64/fi'    { $checksum = 'be25ab578aa4f6652b68b2e51219160d0b279610a2edce26278fade321ff7516' }
  'win64/fr'    { $checksum = '37d6bee629b3bea2183878166b85cee418310ffb6cf88e56393a2eb9daa13405' }
  'win64/fy-NL' { $checksum = '3a26e15a85c17f7368bf0af1116131483aa6ecfce71141fc21b04574bba102f5' }
  'win64/ga-IE' { $checksum = '78866707981e87ad1a2808830fbcee0e0967e866e930121b46e868ecd5e43173' }
  'win64/gd'    { $checksum = '71790ae63c8b52e1c0877b6be01134aaf997e2c664c81cfdb5ce25e9a1a4a021' }
  'win64/gl'    { $checksum = 'fc68e2ab34fec4144a6cc407f67e82ba3ef29ef81cb5bc62318557d087010262' }
  'win64/he'    { $checksum = '04073fa084e044b64b9cbda7c0acfc9b8995ba536c5469ca53da587882d6fdf3' }
  'win64/hr'    { $checksum = 'ab656d7013c9f285726d2d581521aac71ee0f6b8e6251b179ccf40832fe4ce66' }
  'win64/hsb'   { $checksum = 'b77ec663c498a051374e10067978249e098e22f0bc3b218c1a6f3a7861629354' }
  'win64/hu'    { $checksum = 'fe766e28a762ca6f7dc489828eace095a49667d5284f1971b5e64d0e10fff904' }
  'win64/hy-AM' { $checksum = 'f3193811cdef17ce50db4a121d56a79c9b27ab60b5830a490a0c328fe8a11b77' }
  'win64/id'    { $checksum = '6d03048636b7321ba3a5b869c96b00039c4e7143d965b31422103bcac0a0ab12' }
  'win64/is'    { $checksum = '05a06579a66f762b3837cd4cc9375e03da1ec541628e4f86a716893f4c44588f' }
  'win64/it'    { $checksum = 'ca5dfdb8d71fa91d488bfe65b539b40ae77e7300580f7df30143f72131ecbf43' }
  'win64/ja'    { $checksum = '89bd4b8474bc906ede400c1b497f156e382ac6c8a3648001a8d0d9f0ce7c0555' }
  'win64/ka'    { $checksum = '0a303083258d9cf22a71a0ce71c5193f177a95059493e87819771547b51faf1a' }
  'win64/kab'   { $checksum = '16245412544e1d4b7eabdae888f90d1786a8eeacd99bd5d519e5a1520ebfae65' }
  'win64/kk'    { $checksum = 'ce8a2b71f219fd75eb8d5fa400ac24e5686110902422ba98d07a5373de21f182' }
  'win64/ko'    { $checksum = '8d34929bfbd9372968755ddb75c80779de830a6ce42df11e3a65db3944709cce' }
  'win64/lt'    { $checksum = 'fce8c59487622585fc137458cf03f60d729524fcabaacc2af5f069074cb0b788' }
  'win64/lv'    { $checksum = '10a8a91872b36e67a2b6e0bc63693fe3281967ba13d62476e9ed2ae085ee7330' }
  'win64/mk'    { $checksum = '552bffec7de1e0ff921694a5be8dbcc0ff83bbbd1a7a48a50afb141044bad3d3' }
  'win64/ms'    { $checksum = '515515f1ef65f772a069e9ce9b0c1dd13f78c7c587837c8c9c1faefec99aaae3' }
  'win64/nb-NO' { $checksum = 'd0f3b814a758116a27f1db5192eb3a6b1c21fe1229c61654d1b1f191a8bf88a7' }
  'win64/nl'    { $checksum = '980b4c1310f69b8534316896d549b22d4fc0c0c3c630343e7469d6bd76345122' }
  'win64/nn-NO' { $checksum = '931408e8f2c5e322f8e2f33e72e6881fdca3e77ef137f152e4775de1a41e478d' }
  'win64/pa-IN' { $checksum = '667204cc674f3cd07855f6d41dbc8a372c566e97aa9b16129cc0254ab6829e17' }
  'win64/pl'    { $checksum = 'dae79bea81db751fb83c41f3f97cc61ae28843a5e2c697f401798a40e851bba4' }
  'win64/pt-BR' { $checksum = '88e0bdab6f698470f3357843ed6ba42ad84b594a3b4cc523ecf8b6295a4f6a98' }
  'win64/pt-PT' { $checksum = 'c1988eb48a7dc985a925e59f7255a83dd8c5a13ea4ddfec54aeb42d8d6689985' }
  'win64/rm'    { $checksum = '9868cb4f13fd727f2854d2220c1495f0b0296b667c33d915b13e070e587b1a0a' }
  'win64/ro'    { $checksum = 'adb3c036b2eae843c438e93f102f33889cd6905a7e8efba60dca971b684f3aac' }
  'win64/ru'    { $checksum = 'fe1ae8868945ff12020ba5cc879c5c78eb8c811ed2f8eeb6983dcba490bd682f' }
  'win64/sk'    { $checksum = 'a3bb8c54944f6eb197f1e6890d25b7553502339165115e6d7266322bc67e7e26' }
  'win64/sl'    { $checksum = '0af39864f66da1b3fae21db93660e04173bfd534d6c292650a79b0b480e8d09b' }
  'win64/sq'    { $checksum = 'b716295ff8667622d61c2b36906a4daaccfa02a44b0cbb143ea17e916096f8f5' }
  'win64/sr'    { $checksum = 'afc5aaafc76ec114489382c0f82ef8955c61ee3de0996553c07aaa52d004e5fd' }
  'win64/sv-SE' { $checksum = '8045caeb0b11653c5994ae942c21c4a7369527e6b20ebc6c51a4545436b35cfe' }
  'win64/th'    { $checksum = 'ba041206b71faef522dd5dfcb102fab81e7c1c2d454b0efed3d8064bd48cf128' }
  'win64/tr'    { $checksum = 'fd936cca5a9ff47fdfa65e386bf023464af5f89f1fb32781e0658ac381a2f1f9' }
  'win64/uk'    { $checksum = '6962f4b7c27046a1edad526b1136f049bea9690a1378f945636c66dc12371faa' }
  'win64/uz'    { $checksum = 'b9a01773062b7404462f9ce37ef98c361bcf18c141e2893576a19402708d1851' }
  'win64/vi'    { $checksum = '5a1f97a841ba4939fa37f247dacfbe357a874b6a401623a1dddc84c96cc596af' }
  'win64/zh-CN' { $checksum = '77e87400cfecdc21e1a6c78ecb40fa24e302976d38f4adea8425ca9075a88276' }
  'win64/zh-TW' { $checksum = '35706f711657c17597e470617f327610c0fcf689c4127aa5b5215d1448274ba0' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
