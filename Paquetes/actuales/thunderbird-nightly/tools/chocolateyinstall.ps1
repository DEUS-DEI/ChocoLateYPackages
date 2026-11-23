$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '163.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/11'
$build   = '2026-11-23-09-18-59'

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
  'win32/af'    { $checksum = 'a11871d3a4849c19f0c205d45f16e0ae6d0a355a7bcd0067b6db8449598c6208' }
  'win32/ar'    { $checksum = 'e6ca8ab0f0d896d539540907ca60c2a3f0cc111d0906d917512167c82f5b09ae' }
  'win32/ast'   { $checksum = '3ac7dbe65afa43588c3af0b9b7bfa3d6e291ba28216eb40b49555ead11723bc3' }
  'win32/be'    { $checksum = '809e3a1f57d75f12b2a0da32947aee1d0faef22b90885e53f1edb9e9127eee0a' }
  'win32/bg'    { $checksum = '7f633a547f2d0f5db3f56f6e493c43d0bb96c0575793cb7d38cab420212cf473' }
  'win32/br'    { $checksum = '92587b6053e3310ec241cbaf84d56dd0beaa4e81213125d63fa34b5112fb4985' }
  'win32/ca'    { $checksum = 'a2d30897abc314c52f7845b488f9a6d76e12fcddc871ae7f7abef30f5d3c9c7d' }
  'win32/cak'   { $checksum = 'fe5d1d9e05785bce146134c51f08eea69a1daebd94c71bf58f1fbf877c1eb834' }
  'win32/cs'    { $checksum = '0b7bbfff6571782802af4534cc7ca69757e563ad9177986d25c5ba1ab0b64fc1' }
  'win32/cy'    { $checksum = 'eb8b8daf73ff0c15d0070fe8c1d559e49ef4ca40180c8c5cedbe7822329027fc' }
  'win32/da'    { $checksum = '04e726a540406ab0932c704f8df7dd9de3d0f058709d48a70d3ee031cb179dc6' }
  'win32/de'    { $checksum = '0b5af76f0eb69962a39b2d2e296c961fa4e77406f2511d1d43fa4c1900454b95' }
  'win32/dsb'   { $checksum = '197931cb05875e5580efbe79f46f833c492742035defadcb29bb6b0b1cf9ac63' }
  'win32/el'    { $checksum = 'e5d5d39abb8fe37846ee360fc28459c4d5b601f1ad0bf0dfc84d2df7d00a21fc' }
  'win32/en-CA' { $checksum = '2f9423965bf8a31fa3a5bcd93004ec75ab0296eb88156f409cb9dde41dbc87a8' }
  'win32/en-GB' { $checksum = '8743e969385b6060ad3fd0f5468ef57cc13a4a63756636bfba754988a3abcaa2' }
  'win32/en-US' { $checksum = 'e104ab10ae2e44cbcc90b81e7c9ada33064ca156f24bc80a66a614febbc0d493' }
  'win32/es-AR' { $checksum = 'aa4847492e97492c54524ca789efaeaab7a7c0d14c3f4303c3eaddaee7bb5911' }
  'win32/es-ES' { $checksum = '613c3ff586841d50347f34590ba4fd689a138eddc888c2a4e589d3d9005316b9' }
  'win32/es-MX' { $checksum = '4206164d34481560f1894a24a7086b88cfc2a19d0c493214c2218e549558c45c' }
  'win32/et'    { $checksum = 'fbcfa034052042b9a2a968234130f4ff5215d68440257bb8abe78207750e40fd' }
  'win32/eu'    { $checksum = '47969ef45a9c12e85e4137e9c1ca7d2ac206938768c33dcae2947bf1df96876f' }
  'win32/fi'    { $checksum = '5a1a5653af152d3dff83e1d50e09b6f7cdfb6d8539be08593f32c11959bf00f0' }
  'win32/fr'    { $checksum = '9dafcd615bdbe49b5d159ec2be8d1ffc36222ccc23ef9b6f945d21f05abb274d' }
  'win32/fy-NL' { $checksum = '7bb97b9ce7fd889b3af905ac30b4faf74d8faca82435a495df2535afaa4467a2' }
  'win32/ga-IE' { $checksum = 'c9ea9224cf8e1efd7286f0d0a09a584fa4efb20ac98e6447cd8b979147ad7243' }
  'win32/gd'    { $checksum = '37f195540956c9c4f1b2270cd803c63e31949967ee6fe054c886178b87f76d34' }
  'win32/gl'    { $checksum = '2e084f99113327ca0ca07cf65c41a2122187235fd0f55509594d07b8e125948f' }
  'win32/he'    { $checksum = '425a7f59c27555812a6dd3d6d36dc203d28609030a98c6af9a4f9608854c8224' }
  'win32/hr'    { $checksum = '5ff4c619c5f10a9485ef7a4e0c5e58d110b654cd890bf08cc64919acbbea73e2' }
  'win32/hsb'   { $checksum = '2e07c61fc50d50c1bb71e30e026d06e2e301d2c3910418a719b43569a857b08d' }
  'win32/hu'    { $checksum = '849bb80afec4e1021beb249b892d28baf897a22173bed28a746b797e64c2c4ca' }
  'win32/hy-AM' { $checksum = '1b8a9143e1b44d1daf11f90776da7167836e0dfd8dcad51a001ac69397597355' }
  'win32/id'    { $checksum = '8567784266213b6b9afca1430444c19b142c5a6c97462b39a5a837305bea5712' }
  'win32/is'    { $checksum = 'a4d06ff1799f2557c8269a02d03df2768b86acc4370ed2d8694881af10be661a' }
  'win32/it'    { $checksum = 'd342d5fea009b7a499eab9812c2612cd5d96df91579a671b4af1c00b1626a67a' }
  'win32/ja'    { $checksum = '4f851f992d7eb16369f58674b10a9fbc95a369728e0c7d6191235212859f7ff0' }
  'win32/ka'    { $checksum = '3fd2a6ab442be244ab7ef86ef9a84b6dacaf45045118adeb58be42c88d87e644' }
  'win32/kab'   { $checksum = '7ccdf31868fa444dd23e6ede6a9bbf93ace8468fe690856e18d3912370fd7e91' }
  'win32/kk'    { $checksum = '2fb603f4fa8af8f40733681f47fab5c976802086b907267bbc6e9d1f5e40a432' }
  'win32/ko'    { $checksum = 'f9abf91d5cd6a77f2a4e0bf7332ed44e4cf357b8656e4cedfdbf4d4bec339a5f' }
  'win32/lt'    { $checksum = '3d363f6a0f2438a7d631641d07f2457cdfb2cebcb0bcb01dbf5bd3fdcab41aa5' }
  'win32/lv'    { $checksum = 'd37206d298b707f43493438c5945a0938d2cb9364cbc9d65a87dc3a1425abd60' }
  'win32/mk'    { $checksum = '434ae99c91ec80320d1787ffd7be3d0f37a8b64b3dec47046baad2fce147a4f5' }
  'win32/ms'    { $checksum = '1137b6eae4450f2de6ecf12b40308fbaa06c78b5521aba804bdc365e8034d832' }
  'win32/nb-NO' { $checksum = '1ece0f40e4c3457a2ccd5de630c964371e101991cc3491ef3be9b79225de77fc' }
  'win32/nl'    { $checksum = '727d8155f97817eacb83462d29617d550f370ad96adf0ee92442a73e54d84475' }
  'win32/nn-NO' { $checksum = '442b4cadc4a9f057765dae34a307d4eb48a1b125310433a67d088ff0fb990d29' }
  'win32/pa-IN' { $checksum = '2d9571065d21b684a6e98a8a2bd90104ee2165d135e02910cbcb357034627819' }
  'win32/pl'    { $checksum = '1962a25bcedd3bcedbe56088150ff6eff6ca0cce23198ca064a51d38553323ea' }
  'win32/pt-BR' { $checksum = '442a03c5c266881dc908a9e5c363be80e0f7a96a39d7c1e4ff734502118d7f86' }
  'win32/pt-PT' { $checksum = 'ac776dfb826004c54c0208d60aef2ff9d2cc4221ccf573b5a278cc493f8ace64' }
  'win32/rm'    { $checksum = 'a3495ab3ce82c64d4ccd4bbc25fec799a581ef5afbd4f5262371fc675c01133e' }
  'win32/ro'    { $checksum = 'bd0dcdca19c8fd03699535f28670f14d8618f4f3114af6b6b0f7672e25d98e09' }
  'win32/ru'    { $checksum = '554644100e11cc10f5b0a71c7a96231ce0b2aa2d9c0abf62a50468339cfc043b' }
  'win32/sk'    { $checksum = 'fb340a3ffe6ba9d3db40d0295e639bd24763ba1361fb9305b5336d904a40652f' }
  'win32/sl'    { $checksum = '8f5f5b1bfd46e585551d4538e1ebbf636fdbc73fb043532afddc3e4ec848d58c' }
  'win32/sq'    { $checksum = '1b1c42238488221425c6695d35f060a41f5ba7d874b656fbe289d63f1c3a6b15' }
  'win32/sr'    { $checksum = 'efb1d346d3c4b99fb2485ea855f27f17dada4cc0bc750336a48677d18a4f2906' }
  'win32/sv-SE' { $checksum = '9787bb67ebcbc7a80d6c9fb4534ae809bc7064a553e218e0690eff1d0a41cf94' }
  'win32/th'    { $checksum = 'd0acaa90285cabc9f50413c190c32052e672af19442b3903c70e4a205d42de13' }
  'win32/tr'    { $checksum = '469668859311d0c06e75f586b8c104a31e6ac055f577b885502f515b21602300' }
  'win32/uk'    { $checksum = 'b6707ae5b78ec2cb259aef83d3f805773848923a74ff00897dfd7596f65808fd' }
  'win32/uz'    { $checksum = 'deb600fa55eb3a2909f65fe1431a3cc70a70fb140038874d7e0ebc2cdd800f51' }
  'win32/vi'    { $checksum = 'bc30a0de26eabb660e1e413851f5f57f8633a1c489aaf1a026838ead354b4c7a' }
  'win32/zh-CN' { $checksum = 'b5dd01df5f64feaa8b001d5bc52bb69ea06593faedd4c71c887ef8fc8c087017' }
  'win32/zh-TW' { $checksum = 'd44df1a38ef6bfec329948110b5e597da426e3797576aabe60c6dfc974608249' }
  'win64/af'    { $checksum = 'c983dc32fff9dea0b1251c19670e69cdab71054171e33493d271826845b39421' }
  'win64/ar'    { $checksum = 'bf1d5a4febb79669efb7a5e87e7c1d8b2f1179c9c4a0f981c095e428fc60d2f7' }
  'win64/ast'   { $checksum = 'e11884a29db1237b17b46d8c92f5f96eed9ca03f1fc4ffc39de442e8a7f487e5' }
  'win64/be'    { $checksum = '49a63629995a4bd5596ea127ffe5768dc568e64b9c9fbd6bbcd325c1a028aca5' }
  'win64/bg'    { $checksum = '83d4091bbe728634dd382e7a3cce168a89f520633c10fcae917d8e42ffb0929f' }
  'win64/br'    { $checksum = '1ae314f2fdd7dddb78972bfea7de8f85687fc88330e7b141960c3adcf63961db' }
  'win64/ca'    { $checksum = '6f22b3175928fe2cfdd0cdf557f59d933213de5e65bf0e789a1f987470ebc1f6' }
  'win64/cak'   { $checksum = '979e703d0996f2688c2c71e932a82b5b624748037ad2e39a93d7633144fc75c3' }
  'win64/cs'    { $checksum = '42ea0ad3ef7aea2163af7221fb333414ce03f5d0d60de4e9196b1de2481bad3f' }
  'win64/cy'    { $checksum = '9fda37ee6c527c0ac5acb13fdc996ae06b29e228cd6c12804b87636122ac71d6' }
  'win64/da'    { $checksum = '1e2330e256f0bf1c65a6e519e2a02d52982c8adeb6373fb65845c7866dfba521' }
  'win64/de'    { $checksum = '3c6470cb0eee07dd7384d7b0f2d13fcbc282ed480adadbd8bf0669cdf8a48da1' }
  'win64/dsb'   { $checksum = 'b27333016bdef2d8a4001d7c5a986ae3c26e9b61e1d0d2ccc88ff053faf5e781' }
  'win64/el'    { $checksum = '24e43c0c82a81e76acbfb13bd1c7d5913c68f917bd2e49148247dd612fd13f62' }
  'win64/en-CA' { $checksum = 'd65e728dca3a2a6cefccc7a81394da9bb800a3631bd63416ac56308f309887a8' }
  'win64/en-GB' { $checksum = 'b6e2808fbd2fdb7f155e846fdf0e8f9549dc3c6b2a0c5545bf054000743a484e' }
  'win64/en-US' { $checksum = '931f8a816c39dec35a8d7c487719fc4eb21887377ac3783ba9a9866eecacd5a5' }
  'win64/es-AR' { $checksum = '340bf1e57067c79f22931568eda0bafbbca92324eb9e25c0a81e69c2cb6869b7' }
  'win64/es-ES' { $checksum = 'cc1d213c6714e81092aecad6be46559c47b002e2499da5716a5d494bb2533518' }
  'win64/es-MX' { $checksum = 'ba166ebb5ef4b31d9e021e0c5fc01d41b5d8b295a2a867f92f0f4eea2fbc7042' }
  'win64/et'    { $checksum = '3c668235ddc6dc282eb72a8966849fdfa44b67a91eda210ae54a8c31bf2aebad' }
  'win64/eu'    { $checksum = '784477ecbc23a770b22c9cb3a72863a2b3f425b960297f4bbbc99bf8415cf3b0' }
  'win64/fi'    { $checksum = '069e6368fb1bb11204c22829df31bd5b3856cc52526b2ad843436dcda68714f3' }
  'win64/fr'    { $checksum = 'd7a6201c76076570d6e0b0fd03388c8496f0fbfe30860bfb017e453b8c951677' }
  'win64/fy-NL' { $checksum = '4db42875b8cae1c86198f9a8753b8e3af8e54025a9abef37950cfc5011906dd4' }
  'win64/ga-IE' { $checksum = 'ccb04085fabec775877e5b3065cb4fb101e6f872442409ed5fcdfbd1b93dc300' }
  'win64/gd'    { $checksum = '864437be4e84b8fced9c12193683bcccdc81fed64fc542d9ae8f4fa451f5a2cc' }
  'win64/gl'    { $checksum = '7ba1421b4166b8eb3d3f5abd9ae53e30f26b66215c80ed5e107c947985b06877' }
  'win64/he'    { $checksum = '958094c9c1f2ecf306e22bc2a9ae149b30384f03e672378d5fc813f48030b848' }
  'win64/hr'    { $checksum = '3847af67e35ed3533121381e4dfc701b3462ea80ce570bf015cf2202ba37f384' }
  'win64/hsb'   { $checksum = '19a59e7dfc20d356005e233835ad4c7282728e5357cb88dc7902034c8dc2b2fb' }
  'win64/hu'    { $checksum = '0a7e4425715967502fe44eb0c50a20919de2043dbe4e6ed1bc07941999c0eafe' }
  'win64/hy-AM' { $checksum = '8446d5001d3c8885013567b9bbb4c0280ff9e7818f6655a5ecf651351e3eb1b9' }
  'win64/id'    { $checksum = '840a1711f08275081aeee118a29beaa1f9174f318aca752590957eae0d630c47' }
  'win64/is'    { $checksum = 'e8b577ab2bf7ef4faa0026f5c2239cbdb34ce3a6c95523f8f95b008c46d0b4e0' }
  'win64/it'    { $checksum = '883d18eaa4a2de4c47e10c2df937294f6cfb03556bf4052dbebc253b7826ddfb' }
  'win64/ja'    { $checksum = 'e08b846c00e2233a74937fba9021fac0e37102ed989eaa14b41ff6e6ffc6e4fa' }
  'win64/ka'    { $checksum = '3cafc6940d2e212db47fb77e81f5b2a48a522d20a713393215e82f32e8cf5ae1' }
  'win64/kab'   { $checksum = '23595aa94a4b71e2aa005121de3d2aacdf9b4cd3aa03dccf0171f5d901fdebe8' }
  'win64/kk'    { $checksum = 'e406b88ec5946fa9bc6350ee199b96db1d479f823f8c9b5abb6599f7080f0f80' }
  'win64/ko'    { $checksum = '82344dbe2ab7e16dd78a650cd52ee7af9606739ba524d27efc929d86ca4e83ec' }
  'win64/lt'    { $checksum = 'fe1acda9ed0fe232f74973ae383e2f0db85ce69850d38032abe624ba1d8a5967' }
  'win64/lv'    { $checksum = '66cad5295fcf73d9713151ca281e0ba73ed3819409f46b4777dd162b13b0eed9' }
  'win64/mk'    { $checksum = '8225e77eced9e36bfa79c0d2fcf8a22ec0637a7ec39b371ff8dae2c70527942d' }
  'win64/ms'    { $checksum = '33fa6e8c6f5625efdb2a476ce58f5645fa1692a3149af305ba817828b6f6f5c2' }
  'win64/nb-NO' { $checksum = 'f5515ecd264740f72825eed8314fa9786a6f15dbabe2610c66080b7e7497315a' }
  'win64/nl'    { $checksum = 'feaa819f626d3ff36995cfa94fc6174326ac636a4ecbe00da8774419b5c9a11d' }
  'win64/nn-NO' { $checksum = '56c4ba08556680614e912bf716e3638cee1e54402fb5c931a494f4445b9a5526' }
  'win64/pa-IN' { $checksum = '0d2133134e1b7175ebd159dda337011187b7e153935db6677b170c0100ee09a8' }
  'win64/pl'    { $checksum = '29cab68cf6c7eb1f404a64e8f3dbe7fdd1deefe43ef846cde19ccab5428018b4' }
  'win64/pt-BR' { $checksum = '08228ad1d091aca81f14559f29b04301180a856c579ddd5e81de251643dbc511' }
  'win64/pt-PT' { $checksum = '32ac6a008eed176469c9daf80da6244de9ae55d614143c14870fb16dd6090d7e' }
  'win64/rm'    { $checksum = '9752c5cd3aed54853d6157c37675437df627756adc55d0b68e6026184fb4492f' }
  'win64/ro'    { $checksum = '7c0a43ca24d5c73c341d42ba4699731a56b9b1daceeb7d1c71ddaa0b2db49c71' }
  'win64/ru'    { $checksum = 'ac692bab632b09a6d919ed9022038f572f71a69d895f0b4aae3e9e1dd4ef485a' }
  'win64/sk'    { $checksum = '639459963308670cc630df25cd500e314f67a218f21004dce05d874cf110375d' }
  'win64/sl'    { $checksum = '7eeb29bcdc4f0e153804cf7aebf0ceae3ef37c084b0a049611fbb650ab09d68f' }
  'win64/sq'    { $checksum = 'd51ee9f795c0a14971be7c4cba94cf4e8be7fcfaf5708e6538c65c6753cb7416' }
  'win64/sr'    { $checksum = 'cb24d65b802c40d5bec0bc2e70308c6127a0b260d9b4745c3bb594ca6310d119' }
  'win64/sv-SE' { $checksum = '155ec93f5bb19dbf88d9450a0615f2ae127092734ffa793c57bb1f41bc9fa1b6' }
  'win64/th'    { $checksum = '921df840204223885934be1ee6b1f13c9427fa508b2477e773a4551fe17e7042' }
  'win64/tr'    { $checksum = 'f1a664d2ebad155ddc9d72531611a870a1b6080bbafdf3926aee28b3714e261c' }
  'win64/uk'    { $checksum = '5244d16999dd89a9d5d7ad62c3272821ba982ecb265c7f0b11a1f02498f6662e' }
  'win64/uz'    { $checksum = '18692ca717e30fe96c15c174de29ebc611d9bc7ccf9fbb270531077f3b86b52e' }
  'win64/vi'    { $checksum = '0b76e8a0ef3f49d7e5fbae58a3d71424147df9866a00643ff413105dc26ff1d5' }
  'win64/zh-CN' { $checksum = '80ab5d7dfd66744e58fbc3824536d93a91e70663e84bebc98bfe016c60d793c0' }
  'win64/zh-TW' { $checksum = '3c34e55952fa8e22715756a558057937aac442251d173a523125054e97cd1d8c' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
