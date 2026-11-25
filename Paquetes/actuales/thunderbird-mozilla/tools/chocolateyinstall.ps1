$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '162.0b2'
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
  'win32/af'    { $checksum = '4fa28eacdfa51aac65df095b4eb5bc75c0aeeb161f0d766baf77c79911a3382b' }
  'win32/ar'    { $checksum = 'ed777c8e6f20eeb1d872afe74fa73f49e256091961ca9502a787656541fc873a' }
  'win32/ast'   { $checksum = '839ab3d32ceacbf03996c3427465dfb3f1ec35254f9285222815db9ec13b6e4e' }
  'win32/be'    { $checksum = 'c1fb66c6bbb8a122b410b558335c36e9319399b6a39ca5147352fc6366978891' }
  'win32/bg'    { $checksum = '223a5cf0a5f1d5f6f747cc35ccb12a7fbfd63c09b653f37e3f0f34f9380920ca' }
  'win32/br'    { $checksum = 'bedc794d7db3456ae819b301019194b53c26a69ebc06e98b668e07563e33a368' }
  'win32/ca'    { $checksum = '3b7447af79733a74ccf24db53620349e322f02b27214d52fb6f7ed072f36b660' }
  'win32/cak'   { $checksum = '5ac5d93aaca9ba371772beb1cda387119f2dbba384e36edbd63485c6dbebefca' }
  'win32/cs'    { $checksum = '8ef7c50702c3e04354fe39a74eabc2dbf755dd0a670c8078bce50b83232b693b' }
  'win32/cy'    { $checksum = 'a7b6ff92d89df35fac91ef2af2a68ddb8ab657c18d679f65b2da703eaaf83374' }
  'win32/da'    { $checksum = '0a0a7f73c728c24f19e5f2c1d4d2631a6d788f8c3bc3c600ee58194d5c6ea7e0' }
  'win32/de'    { $checksum = 'ae140aad5bd38b5167353d9a5ba3fd210fa9290d5b007d6ba616c994cdaf0118' }
  'win32/dsb'   { $checksum = '47ef64a0fd1a1bdb22a3509740c9434bb8f28cbd3265e757007432469d782384' }
  'win32/el'    { $checksum = '985ade453e2b1eed3d79696a616b42558ab9df55dd16e3a1fa15da8b084c5da1' }
  'win32/en-CA' { $checksum = 'd9f5ef01e17082c9933021496a57523911d1ecae9f17c0f8e84478c563ad76b2' }
  'win32/en-GB' { $checksum = '9b7fa1b42509d31ebbc7c03064aea1363988bfecf496ad26df7e69c6380ee196' }
  'win32/en-US' { $checksum = '944d1ae1f50ab996134f484592d84704f764ceeb20bafb925d91cb31048a1e88' }
  'win32/es-AR' { $checksum = 'be8ccd4e7b081bdb940b64cf433900543c6ff7b5dcd4b809f22a31e96fca1b33' }
  'win32/es-ES' { $checksum = '66b446ba669a85d839fc74093993fe413513005f2f8a1309205e40ce588a6e57' }
  'win32/es-MX' { $checksum = 'ae55519a12d4eec8707030d395507ebb07d3a9a7f53366f1cffb69abafb363f7' }
  'win32/et'    { $checksum = 'ab64fb78e5388352c551ecebccbf9d60ceca1cc8214f8dcb208395e2fbc11bba' }
  'win32/eu'    { $checksum = 'ccd1832d1b14c17917592033701a3a45372a8005d374a8a730edc5b2471886a2' }
  'win32/fi'    { $checksum = '9803b3f0330d9b02ca55aa7be9a0850c38d0ad2e7ae2581538f2962d8b99cca1' }
  'win32/fr'    { $checksum = 'b906bb02b49ccf18b1fb0dced2fb78cd88df46ae316a57b439302ea0130a8489' }
  'win32/fy-NL' { $checksum = 'cbf28c445c8e71b2321cfaed1a3d4676e0f8b67ab9a054d888bc917395143280' }
  'win32/ga-IE' { $checksum = 'bdd7bc5ca59768d2248bf7747c65ca36f3bd5d2398a1d12026410f128d7e2b9c' }
  'win32/gd'    { $checksum = '7e7ce134423e1ce90fab7285666ae4c47a0e107fdad2c18fa75c61fd23dc708b' }
  'win32/gl'    { $checksum = '80aed7bfdaebdce8430fe4544f13b3f33e54c3293b83d0fe67c5a474ceb8f831' }
  'win32/he'    { $checksum = '9811b7107a2ec4f24f33639add6200b5a79c3152468ac8e7a928c6a239a3adc9' }
  'win32/hr'    { $checksum = '5cd6fae6476beb697654134fb0b916084064ece53fcde922c6db6d192a0dea42' }
  'win32/hsb'   { $checksum = 'd83831255f4062282eb1db1cf27843478a24f8933825d1f60420170f046bf3d2' }
  'win32/hu'    { $checksum = 'ed14453eac2224cb29a24c70cd139165e32a7b4a6ed48a848d4bdfeff16a92b9' }
  'win32/hy-AM' { $checksum = 'bcaf7244e5c776c80a17e1169d951664c04f4ef5cd22ba17964c1f53222b9a74' }
  'win32/id'    { $checksum = 'c3849a328f9c4e913659ae645e8aa576612da315e9c00270824a1ea07d85b73d' }
  'win32/is'    { $checksum = '29d3b495636466fe0353f8820f6058521dd70a40c22b61dfbae52bbd8496ca0f' }
  'win32/it'    { $checksum = 'f79c7882134faa2a55b43c7d7ac4aee9f8fcd9439a34730382f40c85c50ba835' }
  'win32/ja'    { $checksum = 'd09195f1c4c53e2525e91e2ae8fae40f7acafd8df6bef90b6d3bba028765e450' }
  'win32/ka'    { $checksum = '7929caca910806d654820d73def0da9402667b6509e306861520d83b1dcc9c58' }
  'win32/kab'   { $checksum = '5412625c0b0f4e3f5f88af2dcabc23a8838b633ae08f80cc8a9246b2f1b39bc5' }
  'win32/kk'    { $checksum = '48fc59e81d9446d31a618eb62cb69bb93ad1ce33072815b925bc817227cfa2bf' }
  'win32/ko'    { $checksum = '64fa8dc055e370c5569eab0c02f8d07a20f2098ecfdc9309c6b85cbeffd05b04' }
  'win32/lt'    { $checksum = '24f33c673f962ead93a00a8887afa4fed3fa699b87086d28eeb5b35a4b9ab591' }
  'win32/lv'    { $checksum = '491fae41a1ad25c49cdc8918dfb48f2e1611f8f3211d0f742ca48afcfc8a4543' }
  'win32/ms'    { $checksum = '7776ac37ffdc87db1d08ccc57e8d649f8c0395d494135bbbf399477cd6a81dbd' }
  'win32/nb-NO' { $checksum = 'f95cf6f4f1211440c7bbad7a50c63a129a349644f57243796d9be4556af70f36' }
  'win32/nl'    { $checksum = '905442caf4c30e03182d8367aa1b8097a83482d0e4a87ad5d22dfef111e4d717' }
  'win32/nn-NO' { $checksum = 'e5f3c0e868b5af5a90e013c0d8af8e4b2a25e2188211ced5a122f6c1b6744d35' }
  'win32/pa-IN' { $checksum = '6dd4e33b8f6676fd0c12d6b781d3eb86f57f22344ce53fe22b07ca0e7f8d2d90' }
  'win32/pl'    { $checksum = '7ccb97163b6b6a2129f140bee083e5de35ac562795e4639f2b4b335fb9396b94' }
  'win32/pt-BR' { $checksum = 'ff14438869f9f660efcd4202683a766ae94443c1cffd9b2cd35c6fb299ac8cb4' }
  'win32/pt-PT' { $checksum = '8df8c3ad77f700a4f27eea3b542d3349e710a2270176ccabff37d2eee4580047' }
  'win32/rm'    { $checksum = '3498b353b02df47541ca670fe7929746ac041162363562076c059a185b95f4a2' }
  'win32/ro'    { $checksum = 'dc0e550f6a88e30a69843ce78836ece1f81cfb7e84df2af0658d39025281d634' }
  'win32/ru'    { $checksum = 'cca716d9477ed1f8054e3b405c96b58493599c081f634764fe3a742b808ef5b5' }
  'win32/sk'    { $checksum = 'e2504d621051d389092f868252eaf28699ba2adf018647a0751b0bba30ed5b8e' }
  'win32/sl'    { $checksum = '357cff81e48ca6b0787438da56215b380435758c2dba481669a5ff2b7f9e28eb' }
  'win32/sq'    { $checksum = '357b8f206881c2d4e8eb5e7a5a296e96ceafda62418751f03a71e7f5852a61c5' }
  'win32/sr'    { $checksum = '11887df3e621fe7df032d8027c1f8e2abf2190af984e57e0618c32d912ea07db' }
  'win32/sv-SE' { $checksum = '8749e0e4457a218dab4988334bfe87c18fa80173f1510fe959b638248b703c51' }
  'win32/th'    { $checksum = '1787b4755a124e4be0cd299a9a99bbe9071bd5384d9d5babc496e5b0ce30a8d2' }
  'win32/tr'    { $checksum = 'e2850fab439b96948807d2fa9bff11e61bc08acdb5ad19bbf05352d054ed2667' }
  'win32/uk'    { $checksum = 'e08a0166157fe1811892e91b736cfb7ce56385ae9781b637dbebec7af4765c11' }
  'win32/uz'    { $checksum = '9bb3024b15142baaac5907473a63d7ca2c8165edcf9e1f670d556d3d7299b5d1' }
  'win32/vi'    { $checksum = '57b767af1adfb0e6a2180be4572d1746627bd7f20a5bf80dfb681d6dd20cfc99' }
  'win32/zh-CN' { $checksum = 'f4659b0f4901ab1d434d7bb02e6190202d1749c68de87b977ec3a5ecb5299770' }
  'win32/zh-TW' { $checksum = 'e438627847e15b75736ceedcd40521251e8f6c3f45771d77623e00195ebb942f' }
  'win64/af'    { $checksum = '3bd8bf9ae61d75e11123d652593811dde16205598af85beff532015a717093de' }
  'win64/ar'    { $checksum = 'cac0a85923154c6668274263d56f62ffeddc6dead8d2f97b77493944bd258372' }
  'win64/ast'   { $checksum = '06be6fa9a85fd554f276cc593a0d89d484849c4d2ffadd6f1423e75318f8308b' }
  'win64/be'    { $checksum = 'd9b700441984d2cadf609a24826656263f7adda800073ed580b2d9bb303e7523' }
  'win64/bg'    { $checksum = '66b0157a4ea2ec7d475e7053e0f93037957a294c5813d3af28da7e0c898cab78' }
  'win64/br'    { $checksum = 'bd617a4b673f8146233a3b81301aa6392e72bfa1c9e279ec740c2c6603d29e9b' }
  'win64/ca'    { $checksum = 'bb2b0be08c8b0cfad31633031bd14d3a6741de385b27ec0972341687379eb4a4' }
  'win64/cak'   { $checksum = '6841e9a825f770b0ab7ddbe645b71edd639743f7013b4d5747ae53b3fb8a6d09' }
  'win64/cs'    { $checksum = 'a11c0868ff61766100c0ff185d1ad72e312ca000735df4651c098c605ca41515' }
  'win64/cy'    { $checksum = '10dc1ae38c9ec06cafd92b7bfb51aa376f8c83c786ae319853c71bb14b4a1f03' }
  'win64/da'    { $checksum = 'f1b920640947eb41454dc5566f83fa00339cc7ba10b90c152aa265e7cd2c3595' }
  'win64/de'    { $checksum = '7f54cae8e8782f908445e1d4c5d1b4121d842635c6081adb7f7ea94af9aa0ce3' }
  'win64/dsb'   { $checksum = '0e47f902c7f957629173c0c98c879934c26da7def87022cb6af49eede9ccf847' }
  'win64/el'    { $checksum = '31ce8707138b763c34aa16fb69ff48be4d06ee42d3d283d2099921892903b40b' }
  'win64/en-CA' { $checksum = '470cf821bbcaa9ba6994939a23b649a8327ed66fce43285511f86450da5fe514' }
  'win64/en-GB' { $checksum = 'ad826841af380030c9998a8044a6131b4472ac3197fafc5644b1a9cbac691a18' }
  'win64/en-US' { $checksum = '08ff5e836fa89572a8d8ae00de76b8402e208e5c717ca32ddbd7a18901301239' }
  'win64/es-AR' { $checksum = 'e5451c4df6ef71598274f276dc10de3d7277ebd8942463076af0bd10bdadcd71' }
  'win64/es-ES' { $checksum = 'd4a737bbbb1f0976f99288201d2101cef678aa18396c289691aa624639a7a5b5' }
  'win64/es-MX' { $checksum = '22abb9a9e9ae6f1407365446003870dc4a7ac759c0cb8c0333fd552fe6a16583' }
  'win64/et'    { $checksum = '7aa6ab1e9a95c0aaed52d45297d801ff5b5d2e1b1479855d89277adbfba10efd' }
  'win64/eu'    { $checksum = '82678e97aa04d23b28d4b0715232b737ea51b7c2dcd5e37400b52305ff067cd8' }
  'win64/fi'    { $checksum = '9dbd296b44eb95125b4ec3989492dc4865e5410649d903bc82f580c12b7bc960' }
  'win64/fr'    { $checksum = 'e84a3f54ed6f6c034c6821cf8ce37c869feb8a8c86b847e218645882f5e1df6e' }
  'win64/fy-NL' { $checksum = '28fb7def1bc6d4209986948b5ff29711fa2054fec76cd6eb4b3bc9dc530ae3cd' }
  'win64/ga-IE' { $checksum = 'a96940cc973ca3b147e807984d1cf76d9ba5c68de07a0cc1c07eed83f3b7e736' }
  'win64/gd'    { $checksum = '89d1dd65d6985184cdaf196df358130043878421aeae248b537279b1e13a34ed' }
  'win64/gl'    { $checksum = '228f0ca3bb5f40e4b90a97918c008cedf9d8974dc361cac998a4d2509f9f6bed' }
  'win64/he'    { $checksum = '8fad0b2285afc4958e6acb741b91a8c2ca632d0d6242ea01b7eaac047b83c210' }
  'win64/hr'    { $checksum = 'd88c793fbff3280a6789e84f4fc97c7c8eb3327b5e2926121454c2354b8b8e0d' }
  'win64/hsb'   { $checksum = 'e2dec043ed7f0ee075cc8e4fb97ef40fcfcabf13050a942cc00f6f07ce4f785d' }
  'win64/hu'    { $checksum = 'b26089de74a632084e2d482eec357c0deb5672ad63d231bb9f3df3b878999e13' }
  'win64/hy-AM' { $checksum = '297c22b3f121cd7e1e550d87905105bbed41e7be1c6fa0c2d2f904a9f18199a6' }
  'win64/id'    { $checksum = 'a29de732c1a8e2b6e943266144e5d494b15b6ccf99110795f78a97b92ef412a1' }
  'win64/is'    { $checksum = '26c98fb62decebf5664f258789d5d684c91a320829e4306226da948fd6d5b846' }
  'win64/it'    { $checksum = '2c0128ec6d0fb43ad7f9626c4180e96fbaeb68ac918bda8a67942172fd6dbe6a' }
  'win64/ja'    { $checksum = 'fc7095a9a88f07e3bc0c42ce165f4c929406a681a6f06eeeb1e7effa1d21d5de' }
  'win64/ka'    { $checksum = '9442d6cad3a196d9fd317a1860d95648adf8a1b5ba4474025164299a78ee4cb8' }
  'win64/kab'   { $checksum = '287d8635d9d219f54b5973be9996d8ff1500e471c6b8db3cb2e4d0d57cd41ca8' }
  'win64/kk'    { $checksum = 'bd4ef45628aa1b1e3f4a7bf1557d852aa7e327f3d7e54632f9ddf1c0b35d0373' }
  'win64/ko'    { $checksum = 'd404012689fae9f94db83da74a960e1177028dcfa75e4513ad5b8573e384374a' }
  'win64/lt'    { $checksum = 'e711486e561c8aea8db0f08b3183d46632c9492f6f7fcea04ae2c5265b8761ea' }
  'win64/lv'    { $checksum = '379d9f9d4014de760bcba1aac36c6afbf851139a59009e61d368755dfce6eeac' }
  'win64/ms'    { $checksum = 'eeda7f439243f83bf82b6fb9ec72c58c0232eade7d23003f18ef5da776848c91' }
  'win64/nb-NO' { $checksum = 'ef255ed1ae5d8f0524454d14c51b4edee6ffd314a3a99181a46af4622dcfce0d' }
  'win64/nl'    { $checksum = '27c69131e3ef52686224007d8a6d6531426e27fb8c7ec1ee7308a29f0f93f404' }
  'win64/nn-NO' { $checksum = '461b9409011423354b5fc7ec779a72a300d819948c7cac88d077f3794be827fd' }
  'win64/pa-IN' { $checksum = '61abfbd8bc7d2acb42c1b3a2c73f32153010ad8b3a9a093e236908e9901fe44b' }
  'win64/pl'    { $checksum = 'b4649669155c8ac9b5a59edf151904dea16111e6877a56171fe645af788dc82d' }
  'win64/pt-BR' { $checksum = '5d28a4b9c3dea19eab804a86f6aec1f8a12489305245c4ae63e6a6d8245c9f3f' }
  'win64/pt-PT' { $checksum = 'fa7e03a57f6135b3b7149b151483e235379869111b5764d42559930d5b5f0066' }
  'win64/rm'    { $checksum = '16aa73276edbd35c9034ebe83db4551e4bb6c7d0be723e03711e02325eb8aaf1' }
  'win64/ro'    { $checksum = '395cf054ed5bfc75c3488720da2f87219f37516e3cc127b6c5b9e7aaa9160a61' }
  'win64/ru'    { $checksum = 'e6e03099a8afde797734d0e3f96c1a61fa40d1fac8638e1381a0078bba251bad' }
  'win64/sk'    { $checksum = '206b3782b348a517a7724c25c4379e895db372d11370bcfdf255d7162d0f5e82' }
  'win64/sl'    { $checksum = '2ff679c35e662c988759dec5e36e677a43a212f46c9f3c44ca6d59edff6016d9' }
  'win64/sq'    { $checksum = 'c5738ba1e38b7b1f41eefa185bea189db99afbd5b086d957285fa17b7ffb1b65' }
  'win64/sr'    { $checksum = '982ebbfd2b282af6ff7b5e551694afb7d7cfd9153998d6393fd27b06b7ea8655' }
  'win64/sv-SE' { $checksum = 'e385bb8a1180d150802cabc8ad428e14536bd8f0f3eefc0fb29dac7956d0dee8' }
  'win64/th'    { $checksum = 'd8efa4c06b3f9a1578e52f441fdfdd8ae1a611224963cc5cc310eccdfb402814' }
  'win64/tr'    { $checksum = '31c8855c6ff12e07512612162bf169f0b91ac0e903bb4ea2d05b0eb96e43b6a7' }
  'win64/uk'    { $checksum = 'de57051d8f893ea95561c311f2e864fe1b65b9273c62f4553c2f08eace96f7fa' }
  'win64/uz'    { $checksum = 'dcf44c14834d88a27d5a601966139ae83763e8c4c9707befef10a5f451d28a7f' }
  'win64/vi'    { $checksum = 'a3acea2c1add8c10d74e55c31d55c0767d25dd01413023c8bb0adf613642120a' }
  'win64/zh-CN' { $checksum = '573fb1f5b85f9024ccc4ae3fa665032b1b9855356504be89c285661619e936c7' }
  'win64/zh-TW' { $checksum = 'a968d70cf0e8921fe03b9d7e52f9510e7f07f7e35e262924ccde7a57c1d56a16' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
