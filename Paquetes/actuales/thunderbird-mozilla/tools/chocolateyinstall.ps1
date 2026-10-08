$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '158.0b5'
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
  'win32/af'    { $checksum = 'f205f517079f4f408a97b0fea7256914dc7b5187be91f63a05d9e12e13e2b16c' }
  'win32/ar'    { $checksum = '4549f359b37348c2cbba45946c98b015832ba52e526ee4c18b44498377e9653f' }
  'win32/ast'   { $checksum = 'b212ecd3d5adde41d2e47cf9097686a818457650c126e1822bb37be8dd51b086' }
  'win32/be'    { $checksum = '5bb16a4eed16c809cd71bb51c2edb51abec53768df5accd4db5554fad5689911' }
  'win32/bg'    { $checksum = '54275e453d829e22428069887169f54ec0c1dafe2cb5fd38f4975934ab86035f' }
  'win32/br'    { $checksum = '5d4978b087248095aa21181f32f049611b44c4c7d56aa1f577a729234ffb2450' }
  'win32/ca'    { $checksum = '12f46915e368da19b22b06938b03f70afac4f048cc6fa0036efbe3f7fd384bec' }
  'win32/cak'   { $checksum = '41091bd9307ccb9976255c2dc16ccdd03de693c9e5acfefba867ece4c52f1af4' }
  'win32/cs'    { $checksum = 'dba3ff587835ba433a9af9bd53308fbfc643feb4e310818334e0470788594c90' }
  'win32/cy'    { $checksum = '7b24665237d323a824a6a3da44e3027bbef12ced665d065c1888a090358e38e3' }
  'win32/da'    { $checksum = 'a2e63973ad0af03d41b589b87629deb91002dbfc6865587a366c2ab35e3274ea' }
  'win32/de'    { $checksum = '1f27882fd4883fb73b89f47a5b832c8878869bb4a30192b39f3e41d7eb5c5617' }
  'win32/dsb'   { $checksum = 'fa4ccacac01021ba5a34221296fa332a2504e096e8a33f60d86591bcf6c8e4be' }
  'win32/el'    { $checksum = 'd4dbc81d256dbe5da9c8e4ddfed604bc6fd8ae24535bbf258faa083b35dc232d' }
  'win32/en-CA' { $checksum = '8e1630a5fd59b00cc299f049f8e7dfbc44645cd7103f0616fc093bc1af732368' }
  'win32/en-GB' { $checksum = '5098c6bcca8bf6c63abbef2c8e24ec7cb1666ef7180fb90d27dec2f603f2be5a' }
  'win32/en-US' { $checksum = '9ec58ff3e47e9274a7c1ee4719acd3ec93e28e81a1daefe67f487a10bdaea89b' }
  'win32/es-AR' { $checksum = '7256359c03490a0d3f82a2616f07dffef1f52539457e3d2a1e630fa439bda6b7' }
  'win32/es-ES' { $checksum = 'c78fccc43ef2ce8d2ff7575b952763ed748a0cc14568721877baa945c2080a60' }
  'win32/es-MX' { $checksum = '378541d2c76e95ce753728a024585a10612368453f6486f4491d1d8452df28d7' }
  'win32/et'    { $checksum = 'c7e7c59c9836cda57702ac51a47400ad694c518de95948a2c9d599839dacec1e' }
  'win32/eu'    { $checksum = '302a149857f6f5c2c9370b1209ec728e5713e338170fb230c784a35478d508f3' }
  'win32/fi'    { $checksum = '55bbe6d3fa2670e8c6ad017ea110b81f30512e6790607837d0ce8799adcddfe4' }
  'win32/fr'    { $checksum = '532ed639082880f56fef15e9eef190ca73df01a6a790a8722c5adef00f474563' }
  'win32/fy-NL' { $checksum = '880fd7a5af41b18ad745d28006881598be153717ebb8952750830004f1428c1e' }
  'win32/ga-IE' { $checksum = '0b15d93d197d3daf2f008e87a9d4b5bdfe07cf4dea9eaecd772cea5a732bd65a' }
  'win32/gd'    { $checksum = '1f0a13be166859eb63aaecd4c5c42f5a79d06c26c0684b11655ecbfc54fdeddd' }
  'win32/gl'    { $checksum = 'ba6593a91c40be2dbc140165d3c2b18b8a239ae4160c4091de39ab0a36f335cc' }
  'win32/he'    { $checksum = 'e91af0ebe1d1809fdc0602600e5816045090b4285ce35dfd4782d8e65719381b' }
  'win32/hr'    { $checksum = '2ba882d6329fd833f956b6d4d0e4effb2dd528a6cfaf746dfdd0b6467132566b' }
  'win32/hsb'   { $checksum = '63362fec2ea5a9c3b488717402fb017d556f9f09f8ff0fde26e2e9c05e4e51e1' }
  'win32/hu'    { $checksum = '3af4b93a8f21d32ec8850d09cf86401b8173839754f0ee0d73b16d8467e3ab03' }
  'win32/hy-AM' { $checksum = '08f3e8a83c60ce77b0cf2f3e87f8442740ce7c7b96fda8422c3d207940a9c546' }
  'win32/id'    { $checksum = '4e652f72102481e034fd9d6aa9825df82bf1362d2343513b1ae93a494fb481db' }
  'win32/is'    { $checksum = '6f4dec65275f884f095051b0945eeda7ea233e88ccc06dba2d4085528ca5775f' }
  'win32/it'    { $checksum = 'c04601fd4f792715ca717f0c37c73e365a14dfcb242e1e8c94d8665815ec8932' }
  'win32/ja'    { $checksum = 'dc805e6821704147a2b4316dc133cc6589488d9ac01202862385e72bcd22d52c' }
  'win32/ka'    { $checksum = '98f6e760c940e7dc87e3d1ee41e9666216c2a58f462e8aedc4b0fcc863102455' }
  'win32/kab'   { $checksum = 'fe5bd9067c8f6e3bdebf2a16611d15dc2463ddb3678ed2da12056e501f7bab62' }
  'win32/kk'    { $checksum = 'de5d2fc6aaeca471b456af40c5d7f7d053af43aa6fe53624b0ec328440dee3ac' }
  'win32/ko'    { $checksum = '6afa8a5fecc9546d94e047de7178d7ad253067c60124e0c262aa126e1642d38d' }
  'win32/lt'    { $checksum = 'a1003e0dfce83d82d6ca148812ee10c8808611805aa8ffab13ccc9e3647cb9ab' }
  'win32/lv'    { $checksum = 'b94711bc396ff3e31a925bbf478d9fb13bbffe4bc1ea42388d9ea944b8bcbfd5' }
  'win32/ms'    { $checksum = 'dab3aa4752ad2c062d84a1b81d85226927c91f157647f40de3a804322f855c32' }
  'win32/nb-NO' { $checksum = 'd252734a90f90c60ca536642866e96529dfa31747660360c437a2d57c2345d22' }
  'win32/nl'    { $checksum = 'c60f290ec29aea2d7d936fc3eace1e4c6826587f51e8009b609c9ce9e9d791cf' }
  'win32/nn-NO' { $checksum = '26c62e553c4d1135027974a5eb3492777ce9f9a01e28dddc0c97ffe4823c7b0b' }
  'win32/pa-IN' { $checksum = 'a54a578d66dd2b79a8c252a02e6fdce1cb20930fa691ea52cd074211dfd085f2' }
  'win32/pl'    { $checksum = 'aa11743598f1cd9d2836bab559d91b7323e16f927a905900e56c386715e9add6' }
  'win32/pt-BR' { $checksum = 'e96f42d26da0939f3c17ed1bc192a6a27a2c8ccafe605ddfbe859c3d05e45b12' }
  'win32/pt-PT' { $checksum = '71ebe6fcbbf230bde6e8857759f7a37bf87efa27b4cb975f3a5700f4983a4cf3' }
  'win32/rm'    { $checksum = '46ae23dc59a545ecbd0d498c5e35c8336d4389068ded60859f9368332005c314' }
  'win32/ro'    { $checksum = 'f86decc9a583bd3b6d7b3fa2e5f938690a0aa4f95a8df38c3f196baaf2ef2f3c' }
  'win32/ru'    { $checksum = 'a4448f3276de1a926e87409f770cbb3069102cbe05633deaf610f005cffb6cc9' }
  'win32/sk'    { $checksum = 'd59ca7794a9a502518ea8b97248ff068eae74a6674e6b42ea0baada7804c1779' }
  'win32/sl'    { $checksum = 'fedceb11f60764f3e9880ddccfdd1cb766db6b9cc5ca4c829195ccfb4f50b3bc' }
  'win32/sq'    { $checksum = '3d4ceed4e2a83bfa6f28be18a1ea83c5a918e7427a599d160ad3f97ac20d3e4d' }
  'win32/sr'    { $checksum = 'f5f18a51ad8d68158516c359e76fd0813f74b1dc36418cee4b70c50b84a1b900' }
  'win32/sv-SE' { $checksum = 'af6d6a4177522e56657ca2c3a2ee3afe819050f5b8097f30882ab2f9bcec98f2' }
  'win32/th'    { $checksum = 'f3a0b3e0f264e964b63a564fef9349936cb6b79c48167d929ca6ae674e9bfb5f' }
  'win32/tr'    { $checksum = 'd7b1deac9194e370a0a2907e294f22f70be58154310f148c1df6674c3bc2b2be' }
  'win32/uk'    { $checksum = '6db101d235d948846b42b874d3c79bbfdaedae3aa49f92da49ad5e310ce456d8' }
  'win32/uz'    { $checksum = 'dee9c15a08785d9f5b802f1326cef0030ad39bc139087cb8cfaf396ef9412179' }
  'win32/vi'    { $checksum = '1160b58f45474eaa007427f66a2c5e092b599a7b201c2af5dcc44150e883cc9b' }
  'win32/zh-CN' { $checksum = '9b24294514a8aaaf92c5c0f944f2d9a607418eb964d46b54bd75da0f3890acc6' }
  'win32/zh-TW' { $checksum = '3de0b9ddb41ad6bf7dc2111a38eb5974462ef4f726c324679f6894f68c20aa70' }
  'win64/af'    { $checksum = 'da242fdca272cc206ccbaef2a9f7cc5be0f5329fe58d917653520615225a32a9' }
  'win64/ar'    { $checksum = '78010e2588c6c77e7fe92a292f7ee8c1dca152e597f4c9f2fac4122ce314be3e' }
  'win64/ast'   { $checksum = 'cd5c564b7a0c068d4d022876b07657a2e7583055119e2bedd9170a6016cc2db7' }
  'win64/be'    { $checksum = '5b3c75c6cf08ea34aafbb827c6b97a9b3424693b187c732bbf881832dd8632e4' }
  'win64/bg'    { $checksum = '843f9adb464292848558b35eadef50e7a3da3791e2f910a1f36e9ef09ae96f2f' }
  'win64/br'    { $checksum = '023e40f4948dfe6c1a4f5e90230a6c99a3b724f196be37c30f95f471bc611f47' }
  'win64/ca'    { $checksum = '9be76be407575b659bf59acc219b5172d51722c51fe839386a95d786f014d896' }
  'win64/cak'   { $checksum = 'f51ca9f3d9d34b419503536dda1a7113f10807fa15d12c65d92a3e091df4dfed' }
  'win64/cs'    { $checksum = '6740e65ebbafbd0fc800a0bc8ca2c62221d3a4f40bfff57dcb1777fce21bda50' }
  'win64/cy'    { $checksum = 'a69126fabc390018220d43eab61ea038199714df67070c9b321ed2b14529fee6' }
  'win64/da'    { $checksum = '31a4a73824bd33d4df0984e91fdcf43ecdc13ad2af8ac5bb2dfd900a3fe0a970' }
  'win64/de'    { $checksum = '37c3f2919519cd49ea5610f913b5d9ab626c49a509982be8744cbe0d56d0a098' }
  'win64/dsb'   { $checksum = '79fc06c9b7b5a992fdf27867f6a7ac32d34ab2071493cefd7511aa8c3fc82276' }
  'win64/el'    { $checksum = '77f4993ca227cbbadcd30bfc920dcdfce42847a742811d2ccf5f4620c2fbb202' }
  'win64/en-CA' { $checksum = '7273257e82128ba6316a6427a3799726f63aac217531ea9fbdc6a4e26df2ff8a' }
  'win64/en-GB' { $checksum = '0270130a29c104f69b98a31661997d3415390e8cd9c8f51d83e8f5e8de878933' }
  'win64/en-US' { $checksum = '223fc63ca340efaf895710fbc6a392da38f55546f428d9befeca40e04ee890b4' }
  'win64/es-AR' { $checksum = '017ba8c7871bdb5e9864b3f4c98e5a0c84da58fff6912757eec6be9c76ba3969' }
  'win64/es-ES' { $checksum = 'adf81ed2758b4fb13ff15267f1e43ef53dcc2b81b042bf1dae58271a2cdd2c0a' }
  'win64/es-MX' { $checksum = '019e5f5d50c171d7afd30954c91adc2497b1c159ddd086b3eee947a19ab1a66f' }
  'win64/et'    { $checksum = '0919d155d92fc0b1f9b590a1e42a25309ca1beafc90530a76d40d9a43abbe7ef' }
  'win64/eu'    { $checksum = '647fdba03d96abfbf29353b1a89469eb5263d72f9235eb56a37389147e047476' }
  'win64/fi'    { $checksum = 'bafc16f7cbc455acf13d369959d66a30cee0119f8accb49f07bc05363bfb9989' }
  'win64/fr'    { $checksum = 'c0f13e907cf89a5995c49cb05c3c5c0d7d902c809cadb1b0f729aa80a9a7f93b' }
  'win64/fy-NL' { $checksum = 'cbf1db687a719e37a43f68edc64c412e0d43285090f8a24f343c8eb63610abea' }
  'win64/ga-IE' { $checksum = '0ad01a9c2c897f1dfad7e9831ef27d4e256591207f3ff3282c4cc9dbc3812fd9' }
  'win64/gd'    { $checksum = '851e0ea5a809a22800f3db7efaf2a5dee7a437bb6fe0e32517032acbae5cb1dc' }
  'win64/gl'    { $checksum = 'af142b0fea73df0ade8d7cf95ce1a42acda31ad3870c44de33fa4cccd1a91c02' }
  'win64/he'    { $checksum = '1d77eb601f7cf4c62ce610a81481c1287fd49c1f6e0e32e554a5eb033c9f31dd' }
  'win64/hr'    { $checksum = '793f61d2ab5a4d33189c446ea2dcc4f6d1882a62643bff5119f5acfef9a5ab0a' }
  'win64/hsb'   { $checksum = '4d6ce855cc04ce7ea2ab2820b59ba58ff455be1121e2714db0f190079102d671' }
  'win64/hu'    { $checksum = 'b32d7bee6276f9e08580ea365865a99361c46839c0d5e4f9b05418af626d6e6a' }
  'win64/hy-AM' { $checksum = '038140490f14dde7b8fe6d246d89a91369655f1fa33ba9a3e2df3b396a98425d' }
  'win64/id'    { $checksum = '54fe2003056ea035da5c72eb9b6fb3c0b1c87030d4ecb13aea2403c93b2eaea0' }
  'win64/is'    { $checksum = '02dbb2e8d096c84fad1d73659a0ddcbfd8f24dced25253d1976aea31acb799cd' }
  'win64/it'    { $checksum = 'da4589ae865801e57dbe6b21c7c69aefefdb23cf75151dcaaf5c866a4cb0365f' }
  'win64/ja'    { $checksum = '9d179aaeb9170bee6dd9c4c880c19178d3ce4218b8077e3872497f72ea1f43a3' }
  'win64/ka'    { $checksum = '81fbeed3bf256be4cf2a400a5ef3b5762fc027df4be3e66883bc68c968845cd4' }
  'win64/kab'   { $checksum = '48f0c2be08305b128f951b8b2fc67e3acb3745f309ea0563cab42a15ada1c745' }
  'win64/kk'    { $checksum = '4bbbbbc5ad3121f6f2f93dc45631ef1ca60e0a7037964246a9529839ed56f272' }
  'win64/ko'    { $checksum = 'a3f3b804369791ab6f25eba8c8f89bec41a5e656b826838b5ac0947e967f783f' }
  'win64/lt'    { $checksum = '40aba1c21e3e168a8a7226fb60c415a36ea5baa9d35ebb655889e9c6c1ab724f' }
  'win64/lv'    { $checksum = 'ff1cdcfade2c1ee036c404bbfec9782c1b08d97852f4bc016c0150d1db67db5e' }
  'win64/ms'    { $checksum = '51c0b6ebc007ec4e2c6e152d428716626ec70d38d8b57957df2120542e91bb97' }
  'win64/nb-NO' { $checksum = '306f6e4a4e5eec136c6c9a91a822851b26b77a89945b02aa904bb041ea71e99c' }
  'win64/nl'    { $checksum = '5aa87d72520f156ea8382b37a4253375324b6b39ddbc377eb1c603791e1f1360' }
  'win64/nn-NO' { $checksum = '3db7aa09064274e2a323a5748a73de06dc324309e0074607079cc402cc58688b' }
  'win64/pa-IN' { $checksum = '838f3930d1db006976bb9d6f96070dcd9f9f81160701295b25242ce8da6a04fa' }
  'win64/pl'    { $checksum = '7c8b717d3cbee70196073dda2326e9db539fcd0e21bacea6b71a6f4476dd7312' }
  'win64/pt-BR' { $checksum = '835d171b3e7587764f71c0a4f92ac6902c6234f184e86ed406369c681d209682' }
  'win64/pt-PT' { $checksum = '4b323a79dbbf2dbea7facc6daab06678238177c67124c5a08ed5cc37be101ad2' }
  'win64/rm'    { $checksum = 'bfe8f0f9f7d0e4e5bfd981ef12d10a631f670921c743ef84c9201732eab3ccac' }
  'win64/ro'    { $checksum = '7591795aa7f9a89015b9f517e06146a5bbf2723129f1f6178f67c72285440482' }
  'win64/ru'    { $checksum = 'ee4a4aa169b7b6ab0e5d8c4fa4f9f4a257fb4bf0c42ceb033083a58ff5b182d1' }
  'win64/sk'    { $checksum = 'fc38661a633c0c8978a90536b62622e4a008cc523b7eb779be4b6cf67caac774' }
  'win64/sl'    { $checksum = '690a9ef59e2c475f43638250b3cff18bf929e6c5ce9f94285cee0da14dafe5bc' }
  'win64/sq'    { $checksum = '6dd2aca47932409143659842b5f3fa8eeff8bc51b9b6c844b61aa5e272c1cd44' }
  'win64/sr'    { $checksum = 'e2f973938ba052b6c4a814636e2fe4c6b25e4d9dc0fd7f5f53f211f374dfdfcf' }
  'win64/sv-SE' { $checksum = '6200c7f7ecc522a91380d84eb5c0f14ef9f2c5e9b39d021c085b95a000a0b1d5' }
  'win64/th'    { $checksum = '0b4dd4d6f9b46c726cb9292ef2ca153fcaea1435175a2fef53295d9debb8d49a' }
  'win64/tr'    { $checksum = '89ffdcd18c120a0af2dcc8d0c9c3dbc67e909d8014afc4f05d569751874104d4' }
  'win64/uk'    { $checksum = '34fb55e4724409bf62d620367a8abe3a5d4fece05fd77be7c78388ec240d4c34' }
  'win64/uz'    { $checksum = 'ed584ae8cfc8f3561d4d007e8b202aaab56d93ab90747b1aff5b9221f90056ff' }
  'win64/vi'    { $checksum = '42080f45882085f558a11582fc5f01debceaf0f197db819a5b1b5b21abf698de' }
  'win64/zh-CN' { $checksum = '7944a3f1f7bacdab2ebdd3eeb05e1ea9a7d556bf55060b0b539adc1e04e8ff71' }
  'win64/zh-TW' { $checksum = 'e0534e4b894795b14b04301f850cb578e94d2b9fa30f7c0196c9df5397ce09da' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
