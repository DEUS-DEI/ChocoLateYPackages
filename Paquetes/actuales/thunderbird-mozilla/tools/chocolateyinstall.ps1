$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '161.0b2'
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
  'win32/af'    { $checksum = '34cfa9fdb780f1d19d8063cb05ca012248f3a2c65474dd13800a35cab15bd36e' }
  'win32/ar'    { $checksum = 'dad1a6b95460126ac9383b4a281748e04d9e754c9527b14408ee3529d2891a39' }
  'win32/ast'   { $checksum = 'ccbe90c60f90898fb99389f8d3f7125d5d60dd05032ff0769ec8798d48f6864d' }
  'win32/be'    { $checksum = '0ca545916a935fea6b0942469c284e70a390fce0b870745ef761a5f9d3a4a854' }
  'win32/bg'    { $checksum = 'c4d14cdc29f01c506ce78d126f177ddb8ac758cf02fb2be8bb3e798904472b25' }
  'win32/br'    { $checksum = 'ea124dd82cf4a7759143114847d7f087c7414d0667604da7ae2a51da9faba92f' }
  'win32/ca'    { $checksum = '78632db2ad2127b57972d6d4f9607472de380e30e15392209950e44f489456b7' }
  'win32/cak'   { $checksum = '1793ec07f325cf706f44dcf14607fb85bdb10a488a6cc2e0065792d707376e4e' }
  'win32/cs'    { $checksum = '4a1107af20d52412ba460d15e43b0e48af2dbd642fce4bbca9e3f1631ea17596' }
  'win32/cy'    { $checksum = '21d4108c8d955fca66a986ef0652b17a89c766a04aae3ece97a0fd69731599d7' }
  'win32/da'    { $checksum = '4e8bff60c5a6d1171febca22ebf28d10ad634c0ba24f3e8c5340b3667ab937ea' }
  'win32/de'    { $checksum = '491c4ce3c666c277fc07831db312a8cf498b4ac22ae38bf4aba8680411c25faf' }
  'win32/dsb'   { $checksum = 'acc705bf51f617272b6f6a1a0d6e8bd581f1bdaeb0544858995eec30bfb3ac24' }
  'win32/el'    { $checksum = '2b12ebbc2cdbcb303b5a4c200ea5eb556a4a4718a3ec2eaea068450075fffe4e' }
  'win32/en-CA' { $checksum = '60119585af85c2187cdc25de67f10473379b08995a0b3e3e26bf14e9256bfa7e' }
  'win32/en-GB' { $checksum = '76fb424213437a3fa52bf09456ca4ee2696145d1de8cc56e71891ab627e24a09' }
  'win32/en-US' { $checksum = 'a3627ac9fe93b4842d0fb166f5b42261b8d0ca3ba2d3e1d3a571f9f3e31117aa' }
  'win32/es-AR' { $checksum = '96c7c133e175405a867083287efc3c955b510a1d2b40027d038987bf18235247' }
  'win32/es-ES' { $checksum = '2ae1ee08e9ef1625ff29bede62b98521420d9006fb27e7dadc04f7769855c51b' }
  'win32/es-MX' { $checksum = '3e0b56fb1b402cf0ce81f313798aba5be3f7678b0f40ba1882cf021feb690247' }
  'win32/et'    { $checksum = 'bf8fd47647ba81c97d3dded9d1165da03195b11f147d815ed5f5279cfe40245c' }
  'win32/eu'    { $checksum = '4114d2a42cea7d52c179deab3cb037158df4c60419ebce99522529166da1c49f' }
  'win32/fi'    { $checksum = '19b3db0fefb28756e3af2bc4bc27ad168b50fa32fb9ecb2cafed381c24eaed12' }
  'win32/fr'    { $checksum = '268235619d2f927f8a99462aa1ae11e722b7e82da168801414fdbfbb850f0693' }
  'win32/fy-NL' { $checksum = '82093007a90d54f69b952a8ef2e2ba1e6e595ed04c29270b432fd801a33c57fe' }
  'win32/ga-IE' { $checksum = '2b7819d71234ff25b721d90eae1979341377f3a555367f4405b9b40e85e01728' }
  'win32/gd'    { $checksum = '87a35ad6a0c938fdaeaf14c715dd87356a1ae534de24ba44c465f4a30785900f' }
  'win32/gl'    { $checksum = 'ea10bd2bfb6567d0c687fa778da35d706eaf469a8636e46b51bfa3578212775c' }
  'win32/he'    { $checksum = '8b160a41d25d80728935f4b7f2167ad098280fd259efd633fb0093733e7a7762' }
  'win32/hr'    { $checksum = 'a55055e51b2674a6ec870d657cb5e4683776a599f60242100830057e72e9bb8f' }
  'win32/hsb'   { $checksum = 'ca601b9740733f03aced72a7ec4d08e261180c4587b2e31bdcf7adaec5994e65' }
  'win32/hu'    { $checksum = 'b1130a13a6928dce2fd82fb8df7afdd04113f8e63b5c2786eea84492fb00a2ea' }
  'win32/hy-AM' { $checksum = '883cc79fe2afbaeefb5f35976c06b2fbc0040bc05c02f6e27ff43fed530efdbb' }
  'win32/id'    { $checksum = 'ee3fd977c69b373bdb5b4ca8e91b9468d4460aaebb266f697aa255a6a27baf41' }
  'win32/is'    { $checksum = '94ddab3783f8a2259201130af2e5bca450a743d675641bc55e5bc28ba6634d82' }
  'win32/it'    { $checksum = 'b75b07cafccd1c88cfd4ee46a52ee1f5e5761ee8fbeeb0f6975e20ddc2c9095b' }
  'win32/ja'    { $checksum = '8de1331df7907ba2578407108ce83bfe3f92d0f9793ab3b1a78eccd420dbc08c' }
  'win32/ka'    { $checksum = '803d3ec855e3dce757d440009160c9f3ddf15cd3fd31543daa0f9ed4b7a9171d' }
  'win32/kab'   { $checksum = 'fad70b54632c29551b6bbeb48a7f3bb1f9b306707ab24409a07a909a7170ec84' }
  'win32/kk'    { $checksum = '8b96db4036b6f2656eef1a5be41b326e942d358f2438c31b71b4c663b475ef95' }
  'win32/ko'    { $checksum = 'ebf8a95f9373bfd4f65aedb76e211a950875fbbdd885713d686173b0a04865f3' }
  'win32/lt'    { $checksum = 'd21a5624719eba4ff4f8cca6731296bc5ac7abfd5b09ed9897b11dbf2b5a52ee' }
  'win32/lv'    { $checksum = '261e38c4edf5be7b3e0b1191ccf55cb771e11ed3350e8077c2ad0a5c3a1132fe' }
  'win32/ms'    { $checksum = '964d8889057199b2608b4a0d23d865bc843033f9d64ef2c2b0970eafde9e2c45' }
  'win32/nb-NO' { $checksum = 'c082aa3f871ae1fa8de78f1d2a34e24d2ff4bb90185842ba8a40d911db169f53' }
  'win32/nl'    { $checksum = 'a005b004a9a3ce6e0d8dd582fff7590e2959b7db33ddf1a085f7a93ff04279a6' }
  'win32/nn-NO' { $checksum = 'df9dc7fd0b7824417a77adae5ac9537b5b1f8b5dd598397ce3dae08bd62d3fc3' }
  'win32/pa-IN' { $checksum = '3fe3ba18ab897d0583b61607eadaa2b6ab4f200573e8a7e3318a95b0dabbf3ce' }
  'win32/pl'    { $checksum = '266c6547a40a9f261970aa548ccbcfb99603c770fafe2084084ae8078cee2933' }
  'win32/pt-BR' { $checksum = '50ab9497f8dd2be7c91aec3471ad84ad1a88034c59f28d330abbbd4d4e1a70f2' }
  'win32/pt-PT' { $checksum = '814d3114bf8641528b51f4535064a5dfcca61f2217415eb2da3b00234c8dfaa4' }
  'win32/rm'    { $checksum = '874b749f2746d48ad9622b612471b2c488d9a1bb731c5af8c7d4884ec21a2bf8' }
  'win32/ro'    { $checksum = '3b49de26ef68afc398afac537b6c7ea8631784e0ee2c3902eabbd33555ecb7b7' }
  'win32/ru'    { $checksum = 'a3e66d48e56671b82887928ef9062c2a0ab2697d29e6ced7e21fb858e7b072fe' }
  'win32/sk'    { $checksum = '39dd9086eaa9089c090fcea3c6af4e1e87861b94089f98f5e5124816c81d19fa' }
  'win32/sl'    { $checksum = '346733eeae4561913b17abb50cea9669f73a6c306e64a4c99bf0d53bb11143b0' }
  'win32/sq'    { $checksum = 'af4ba42436006c0497516d54ab1f8b8356be68cfc5b816782d9f9c33a77cfa88' }
  'win32/sr'    { $checksum = 'd32b39f94ec564d2d7c2e65e3286940f97aa9325fc76f23d06de9b67b651df5f' }
  'win32/sv-SE' { $checksum = '95cdfb911c980b4e1b11562357cf3620509de48e0981cd7d5398834bf84b88ff' }
  'win32/th'    { $checksum = '5796dba4bd639804d8edb0fe89d25b2b9e84939cd8b618e03df1ed78801b5a69' }
  'win32/tr'    { $checksum = '78b884ab0c2836636a87bfb4230e9b5f113548be1cf845ed068326f8f2f0f97d' }
  'win32/uk'    { $checksum = '9f525cbd417123d8c24aa338ec5ad51f16ccb45ba12a5a269f70559f463dc368' }
  'win32/uz'    { $checksum = '5efc895290a1477a1be4ccc10469f834293a1b94e02120426329a1c0dc62a423' }
  'win32/vi'    { $checksum = '06ff32ac1f4c287163b3db04214a944457f51be08ad4878dcebecfb08beab0c0' }
  'win32/zh-CN' { $checksum = 'f3ad0fac97be7fef895c678973256dc5eccb1dc4e07d793151689159592c96ca' }
  'win32/zh-TW' { $checksum = '7b5472742aa76ac57b0e9b0f46318349df65c2d3a5f108116d6d21f3f237020d' }
  'win64/af'    { $checksum = '6e607d1eb44c150cfde8347065dbda378429fa25b4dda376db40565a9666a869' }
  'win64/ar'    { $checksum = 'd157082da73327e78848b62870a833d362f01c398b40b12bb3e23fce7ec99095' }
  'win64/ast'   { $checksum = 'a357b16b5798ef6cf4c8c51003c730420a7717d129b3267f2370f45b31487ee9' }
  'win64/be'    { $checksum = '7d16b2a73124ccffd341e328a4a580cd8b29e70f428732332041393bb8424be1' }
  'win64/bg'    { $checksum = 'e1db80ddb58dc520e0646cc54696129dc3183c2ab0c7790742dbd1cf42107244' }
  'win64/br'    { $checksum = 'ca1e27839765708d23272e8517da1a37f6b4c92f037ebd1bf3a5c1e545270d08' }
  'win64/ca'    { $checksum = 'd8f8f6b8112b7107bc1ce0cc7be626b6c571660a4a6682e296ee69ec60bace4e' }
  'win64/cak'   { $checksum = '5a5197205fb3928750e4d33e784bf88471c11e4074db6f711d0d2c83115e8e90' }
  'win64/cs'    { $checksum = 'fc447cb0c6c46319211678654cf5811902559c5129dc33bdf36eabedf6e46c34' }
  'win64/cy'    { $checksum = 'ef1901b7739e3beceefb93ff106ecfc9991576fe59ac430b5cba3d7446c97a48' }
  'win64/da'    { $checksum = '7c0468a859f83f5af7dc591ab7fdc691c26b2b22299f95ff88fd7d48d81c3f4d' }
  'win64/de'    { $checksum = 'bd85ff640f3c16aee75695fdba710630578b3c8ceaf9e12c177151f7ca43c713' }
  'win64/dsb'   { $checksum = '613d833bee490bd549c0603b1315e307de23d4b71e0c31c6cb2a681734422572' }
  'win64/el'    { $checksum = 'cf97c2be945728cee694c3905fe7cb6e8c8276aae8c7d1a56bc533030e2722b8' }
  'win64/en-CA' { $checksum = '8eaff9436ddd4312a2adca55fff3e909f269d5e1f31d26c1193c2019e5f4bb88' }
  'win64/en-GB' { $checksum = '1ab566a576b37d2282279d339839325827290e57e6fba6bce04e1502a67a48d9' }
  'win64/en-US' { $checksum = 'd72020bd41e842593f4797b4aee3d125df495da1da8eb34f83f934c1ac3495c8' }
  'win64/es-AR' { $checksum = 'bd6beac3ef4c8678388e652b1925ac7af98e2f310118b78f47874774b25e2b03' }
  'win64/es-ES' { $checksum = '01f721d85cf3ac0b84b9d8693977324ed2b13cb5e65e85a8b0411f8e683d2d64' }
  'win64/es-MX' { $checksum = '54fab36e08fc0ebca98acbb9105af8fb21481baccac79eb26b836e331cf4aff9' }
  'win64/et'    { $checksum = '7ed679fa3d6f8e337398b7d9ac2f71b142079d878f44310fec186a2fe5d66dde' }
  'win64/eu'    { $checksum = '6bedf7dea6cde56ec9e312871a7f4ebcf5de99cad635ac9f41cdb9028827793b' }
  'win64/fi'    { $checksum = '79556acc7b1c8f0b82b53360c6fb0c0ba1835c61a19e400020b33aef413d2582' }
  'win64/fr'    { $checksum = '786ba701c33e3fc06cbe349d6f860bfbc910c1fc7a7272383fa6170efbb3b67d' }
  'win64/fy-NL' { $checksum = '1cf7cb616e2e58077dec20f03924bfd13112a4583053d2bf50cdd063ebe9a800' }
  'win64/ga-IE' { $checksum = '104737471821395a47fcbb02fde9ae5afc2c05aa8595ab9525f2f4336fd422a6' }
  'win64/gd'    { $checksum = 'b72265f17e7dacf1ad559549c07c079a7df42a4c78a228b322a74035dfda7ec0' }
  'win64/gl'    { $checksum = '240467d425c9b5593ee6b02421b7af911ac6422f3132196b0d9d37ef8ffcffa8' }
  'win64/he'    { $checksum = 'c6cc540ab4b46f0395719aacc8c87c63d97eb4bb00c794e122cfdd60da5e6b22' }
  'win64/hr'    { $checksum = '8dbf19bff7389e650843ab4c46cef4c3d62e73a5ce9f4c8fb89171f16fb90f06' }
  'win64/hsb'   { $checksum = 'ea7ce3360259e98a1070a272d5050a23356a61d4016af00a915c8c4fd6aedcea' }
  'win64/hu'    { $checksum = '0326d8d1ee66dcb55f42b391c318bda0085855647e366284f464640d5d542187' }
  'win64/hy-AM' { $checksum = 'c60d67dc0f20d39afae179a274c7d0521ea2e973e3b912eb0bdc52eb6c8836aa' }
  'win64/id'    { $checksum = '6b597130d62998f80a695116f8db0cd77f5c95223a991cc4540f9a1d727e2d4d' }
  'win64/is'    { $checksum = 'b886fc6d335b249370021d75004c61c1b54322e72aca3856b521a676d688ad73' }
  'win64/it'    { $checksum = 'aad0405cc276979293040a99ba3b9d49449a54c46bdd640d8f278870c704ba80' }
  'win64/ja'    { $checksum = 'cf195e8d12dcda09955aa75f1486fb96a0c48808f71b04c0c9635ea4037d4809' }
  'win64/ka'    { $checksum = 'cf1bf14b1d18f5eb38a09ab34fe21c58f19c2b8971448b1faf9c40a232732c1a' }
  'win64/kab'   { $checksum = 'cd49b23bca87f645502136a01aaed20c2f84dc729af55ac1234fced52784e482' }
  'win64/kk'    { $checksum = '270b2c41611a03d7964ca37b24326317fc67107a4716c193b37dcc699501a25f' }
  'win64/ko'    { $checksum = '127418558c3370676ce6a58f9f5357666725373a6d48339907b7d4e811a8de43' }
  'win64/lt'    { $checksum = '183d1bb53e38a1434e91d1040ff87802d76a46f44dff7311a32cbfc143e20ce7' }
  'win64/lv'    { $checksum = '25c33e64d90b246b3fab7b1454d11e65334d8a14a26bdded6507c8c6f573e77b' }
  'win64/ms'    { $checksum = 'd4f3cb1a5e68aeca3d5dcfa6008cc907ce4ad574e007a916362bfc860f320455' }
  'win64/nb-NO' { $checksum = 'e3bed4647276d8d2fcc33fd33d60f803f2c202ad7f0fc57b1a19114667aefe18' }
  'win64/nl'    { $checksum = '4491d0e8774fad8e193f58466c036b30215ca2c9e94bcb16b33a6696ab7266af' }
  'win64/nn-NO' { $checksum = '4310a3ea26d826ddf1418d47f20efc107848ec49e09ad24248c002771a9257b3' }
  'win64/pa-IN' { $checksum = 'a6127e57cde301089e9212bfd7f224a67177315b2ccc81136170e0ba8f590d45' }
  'win64/pl'    { $checksum = 'f36ad90defc4728629c7ed3c6b32b600cdc7f40485b531ffd1f36d95c0387d7b' }
  'win64/pt-BR' { $checksum = 'e48248c5e8828aea69200f7c67b551131b4fefd2d5f65fb5bc72d3b45f7f489f' }
  'win64/pt-PT' { $checksum = '1dfbb7ab7668e25793f6662f917fa903861a6f52e4561988ee6c66c40c9cafaf' }
  'win64/rm'    { $checksum = '5a9e65a2bd0ceb30a8e12024f4476b4599e882235ba38892aa3611cead82dfde' }
  'win64/ro'    { $checksum = 'a31dbcf8900430a105036ee626a8ea04b70c9fc0d2c727e9eed03c5d976e59ff' }
  'win64/ru'    { $checksum = '3ca93ef110a1bdbc54217cda27049237b90adf627c790075a7933817101111f3' }
  'win64/sk'    { $checksum = '637231d9290bafa67c42ae529ff2dc540fae5362b314429796e6a7563b88b4cb' }
  'win64/sl'    { $checksum = '47b421c1963c98efcf9753194b21f1ab934b784a915570d0e1aa941586c4a5a2' }
  'win64/sq'    { $checksum = '91f9a71666d007d2d54a14dd45c0f736e2c0be5e71b13f529f84d4b5261ee352' }
  'win64/sr'    { $checksum = '701ae0c1322a6066f795d75e1404ff0713380a704368fc396914d249e9836a78' }
  'win64/sv-SE' { $checksum = '9d639c8bab5623db8ab1d403674ee2ab94952ab81534f9af78c29f6e1ead3720' }
  'win64/th'    { $checksum = 'ceb5d5b0ef01b8e94bb3efca9da57fcbe49dfa0ab6b1827b81cbeead0fba990e' }
  'win64/tr'    { $checksum = '010b91e96045dba170b21fe1a03f3c3450108ce65df843b51130ded5ef15b4f7' }
  'win64/uk'    { $checksum = 'be2ba165d45ffa6f06fba08461cfdfee09975bac93d24f831796dd5bfdef6bc6' }
  'win64/uz'    { $checksum = 'c1f49b6d7d4a64ea0b83fb4e0fb067017cf99667fbef72639159ef956c25aafc' }
  'win64/vi'    { $checksum = 'e6beca491ead79eb4c3c70704ce2f2afb608ed0a0718831a7fc00a1608863da9' }
  'win64/zh-CN' { $checksum = '8145be4379cd0d11a9483887d06be3901b7672a80b165d6ddf837801c0e8a8bb' }
  'win64/zh-TW' { $checksum = '8535e188bc620ab2cb9df8bded7f2eb593dbd277fb1bcb17fa8b70e7631412c2' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
