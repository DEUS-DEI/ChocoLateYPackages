$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '160.0b1'
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
  'win32/af'    { $checksum = '98d1d62833e5cfce12352670808fc806ef38a967b523f5a270e058b29f207973' }
  'win32/ar'    { $checksum = '3c326b054f512d168178e207750e6cea349d669adc01d4783bb020b4ed4105fb' }
  'win32/ast'   { $checksum = 'f39e3802e66e8d89cdc01ced2cfc943a0a8b6fcd0ce42e294a91e6b38c08196a' }
  'win32/be'    { $checksum = 'f3a2ef1d1a5bb69b3462308f6120d4200c3ae828cb6b690fd3e53f3562785166' }
  'win32/bg'    { $checksum = '631276416353a35925f4fc40508b7bbdaa8cb13108335753f800370daf99a3ce' }
  'win32/br'    { $checksum = '01d5fffa92b3e21f409696e6364458ebc99548fc1dd123b9f40b38a484a99da4' }
  'win32/ca'    { $checksum = '63d1f966fb74f50db5c75ebc45c5c7897e74c8d4f40133e2951d4143b8d34c8c' }
  'win32/cak'   { $checksum = '0dab697aa01b36a320bb339ee1a219dcce8183c58c1ab3c0d1ecde36c9c175d9' }
  'win32/cs'    { $checksum = 'a0afa7e788442bd21e26edb35eb3d1f8ae95fd5eb8d597071dfd90c3b0900b90' }
  'win32/cy'    { $checksum = '0e553b820817d372f79008bececf7ccfef4ad4fd3f9003a24ca34c7562c08395' }
  'win32/da'    { $checksum = 'e715b6654e917cb13eb70c40daa311f8e30ad7530e8429d4d2dbcfa58a70633f' }
  'win32/de'    { $checksum = '123e4f61a938cef380c828d073daf09a340db638318e8be68952cc9117426a42' }
  'win32/dsb'   { $checksum = '18104c8c05a56042b4b3694f2179cb47a5b4ed8b1798330b911527ed7a49bede' }
  'win32/el'    { $checksum = '404dd3f91a6c4bda4b3f520b229b141bd907eb948211fd75fb386cecaa0312a4' }
  'win32/en-CA' { $checksum = 'ba6087f13c28a5e7f6c3a1d36730c51ca94e28570939b6f99392a7ed8b49aa9f' }
  'win32/en-GB' { $checksum = '7148e5c93a509f889fabe19567212ee4e52089227aaff1c278f56cf82ac13e44' }
  'win32/en-US' { $checksum = 'a1e25f3970d297c0681ca88fab9035b956e83a796ab948d65afb4891fc986252' }
  'win32/es-AR' { $checksum = 'fd87eed88d835014600f79b7093cd48850bfb73c5bbade446082a7473496da2e' }
  'win32/es-ES' { $checksum = '15303fa24b4d11ef9a68e1da55f819b25b143828eeb8019576be4260d0ef0e16' }
  'win32/es-MX' { $checksum = 'f760c294fb4634286f39a713eec20e9a5028b3dd71ae77517fd4d1374c93ee74' }
  'win32/et'    { $checksum = 'a41a4e47d866de42442903ad027cc2d4958efca6f45393285864362bd41a4e1e' }
  'win32/eu'    { $checksum = 'e84727a829b370e98280483f1183bb4bc4131dd0f7353b2a07e025f3aadd8f89' }
  'win32/fi'    { $checksum = '8185cf44184c510d1afaff8adf485fa50069d06779cd3b75afab39553aec0ec8' }
  'win32/fr'    { $checksum = '1bb813bbfb1f7b6009a4259d334710af60f0c04b5b6d36755a2d39d331e4f882' }
  'win32/fy-NL' { $checksum = '8105e60c9322c31280eb86bbc68408cfd4c80429756f70894bc7ce9ac8fafa04' }
  'win32/ga-IE' { $checksum = '2b6cff7d32fe0a36fd64878a434a13aa18f4239235f2a47533d471cdf7c0a4b4' }
  'win32/gd'    { $checksum = '1ef05397fea53a2c63c47891fe442d7c13c1c6df4ab12d3e568785f8677b5c63' }
  'win32/gl'    { $checksum = '631370bf4b9f83c207148cc9426435b3900d6b8682229e0fecf66354f045e086' }
  'win32/he'    { $checksum = 'aecbb4d1d016d1742508838d409d1631d2c57063fc4b035869c78a24eed85a0e' }
  'win32/hr'    { $checksum = '2f05f957bb8140047eb668c8205ff030e9cb483cd6def8b063894479624d5375' }
  'win32/hsb'   { $checksum = '10cbdaac095a3dd654e60a28302a6d16dfcc60a82905b93fbcbbf1739f66cdec' }
  'win32/hu'    { $checksum = '5e0fd99d72ad6d27eff60830985be8ded0d8e672fe3db86706661c219801831f' }
  'win32/hy-AM' { $checksum = '6dd036227326d0cf02084b35a00307d21e8a739602ce7a9b0136a5172659a394' }
  'win32/id'    { $checksum = 'be3a0f1fff6a246af332ec1c4ff0f283f5a3b606a1ef3cf1d0f389b19363fda0' }
  'win32/is'    { $checksum = 'befc8b6093db9c1eea38112e5d82db322d723733f035649cd17d3fba0f59cda1' }
  'win32/it'    { $checksum = 'de3bd39cd32b69a7d184ee1ef8c68a9bb4f337bd40cd08ccaccf3bfc191a4f8f' }
  'win32/ja'    { $checksum = '83c168f967d0dfdfc2227c8107ecc4a8446fdbbc4bb426119a15bd793fd55890' }
  'win32/ka'    { $checksum = '0fb5c7066fb8dc3c9e173aa0402b975c7961303be6f1323b20d431e636c5f115' }
  'win32/kab'   { $checksum = '82a371e9dbfbc2636f2455b03680f818eafbffc8cde310f1cca623955584f447' }
  'win32/kk'    { $checksum = '07096c70a501167ac354dc0968ab7a908e8605be7584529e36623090910bed1d' }
  'win32/ko'    { $checksum = '0093cc1d1524c30f152b7edab37a93bf74238de6fed5f1555f92d1b29ef33891' }
  'win32/lt'    { $checksum = '9bedad2a4fba78065c749d2a8f32ac8645908ae99db2f38619636e97205ee75b' }
  'win32/lv'    { $checksum = '50619e6e8d831d00ccaf602fbd02578fbb3a10e796e4225ae01e16a27873c37a' }
  'win32/ms'    { $checksum = '8184a8aa74d40098229bc277ea7a90b0239984d754b4fbd4cfa1cfc5af5c6f56' }
  'win32/nb-NO' { $checksum = '62de856bc4ed3c73217c0c3a3d47ba985a3f2e9cbdbd9e7ade28ad0adda4f10a' }
  'win32/nl'    { $checksum = 'a6847162f2b5ea9ea56cc7af578495a95dcfb7b871c665f55d79496ce61b8b12' }
  'win32/nn-NO' { $checksum = '39557981e31a699fd01bbf7aa008afaa8bd8a52f6d9b8f74c4e9f8fe13d33981' }
  'win32/pa-IN' { $checksum = '323bf2df0c8a8ad2c618a08df30ae3924d53086c08587e20b07eb05d2d9b047c' }
  'win32/pl'    { $checksum = 'd3e6d4b7c5cac511adf89feaf57ae597d1cc24c035cfc70fd4cf341127589339' }
  'win32/pt-BR' { $checksum = 'b0f59e2c2747cb423d797da514390950cb1b83cf4810540340baf715dccec408' }
  'win32/pt-PT' { $checksum = 'f2f3e8a0c92fa49425946c0a5b7e89df9611d574775d623fb4c18abc2e7a8984' }
  'win32/rm'    { $checksum = '26139d44fbbbed23fc3599832dbcbacaf0addbefdcddf950b6759819e4ae8122' }
  'win32/ro'    { $checksum = 'c09cbca19a7288b60d3f480ad04970f96529b1700618ec2f9099489aa41b3c81' }
  'win32/ru'    { $checksum = 'f167fd89ea2ff52e5f84781ffe9f764c448a3593d6f2988691518a58291830bc' }
  'win32/sk'    { $checksum = 'f7113b63cafb3d212f7088344648a3661446581092334c53805e9cb79720b3e1' }
  'win32/sl'    { $checksum = 'eae2e121f1349a32bf70aef0516ffe20f0b10bb124d378f06f5cb51643186a65' }
  'win32/sq'    { $checksum = '66225afa878d4064355b8ed5a19ba373c82d0ef12ffb1ae6d819fff9d1ac90fb' }
  'win32/sr'    { $checksum = '84ee2163fa04c13c87ebb05ddbb8e312da99be90c3fbbeb7c6d577eb669d9cb9' }
  'win32/sv-SE' { $checksum = '55b80b3b30c30dca6454bed3208f9ef5613fd8b6b40bde3785c4a5230f4e829b' }
  'win32/th'    { $checksum = '18b23833f04d88bfe7777033d1fd170cac2813e72a12ab682c9f8428b417d886' }
  'win32/tr'    { $checksum = 'c1f12b570c87a1ed4110bc8d986ffa27b75d7b9b8a31a3aca078635a9c77edc9' }
  'win32/uk'    { $checksum = '5e89f4be3b4775051d79aa2702bffba93599962bb8b94becdc839970c4e17af2' }
  'win32/uz'    { $checksum = 'cee70fd36c730aecc4df574ea5eeb270eb1f0cdd58ec05bc45ffed6dcd0a19ff' }
  'win32/vi'    { $checksum = '1992d27fda182008d64652f7822b7a57aec68936f793f9cf361ccde203ba6b11' }
  'win32/zh-CN' { $checksum = 'b3017064ddb6589146c3aa9bd1e06f35989cccf02740eb099b9c47d00a00644d' }
  'win32/zh-TW' { $checksum = 'aca20a23f7ed8a213e2907c5227972bf08fe2af53ad23ac9aa5835c783122b44' }
  'win64/af'    { $checksum = 'fef87a28b50a01ddc127000857c14ddd7a917608629cb17dd0bece7254b799f0' }
  'win64/ar'    { $checksum = '6b67a0e75b880080de6bda9c0c2670845ef7b66f17bf083dab153a2496601def' }
  'win64/ast'   { $checksum = '1b46979941aa2b030114ba8b1c6c5556ad4c5a20a49cc819b1c0371223a97bdb' }
  'win64/be'    { $checksum = '15cdbdc0dab43d5a20c3d966a4efcd2d9e19cff8a6ea104ceb692480a1074d78' }
  'win64/bg'    { $checksum = 'e62a3367c9209a515ecb19b4f11825e585a925f3c39930d15e0cb3ed287badf2' }
  'win64/br'    { $checksum = '5d1a6647fee0e26f316fd39c62b0e7b0998fc6a1062cf5a7e2d8b4f1f8f5804b' }
  'win64/ca'    { $checksum = '577b09f534884ab3283f4674770bc59dda64a44c470f271db02d02487a81857e' }
  'win64/cak'   { $checksum = 'e905bf83e6e2e027a4240903582098da138986d79c7591b519d68e3cc533cd2f' }
  'win64/cs'    { $checksum = '1b518f5a33084a768ae63474afb3057f80047fb34dab157620c39473c822b4cf' }
  'win64/cy'    { $checksum = 'eb8397b89b8ba758c50254429420af08bca0734596547563608e23217e8ce776' }
  'win64/da'    { $checksum = 'c42c4ede1847836e0ec473e14a14479c6e5d1a0b6403504058980a39d00b30cb' }
  'win64/de'    { $checksum = 'd829378737a28d4588b6d3d3d4946f0669512c43957067813646c8f9f8749066' }
  'win64/dsb'   { $checksum = '6eacd7b965c818fef8c70a930cb8ccc498302e56c4d92db3a17cbf15c5f3da8c' }
  'win64/el'    { $checksum = 'b3a180e46911a021a60e79c2ab8048e915a9d0210d02573f38eb393a3f9e7449' }
  'win64/en-CA' { $checksum = 'fad9b53c333eae4654b141fbae5402e184b364ba3bb1464758dbe35af7e08114' }
  'win64/en-GB' { $checksum = '4855ca64dd87665acd910f6c81a8a6cfef7c71ad0e36e65bc9b27f6548044659' }
  'win64/en-US' { $checksum = '6a700500d4fc7b70a14cc7c9fd5975fa4514902fa9f017f600209b855cdca2a6' }
  'win64/es-AR' { $checksum = '1a6fe38ec03d909ff82591ea68aa168e639fe392d44dd80a1972b89cb33bc638' }
  'win64/es-ES' { $checksum = '8519561db0d475224f9e0db86ed11f8a18814ab7cf827de09efb5c80a60d14ec' }
  'win64/es-MX' { $checksum = 'db59c28cfe9356e820a0c1a7ed0e7fe14a6d154e8a932cd78842853f6513f55a' }
  'win64/et'    { $checksum = '67b4e5884a3e2d94397051c610f830cc8f3411dac265175f69eb3be2731168d8' }
  'win64/eu'    { $checksum = '557b0f070d9ac4fe8e5f22056c3b7004b3ef2ac2cd838a0301b6655d9d18ec50' }
  'win64/fi'    { $checksum = '68434416d75ce852de493215f57c8078f622f2ced80a14359d86008213ad4046' }
  'win64/fr'    { $checksum = '6f87ac60024a5e7303ad64e01fe2f7a39c284f8bdc5347e580531a74d20f397f' }
  'win64/fy-NL' { $checksum = 'f4537c326b41e94384a4f71cb94fdcfc10f70fbf04432dd431c347a5393e4540' }
  'win64/ga-IE' { $checksum = 'bb80f9f69daaacf9277cf77b0c1bfb55233420b3c005da5c6c05f46bafeacd8d' }
  'win64/gd'    { $checksum = '519233744aff36d2df1bdb2f8ba854357ff70d5e6f0693da1b7842eef1dadccc' }
  'win64/gl'    { $checksum = 'b2807bd726d5b69fc932401f2c60d4deb6f45a0406f18347395a18a00e9b231f' }
  'win64/he'    { $checksum = 'e521254afb21ae978f43a3f5a5300978f99ed62a575c6d4f6c2d4768192ef29d' }
  'win64/hr'    { $checksum = '0be4e0acc56bcaef55d78659dcd4e682da7a9ec08f6fd675f88b58e044446456' }
  'win64/hsb'   { $checksum = '91dd1bb2ed31debdfe49c2442793b4c15762e3cd613130c75e461fd982a86345' }
  'win64/hu'    { $checksum = 'f976f5355f67fc25bb57cc7e66698942fb1a7e8ef7f21c8064fb503d385637c2' }
  'win64/hy-AM' { $checksum = 'ca57b6bde1a9712b6d344343961e274bf879c0a4606ecf241b9a2fa8e36bb722' }
  'win64/id'    { $checksum = '6ef4b47a804300b31d2a654c463dbd3fb55e1069e12c5185d7877d60595abb93' }
  'win64/is'    { $checksum = 'fcad1348fec7ad941a949d041105a2a3a669883448a84fe3840351bff2035a3c' }
  'win64/it'    { $checksum = 'd6633c8e82ceb237981faf75299159aabaf233b50307bbeefdcdb6f505235aec' }
  'win64/ja'    { $checksum = '678e52016a4f2dc5b53655f43d3786561eec1ef86166a3275de8144fcb6ae389' }
  'win64/ka'    { $checksum = 'eae6806d16ad502f2f9e262f62cf2fdc941a9a6ea2656a6d40bc122590308eb5' }
  'win64/kab'   { $checksum = '2b8c34ab646cf0664f10b6d7fa7314bd7fcf1844302c0247eb69bea06eb4bb15' }
  'win64/kk'    { $checksum = '7ad175b8e7c74e38b47e6ebe289642cf20b7152e53a4733634f0284f86f1a9b2' }
  'win64/ko'    { $checksum = '51c402f76031163a0566ee3757e3725f3d7199297f2aad86fa4cae3b0bdfb6d4' }
  'win64/lt'    { $checksum = '1045c60da7f20ef2e887acd422955aa287e58b3c25a45ebea03cb3a09ae0f1e7' }
  'win64/lv'    { $checksum = 'cb4aa37840bf68614e3d06258f81c7dd52d624c295f08bbb0e63abe18ab78d36' }
  'win64/ms'    { $checksum = '6da9049e33e7462478daa049bbeb1bb6289c2f0be02f08bcc0d237617d121b69' }
  'win64/nb-NO' { $checksum = '7dee6678634a053dd8a206eac3bacb2a3cb900328a71df097f4b9e101eb12f53' }
  'win64/nl'    { $checksum = '6e23f237a3d68cba4ef0ad07d821ac673b6fa6dae5dc5be3ee95d8153ce4eb51' }
  'win64/nn-NO' { $checksum = 'aa5e48035282a08aae2fd6afb8d00c653000a4b1a5c2b456665f857ada6c64e7' }
  'win64/pa-IN' { $checksum = '9b43c496554acd02723dd4bfb000713d2fdbfecab2889bc240d96e29faf5e82a' }
  'win64/pl'    { $checksum = '1a9cda564c72b85a4573d5d14850a08138b194e69b8b298f5ddc6afbc9971415' }
  'win64/pt-BR' { $checksum = '4737ff5927bb7d9c69f6c2f067385738aa7b30735b795a44df65ed7f40bdd18d' }
  'win64/pt-PT' { $checksum = '1fc1677c0ef76a25688357b6945e117fd88b8f717b6745886b9969c247d09680' }
  'win64/rm'    { $checksum = '2ae6b304fa649101bbb8cf74ce92c285c22e7532f8ff2d15de9136110c278f97' }
  'win64/ro'    { $checksum = 'b069cd34b0d940be069e7690b30546fc1b658025027c14d38354af646fc7d49b' }
  'win64/ru'    { $checksum = 'e4b35088fc164d0f26c75fae7ba851f96e5f6fb082886668e054b896169ca871' }
  'win64/sk'    { $checksum = '0e53f3e1d4b5429deacd0cb3f09d9d36c113834a731da18c7a3fa823b78ffce7' }
  'win64/sl'    { $checksum = '6a86fd6049c7a312e4f49246bd408466b4059d099bb7a3fa7a013487df48eb08' }
  'win64/sq'    { $checksum = '1937c3a52cd917b45a65aae4fe6d290701fb4492f6aec67198ae43b176632e14' }
  'win64/sr'    { $checksum = '5568285b86a666be2015edea016fce4bcbdbe915f2a84eafc52694c77d580eff' }
  'win64/sv-SE' { $checksum = '2a1841849625f790b665e59747b4c3d69656047f7ae34c1e3e4c2bcf876322d8' }
  'win64/th'    { $checksum = '9b445871dd5a3b5d071e3fe52157736065179ea8ad54662faeb5c8e9c8e828e2' }
  'win64/tr'    { $checksum = 'fb11b6288384ff0b85d129c304c4a5613fc43fba0833f65e46c4420ec77813db' }
  'win64/uk'    { $checksum = '370267904e3e3da50e140e0e8970a9ea5a393abe0c6f70dcaa062228a2089a7b' }
  'win64/uz'    { $checksum = '3623de9f7efaf08b9fd3d204aea7f67b9cd272d708d0116e202af4d64dd6f63d' }
  'win64/vi'    { $checksum = 'b1896ec06974322e0f1afa9f8d67c559b64a8b188bc61eff28e3b1ffa5972859' }
  'win64/zh-CN' { $checksum = 'fd9b9a327c5df9b342f3276dfe753959e4f26345d5c67ad7f84d98e19ff1a903' }
  'win64/zh-TW' { $checksum = 'db96f79d733e9e15c5d8d7a496ff4e12fcd9bd36bef573ae2a31ca7e4fb1efa8' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
