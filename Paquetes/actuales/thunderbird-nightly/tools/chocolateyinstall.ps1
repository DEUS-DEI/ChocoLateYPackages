$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird Daily requires Windows 10 or newer.'
}

# One nightly build, in its immutable dated folders ("latest" is overwritten every day)
$version = '161.0a1'
$baseUrl = 'https://ftp.mozilla.org/pub/thunderbird/nightly/2026/11'
$build   = '2026-11-01-09-08-50'

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
  'win32/af'    { $checksum = 'f7e774053aa1e92b36d7eb867430e4d2092dbf086fc021af60e67351428afd6c' }
  'win32/ar'    { $checksum = '37761d52f204ee38f1460fbb96a629031cc62e81598ecdad2480cff685ca3c9c' }
  'win32/ast'   { $checksum = '132b3069e5a79fb9ca3cc64b581088bb22bcc23a8c079af835361a092cdc689f' }
  'win32/be'    { $checksum = 'e371105d62c45c59cf4b89f0887125fd907735f4e3509c821eaaa65b0c229383' }
  'win32/bg'    { $checksum = '3f85b2c41671ced398d5a3481034f2ddcdab6b8f22b906a4df9e7bcb6848c1c6' }
  'win32/br'    { $checksum = 'b1e8ab216590042a70e9e344854d2108a370bfe517f5cabd768090318fd0702d' }
  'win32/ca'    { $checksum = 'f431c3906627e2e195734fbd6c156201eb3613d069aea36bcc31ede32af74ee9' }
  'win32/cak'   { $checksum = 'cee92d4447a2d1750d9824df512f7e5af830a57cb292a414b34312cf2c19534d' }
  'win32/cs'    { $checksum = '2cf628b9072b1d31d61e2f85f6c0ab6ca7402cafbb8c8c8334182154932a01c0' }
  'win32/cy'    { $checksum = 'babc791f1b7d74cfff9f6ed38d785cb33db75c402e61525cefa459a3d21423eb' }
  'win32/da'    { $checksum = 'baae4d8d5bc1a20f6c7e3871a9d2f19e7ca9f013f2954ec966d08ca714b46392' }
  'win32/de'    { $checksum = '69c3549ba3dffcc0437776c1c0c47caab4325408b16f24398dfbb88df499ab11' }
  'win32/dsb'   { $checksum = '37cccb2e055822f494de6a42b469408f9fbdc4c90184c5feee4bcd001ce5246f' }
  'win32/el'    { $checksum = '8902ab7630cce04081d2ab98b9f1729d3b6a74715b84db8f10c70e6ad81ffae5' }
  'win32/en-CA' { $checksum = '3ad70dfc0e280f8e071f0952a2913f70d04cdabba7bc7d86348a61c94f6f1e2b' }
  'win32/en-GB' { $checksum = '566f2cd21358e9e19ed4ab9880ae222a7016b6820d019a83202340cbd2b2119b' }
  'win32/en-US' { $checksum = 'ec56d34ceb97ca075e5c03ef6c219e6af19e727ba6d4b36f961552b5a6781dc1' }
  'win32/es-AR' { $checksum = 'e2512d643013f3a7ff0e1e80ea0bb66aa0a87197aed934507e9c34a807ee57c3' }
  'win32/es-ES' { $checksum = '02fa66228009070a72d932bd0fabe69f71bc4c0c8c1a3c3fe4fed8d85afc7429' }
  'win32/es-MX' { $checksum = 'e3e36449a620c34c22b6434eb02ffb74257b219ac16780c452f298971642ee15' }
  'win32/et'    { $checksum = '240dd3d4b93c47f7beb3efa67f471728c60254b22d5157a3ba981480e2ce3e1d' }
  'win32/eu'    { $checksum = '5bd78c0576f8e219ca2f0eb6178f1ca52568948a62dbae02d3386d4bdb59f16a' }
  'win32/fi'    { $checksum = '851816036bd22273d7f9d70bbc850e9bfc224a25447525f20879231189542e65' }
  'win32/fr'    { $checksum = 'f6415d54ca779b4b1e9313756f25e27c04c2503cd870334e701461246c830607' }
  'win32/fy-NL' { $checksum = 'bf267b1665c0015177d77be046de158fa3e6298688bda34945e8326636a34f52' }
  'win32/ga-IE' { $checksum = '0cec71344b7b4f0c8e88fd50fbd7997490fa2293af4225462c5ca12140ebfb9d' }
  'win32/gd'    { $checksum = 'df62232ed881b44aa9d92c924436497b3ac00498573bb7e086bfdec84eed0b72' }
  'win32/gl'    { $checksum = 'b359f192a760d931a023def5340422b521bf8b91236f732e7d7328c096abbf37' }
  'win32/he'    { $checksum = '4e188c874386d2c12474324f4259869eb8c6c10abf20cb7a223bbc8c0af36fa7' }
  'win32/hr'    { $checksum = '1d95aa684ab0b2881070073769983d2782aa7426ac9606903718dff766e7c88b' }
  'win32/hsb'   { $checksum = 'a6d6418eeeb0b331396b294c98a68d03b1e601c34a87943d21fce419d3c55131' }
  'win32/hu'    { $checksum = 'e604d7241051b1c906bffb6ce3da83351cfb6ecefb1cd19fa9704d26f0f93edb' }
  'win32/hy-AM' { $checksum = '8dab5b9e1ff68a9cbac88219e3003282101a1c8d857264576543e4fbf6829656' }
  'win32/id'    { $checksum = '70cb88e33bbc45366e62d25cdc34d7ed02f9c71ab2ac0b936ae46a17834b7192' }
  'win32/is'    { $checksum = '13a22d79e8ec2fc8adad1a03a1e67f849c6e371b72c88d713fd4cbbef99a335d' }
  'win32/it'    { $checksum = '2279566ec8fbbe7d46c499cfae5f8269f5b6b93ee16e6ec9b9d9a6d5a73cec30' }
  'win32/ja'    { $checksum = '271b54c006f6c1707427af7665f83e31e82a1bd26bce5e07b4a3b074a0132414' }
  'win32/ka'    { $checksum = '5cfdb3ffca865422db25dc1cb0ab7a73532fad70b0da7b23827a3ac61f8f4f55' }
  'win32/kab'   { $checksum = '20d9796283c9c85e8c71fa3a30bebaa79410eceaf43701e16575988d514ed949' }
  'win32/kk'    { $checksum = '0eb661bef76f555e4dfe5603edf2ef660fec5d22fdd94955269a90493bffde3e' }
  'win32/ko'    { $checksum = '451d6ba802dda6ea072272926412e5e714a2232fbac35fc038e9a013be899e2e' }
  'win32/lt'    { $checksum = '249b2dd7ced87fdb97ebcb6062ba15d876fc52eb119bdc9eaff04a5eaa44851d' }
  'win32/lv'    { $checksum = '970fde8990df6707ce6464a6c20c63a0591e2f0f14810ea5862b9c35a32d861c' }
  'win32/mk'    { $checksum = '7065e8244a5a2ebb34b4940e8c1fda20487810a0865e7c379d3fd87d95fbcc46' }
  'win32/ms'    { $checksum = 'c646cee7caf734504ff8ff9b0d1ea21229044f2fdeeef2c4cabc8c2c660094de' }
  'win32/nb-NO' { $checksum = 'b04c1bb1b28a93f82e7a44da97610a094eb61acb3c50bf3c446e3894c7fee794' }
  'win32/nl'    { $checksum = '7f4f60b1ae7fdcb72f957c61fd78d374c559b3498b3d48dfdc056e07a15c15bf' }
  'win32/nn-NO' { $checksum = 'e99a9d594110da7b481e35bb5c651031184c231e1e9f4bd6967278b3900b2c3d' }
  'win32/pa-IN' { $checksum = '620a1a876e899c1df69faedf2752d725ebc54c849488eb7d364aa89f40b16ada' }
  'win32/pl'    { $checksum = '9daf3440e0fc71b640602dff5c77deccb5fd9a4d4910be82c50714429bfdc84b' }
  'win32/pt-BR' { $checksum = '14137e31180159ccc1d818954d2d370c6eca5a547cc3e31e74393f3a270aa501' }
  'win32/pt-PT' { $checksum = 'b48bed25279c86b9a989c93907c41f3170962f2be442e2abff063387cccecce1' }
  'win32/rm'    { $checksum = 'fc101e31458c9f9cb6f510f040c2118852548982f747365a5fb8cd6121866baf' }
  'win32/ro'    { $checksum = 'b8eee3265258af8f7b182188b8769afedb46c8bd6bf7cf062dc179bfa54af761' }
  'win32/ru'    { $checksum = '6e221482a3e48aa6fd835dc6d2b39693552322636df0aa9143d4cd73353a3b8b' }
  'win32/sk'    { $checksum = '829f8a983886fbce1ef308d48b5334c2657b20e9913a7fbb89c9a5e4bd87d4ad' }
  'win32/sl'    { $checksum = '7cde8e84ed97143c7d5f78feef9c29b6302259a2c89ad5795d2c469d8e7ca502' }
  'win32/sq'    { $checksum = 'd7c193e400baf0a135aae6f85949ccec8b80f2047fe8da1e2ce95f804e4fa5d5' }
  'win32/sr'    { $checksum = 'ac4ddcca688f31e4be6f5d3b60d96c04903823b2b2745dd9202c929bf6003814' }
  'win32/sv-SE' { $checksum = '9cd92d9fe878d7ea71140ebee59737eedfa7bdf3774ad41de6cd522e456cbe17' }
  'win32/th'    { $checksum = '3a231acd67fc836bab16c68cb8eb792fcc383ab834cb6ee6bf7e960cd3322055' }
  'win32/tr'    { $checksum = '4ef2482ce62ea285cd0d5b211bc567de55554f83e0009115d01f42620e7c6d7a' }
  'win32/uk'    { $checksum = '671c846ff7f039947bc32b6773d973658eb08657ff6f875eb13c148b890f6d0e' }
  'win32/uz'    { $checksum = '047b2fc3ae7839be12db6b194b6ff3e1ed12d91003bde9d28a885b35f9acd131' }
  'win32/vi'    { $checksum = '55acd2e036882c5b349d134420dba212bc4c3b9391e2df94f98cc39222949f68' }
  'win32/zh-CN' { $checksum = '61e3c8edbc61614ee8f958cac90dcf2b8a8b77681676dec30587dccfbb069a3f' }
  'win32/zh-TW' { $checksum = '939f6959f323d8afbdef1e1ac2d812304bdbd0fe89147bbf999268a63005087a' }
  'win64/af'    { $checksum = 'f9e31decb4dcbe168273786a27b1ca5d5bed73a963caa754224f4c94948261a0' }
  'win64/ar'    { $checksum = '013ac8636378f5e25b4499d0e3cb3de019f6d1e579223ac34232205c8a9fd01c' }
  'win64/ast'   { $checksum = '01dfdcbd68af61c8530671d5246c9eeb2c7c4ed6e4584303a10a63a1b3bc2e35' }
  'win64/be'    { $checksum = 'a82e0a9c6e7cd813b3bdbc9d2c69d4e3f1d17386aac95f4c5294ba2b7bc27253' }
  'win64/bg'    { $checksum = '69df617403a825e9ace0dd0bd6d883c777246ce8f668ba2820e9ca351e73dd72' }
  'win64/br'    { $checksum = 'f02d6e5f8b27abcc4ba02103edcb815c393cc3098169113e748608afcd563ab5' }
  'win64/ca'    { $checksum = 'c4ffe33bb182d045ba248038f2478977d3679551aac87d848d0807e0d77de118' }
  'win64/cak'   { $checksum = '7c2b9f70aa573b6a93e47a85a9608b43e227101ce718126d6fe11b372490e4b6' }
  'win64/cs'    { $checksum = 'ed4123a2470f315f0ffbdc8b5bca0b2bed5ae30f04a365721b4091665b0b8c5f' }
  'win64/cy'    { $checksum = 'ee28253b33c7de168a7888c60d78f008fc6592c278a68355e6aca2d3c5b62f18' }
  'win64/da'    { $checksum = '6dde074f76bbf21fe967cde762220ab3ef1cc46661c3d156c23d4eda59f6e1bd' }
  'win64/de'    { $checksum = '0afd25338d49c88b33a04b7f70cbb01fee469a284c0bb001ca3a5982640496e7' }
  'win64/dsb'   { $checksum = '63a5efe790aed7246afef971d628770fc3cce49cc5c65f1aca01330b2d4c3b74' }
  'win64/el'    { $checksum = '37b675e171641bf29c575a84811c021cfae36b8466b98ebcc666929acde7d12f' }
  'win64/en-CA' { $checksum = 'b79ae5e94e74f125a9e1ecad737a00aff46e5e7172ea9569f15275ece4d7d4cf' }
  'win64/en-GB' { $checksum = '53235e9d2e7669b2c060463bf1d1486a10d4a067df9e9d7aa1dddf68138d6d20' }
  'win64/en-US' { $checksum = '87f080a458ac32c2ab393dfe1dc3f77dc662f1915aa05dc642d877c820680b30' }
  'win64/es-AR' { $checksum = '2c24e6d14bad8bb215f7d561e352e43fdb20e019f6677f3f3895f75bbe302003' }
  'win64/es-ES' { $checksum = 'b8140ae81a73107282b56c69d32811dc1d859e35df6c0d3b618f36f3d2bd358d' }
  'win64/es-MX' { $checksum = '7ab41e34e7b621e47b1afff21a27bea30b714977918a6ba537eaf250c2aae3b2' }
  'win64/et'    { $checksum = '4a57d6cb99972a01e696658909f640247607295af21a384a46664e2eb5e9bd45' }
  'win64/eu'    { $checksum = '1db4ea78ceaeb79f901817b8b36c51e3f610e353c6a6c17e6d19833a101cbc07' }
  'win64/fi'    { $checksum = 'b1b2395ae473372e1dfe49877ac6ff2305e9587772b99efaf91926989e5541d9' }
  'win64/fr'    { $checksum = '4e34fee3884f9cf42af55bec69e5a7b83fac2e364af8eaf764479ba9b1a24980' }
  'win64/fy-NL' { $checksum = '886888326e7ebf91c4b5bcdd87f558c0ae63e9a80fb5424ecc8daa803ec98eaa' }
  'win64/ga-IE' { $checksum = 'c7716d875bc8b6206566d3bf9a59852a36276bd3f66705d6d00dcb60b802131c' }
  'win64/gd'    { $checksum = '60ad0f64bcd261c44c809733a7356a62d0f3bdf872e17a55355c40d3cef536ab' }
  'win64/gl'    { $checksum = '1eeb8c997d8f028134a03b2bb1bc7e684618f97276ca0cd5723c4d3ac3defd8f' }
  'win64/he'    { $checksum = '4d55b8e545ba79d4c825ca11b9e2f135f1d82b66c90a27d12f7a8cd52eacfea7' }
  'win64/hr'    { $checksum = '7fde4d8c3d00ed9345879eb475ceadf80d62d38e8c17971673204781a8b50008' }
  'win64/hsb'   { $checksum = 'b926c8dfe7dd2cb93465b0e1339cac644c91789a315567314f25f58d37ba7888' }
  'win64/hu'    { $checksum = '1c1821563040bb084c3f5163caecc833650fa8e3fea79728d7144229c644dc75' }
  'win64/hy-AM' { $checksum = 'abd4979426942501736abbe9986677989728a72467762a66578529a4903c6560' }
  'win64/id'    { $checksum = 'f1f8e3b28cc2ee9ac2dabeca63ee0336af391c0860b1a4bff9bc9dda8474147c' }
  'win64/is'    { $checksum = '091f96301d0eb0b63fcf8721d45c9bc773d9d851d55fb62b2730365a2454e463' }
  'win64/it'    { $checksum = 'dc6affd0e38abde6d2908b879be3f1e2ae32f0003075115b3409ba99cd2b363a' }
  'win64/ja'    { $checksum = 'bced5d890f3de5f6d2f1b0683b1f4345f5ceb277fa4ca375ec3da91956847f4f' }
  'win64/ka'    { $checksum = '87ba849fcefeff094fd1f9e26be0cebba9e565888232f76ed5e6b97dc74a50ed' }
  'win64/kab'   { $checksum = '22a258558bb24db30b598756d6ff31e407137dbeee38010ceca3426baa873409' }
  'win64/kk'    { $checksum = '2982feaccd7e943ab9c77309a1e924754753e751174c7289f9b5afcb43d67c6d' }
  'win64/ko'    { $checksum = 'da6196ea1b81c1118e311dd79fd23dcd16d5e37bcd328a1e279bb2c820b5c607' }
  'win64/lt'    { $checksum = 'bbde7c5380803e6ee23618a49c38456bf709eccd737f527c23b4d2e871715d82' }
  'win64/lv'    { $checksum = '772d3173eb9c1045694ee90c6d9595ce787ce721f70794346e26491f42c31214' }
  'win64/mk'    { $checksum = 'dd61f63f5389621d47b51f5c610c2ecc78f0029c43f5ec490db5f731db79947c' }
  'win64/ms'    { $checksum = '7e1b21f14afdb91ab94720378cab5bd0c4a5b409c97f8770fe80e9586b9b6114' }
  'win64/nb-NO' { $checksum = '5efa682aaf2bf4da623904bbd4c6c9fd30a8844e0be1d692deaa6d5c61a64a42' }
  'win64/nl'    { $checksum = '4ed700234dfa20dd0f0a442233851ea315ae2951947dae5afb33c46df6281f9f' }
  'win64/nn-NO' { $checksum = 'ad5ab1f7a0446c5ecd62ed8f5f9e395c920a353e69e0483c18c2f77b1116dfd3' }
  'win64/pa-IN' { $checksum = 'ec1de2d7f6898b1db2f6f7bfec1be8992e65c6603a69446cf35a7d57b56002c6' }
  'win64/pl'    { $checksum = 'ea81e7d9fa02fe6da397cefbfb4506cd16024ae2a10818418d893c0667313d47' }
  'win64/pt-BR' { $checksum = '00f61c866009336e40090eaf203c0847210c903b8ab83bc5b977735be91821f7' }
  'win64/pt-PT' { $checksum = '6982aea84bda99d14ce2fea75867bd720a4b4dfc69d94fd1e09307a46a461145' }
  'win64/rm'    { $checksum = '42ec7cc8bd14a5a26c0959c4c4d8df6121ab7d578a821112ce2a525dc67af13c' }
  'win64/ro'    { $checksum = 'e25779a416beb7428399758c410fffbe6ca3d9de6e7c58201c00dcd3f6e4901b' }
  'win64/ru'    { $checksum = '50adcc1bd6e735a1143cb3505bf077fe160a836120f6ccf8d89ca73258364d0e' }
  'win64/sk'    { $checksum = '3792276afaf385cb61fac671d1a42c97e54080b3ce9c35accdc663d95c0da5a1' }
  'win64/sl'    { $checksum = 'dbbf43971fdf884a47b915e3dcacfa593dd5bf0a4a0c04ff1e2c73d7811b92e4' }
  'win64/sq'    { $checksum = 'b7e5f9cbe110512fc354134be459f25a9267c991beaf46b2e9c8177413a23857' }
  'win64/sr'    { $checksum = '1f288f9f1c5b51c2a215e38068ea3260681af289f2f478b5b88a24f96bb3c6a9' }
  'win64/sv-SE' { $checksum = 'b885540f802a75d19e69b6c42f25ad1cd02e60f91c492560adce359bd55087d1' }
  'win64/th'    { $checksum = 'ca3e6d2725aacad42049ea238efc18bb875ca4861ed7f65a603610c731eef316' }
  'win64/tr'    { $checksum = '22781537de271bce1e69798ad2c55315c7f8dbf9a84729d506df0efbeb1d2d63' }
  'win64/uk'    { $checksum = '087fd3e9fd5630051b405c4ec5f47815b6fb9c7759aef6aa08264a6219ec799f' }
  'win64/uz'    { $checksum = 'd3993a35c13d046d09d89b55c826e20662d0a8674285732fe4548216e8f4abfa' }
  'win64/vi'    { $checksum = '177f9d2daa12ad6cdf5e53ca47aed04234d0a72a4b856295fa0b777da0bc0228' }
  'win64/zh-CN' { $checksum = '84b8b3f73b05c272d747c1bf3355f4bd5691946dd2a2697e0a0924b3e7e6d602' }
  'win64/zh-TW' { $checksum = 'c5fc570c4da5dc00f145adea40899d4ff465242b0b9ef34741d69591156a2d43' }
  default       { throw "No Thunderbird Daily $version installer found for '$arch/$language'." }
}
# </checksums>

# en-US is the main build; the other languages are its l10n repacks
$folder = if ($language -eq 'en-US') { "$build-comm-central" } else { "$build-comm-central-l10n" }
$url    = "$baseUrl/$folder/thunderbird-$version.$language.$arch.installer.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
