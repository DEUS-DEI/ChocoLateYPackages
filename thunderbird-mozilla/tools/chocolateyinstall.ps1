$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '158.0b1'
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
  'win32/af'    { $checksum = 'fadc40912c36c8acaff12b1f4a2b0d4071f4f7370002c15d26629490c7e9a95a' }
  'win32/ar'    { $checksum = '987639f40e0a08118b02e866152e9f88c2defa77b19019f9941152716990fd02' }
  'win32/ast'   { $checksum = 'e9835e0d2886e40f891bfacdbd264f30350719c4cd25c6710a8f47889d7520de' }
  'win32/be'    { $checksum = '6a54afca480562e54dc43e86bde2511cefbed08f5e3e3931a6d9618668f8638a' }
  'win32/bg'    { $checksum = '63db996222cc2cc774261f49070d502b79ab28522e988d504ed106e0d4b82f47' }
  'win32/br'    { $checksum = 'fb9408fc754193bb7404a3501fb42193e7dddda33ed83b6b29393aee3c43e8da' }
  'win32/ca'    { $checksum = 'd0af68083a26fd55120a09bd3e9f9ef442092678a6585bc553d0a24080424140' }
  'win32/cak'   { $checksum = '78a74170696d6e2514de79bca78f321946a45fdbc9ca2c54ba2224ea1bb9a5f9' }
  'win32/cs'    { $checksum = 'e33b1196b4aafb0d2110acd2b676ba5d141298de11dab115b2e3f268f046350e' }
  'win32/cy'    { $checksum = 'abbe5a294232559cfb5bc8aa6ac6e4561005bac1116614f749935607124ff703' }
  'win32/da'    { $checksum = '1d1e5bc9f98cf2bd29ac3b7d0e5a05f6a395c474a91212af28aa9ca251da0dd1' }
  'win32/de'    { $checksum = '337a44c476db6fc07ed6670cdfd5d639b4126db16dede7af2e87eaed9e375853' }
  'win32/dsb'   { $checksum = 'b58a9d7d13fe28cce6fd5ed128ac3a7bca52ea0cdd568a797d3b50ca746ca0e4' }
  'win32/el'    { $checksum = '43d8c458df5f3d6bcfe68d20295f7aafe9d6f6a368c49b99d1545a7cb0d4d720' }
  'win32/en-CA' { $checksum = '2b438dd7ac0e4f2f53c7895f28d339da50af7802b749fb5ba3c85551927f0c7f' }
  'win32/en-GB' { $checksum = '4d8770b913be73b470f8a25205b767edac8d2701b5a77e468c7c91c55199045a' }
  'win32/en-US' { $checksum = '1a7a4e64d615fa827ac0911c6d7fa6dead837b145a5d6a1896b1323126595ad4' }
  'win32/es-AR' { $checksum = 'bbb9d5cfd324f0df87b2f6ce15601bd2066a33a06a6881b948e767d70af9d0b2' }
  'win32/es-ES' { $checksum = 'f1611d8dbd5b924cd32da92bbc7fdd85b9d0db0e7168df49c79745877805b88b' }
  'win32/es-MX' { $checksum = 'ad6f69c3fe08fd27292eb864e0ccb7386ff313023a1938b39d7da96b71628d6c' }
  'win32/et'    { $checksum = '49d760cf6852e242d5f0ff0064edcb5ab232b9c48dae8c9ceb97b11e6e4d28ca' }
  'win32/eu'    { $checksum = '246dc2d4406b3794f2d8e26852222006cb9733deaf3f8891e3a50162f47eda38' }
  'win32/fi'    { $checksum = 'e606970b443eb92206a7280645feaf93c31fb0786809e9dfc9306550bebfa517' }
  'win32/fr'    { $checksum = '30bdd42df5a41696d194af43199cdb499f8b18ae6d526c87b4bcc5ad43cbdfc2' }
  'win32/fy-NL' { $checksum = 'bf9e3a143ddfa73f80762cee2021f1fa64ee979fc3a8a4b28ce09bb5f37c3987' }
  'win32/ga-IE' { $checksum = '6a61d8afbdfc77b46a8b898c57e7044e8bda280f5e965688347b5aa3da287aed' }
  'win32/gd'    { $checksum = '13ae60fc870d533c306b499ab2f15340ea7584f9f97a4fa5a4a7f11a9366a9dc' }
  'win32/gl'    { $checksum = 'c6a6ca2be3c6b965414e1d7bca780c75ea7bb2e56a08bd4b3a3d37e71faa8ed7' }
  'win32/he'    { $checksum = '02445f6a4144928e51d804e44feaa588a150c74d57dca2172a668f79e54fbd1a' }
  'win32/hr'    { $checksum = '160cb4e684007a9a3752f72493a42b9e7694bc0de8578abdee5475790e6ae0a9' }
  'win32/hsb'   { $checksum = 'cc0d30470eba282791f83e144a8a594e15a3f95a9f5a671f506eddd4052d04f7' }
  'win32/hu'    { $checksum = 'aecc343cc71aad9689a9a4e522ba48208c68ff2ee8705b139950a8e58eb0bbb3' }
  'win32/hy-AM' { $checksum = '75b1788b2553881240b27d94b7ff82cc4d8d49f82b8b6298b953f0d8b05373e4' }
  'win32/id'    { $checksum = '49f0284e65cb3dd0e97462c4797749377aff8690057e5bc9f32cb85a19a60303' }
  'win32/is'    { $checksum = 'deca0b6598ea9b751ce2aea042910a82328ac4e662fcfda983510e82b420aac7' }
  'win32/it'    { $checksum = '007e34320007162400d6e15c4047f3fb9c3a54fdf9c26b55610425091042de0e' }
  'win32/ja'    { $checksum = 'bd10fe29532c677bc4de08d22670c0cd546cbe21d964f8968fb651c92e22343d' }
  'win32/ka'    { $checksum = 'c45737567d0fdc52cd3aae03a0bc8153ff8ebe442e7985fe8913f364055ca094' }
  'win32/kab'   { $checksum = 'bee366626aa3f72b0e163005cb71e702903757c8003fc409b41ec0968d27a0dd' }
  'win32/kk'    { $checksum = '5beaa87cd928a8898d39bfdb84faeec20e0717ce2fee6487113cd01b12cd9d31' }
  'win32/ko'    { $checksum = 'b1465f360c21e55bae163550f4bd57d9ef20e423e057a1dcc1811c4504a941fe' }
  'win32/lt'    { $checksum = '887d53770c3eb81a33710e4bab71fb1a8569b138a2af3da1a824f091b6fc316f' }
  'win32/lv'    { $checksum = 'd275062bbfae2ab246be60cff810ec86271fd160d0cbe09a08d85b5ac54f2343' }
  'win32/ms'    { $checksum = 'caba679f871c8f918214455d3b1fea1f20b86649dfd624789ee91a6aa3e48e1b' }
  'win32/nb-NO' { $checksum = '9b6925e9fe07193be3b06cd39c4c9f1a2f41716f85a5059648a9215b0e2f450f' }
  'win32/nl'    { $checksum = '4c815cbbb73200b2fedc61f2b90d3fd3bc106b8535b4dc5f86d7a12976d05747' }
  'win32/nn-NO' { $checksum = '56f049e995a76c9343e2d04ed3caeb5993d43618bdd2899002a8cc658bc54a50' }
  'win32/pa-IN' { $checksum = '09d29d4755d1bca08e5ecbc16a8e88b29ebdfe34a1215dc3532e62e6271b6c5f' }
  'win32/pl'    { $checksum = 'a85f597c20798eab80f2d822514c459e97d14c7c929030bf8a7f73ef50f135c5' }
  'win32/pt-BR' { $checksum = 'adc3fb5954384155de943e50c59120366c83055c670920e77ac437947105c251' }
  'win32/pt-PT' { $checksum = 'fedf969a0845ce11ad316cd3c3cf6c4e23e94aee774dc02bc1a0dd5ba36b649f' }
  'win32/rm'    { $checksum = 'f80de27a448b6972dc98c79a35fa83180186c320974dd40fc69a1d3d93ba1cee' }
  'win32/ro'    { $checksum = '55ea638d77dac18f400fc63fab13cf94e923c3d7edbd32cc289b3d782e8f1397' }
  'win32/ru'    { $checksum = '56251c6ac66a2c5cdd1b39fa193956924adc4e726aa380f862b3606165529289' }
  'win32/sk'    { $checksum = '48e8b7ab8dbcff4b702058f03c8aee2729c67eaac5c42d379fbd8e20e0de4de5' }
  'win32/sl'    { $checksum = '4ba838a8f45191d0a27fcdabdef7566b96a875b73b013ec91d7ba4dddc4e95cd' }
  'win32/sq'    { $checksum = 'f58a4a7c5b452c7c08809e0552571a3a55d098a82cac1d0f52b66fa35323c461' }
  'win32/sr'    { $checksum = '582f55f8107c40c5517c3aad8142a36aaacccfce0692ada1f2ba8dfae729cf70' }
  'win32/sv-SE' { $checksum = '9aa8d34f8f0f321e5a76f579c10a968010c47b1e3621056763fc3c6405a9443d' }
  'win32/th'    { $checksum = 'b8760caee52d5cc8c4abb378389e9827c6977cb4abf1fd8cc8436887d9d1ba88' }
  'win32/tr'    { $checksum = '68e0952fa3184d984277bfef284f8cd0438d15be5425ce5e173d1df1b688ccb8' }
  'win32/uk'    { $checksum = '89796bbb747c02a893e1ebc8d1865c442afafccca494aa210e9fea387e7b10c6' }
  'win32/uz'    { $checksum = '8e5ee5112ff4ae477d482320e504acd72f7ec0923f86f3ecf21e3d1ff5670e8b' }
  'win32/vi'    { $checksum = '1e7f4d5011df63ba70af60e2ff21efd6256b2345386590e1c05cd4c43eadb0e5' }
  'win32/zh-CN' { $checksum = '095a73c14060f25925ea01edf58e123cd80570abed06e84fcb025b8285154203' }
  'win32/zh-TW' { $checksum = '610e4a3e8f70f8b1d818f9177684d69154d57c321c00898eeb28b658d6c4203d' }
  'win64/af'    { $checksum = '77ecd1e7379a2a56e100b2f1dccd1940bb1fecf9c87db56938e0b49193b734fa' }
  'win64/ar'    { $checksum = 'd6edf63f149865e4c9d52982490530b1c4d41c782796fc9e32c75441092f3eb2' }
  'win64/ast'   { $checksum = 'd8319e5969a5480ddb23dd3767c5956808a8906971173438be7409265d560294' }
  'win64/be'    { $checksum = '52b281e7b2a222bac13335d39407f8629cf25a002eaea3eebca135a9155b57f3' }
  'win64/bg'    { $checksum = 'f94658ed995c10cd36cd85e16ded7f76cb5657988cc22c3976795cf0cd3fcab6' }
  'win64/br'    { $checksum = 'd1299836676a1c451271b4afe1f2de21ddddb5bf04fb597c3beab7f7299210e4' }
  'win64/ca'    { $checksum = '93a107f89cc4d9ff7d6f24d0087146ce50dd4959db4e61b5a974808f041d17a4' }
  'win64/cak'   { $checksum = '7a00f6f3a4840313d0ba4a9c6758761dbc1aac60af44d305b5a6606108707ed2' }
  'win64/cs'    { $checksum = '7d6c78052f3fb14d7c0fada35dd63aa3e2648b4b0deb631bc1ef1c81b86391ce' }
  'win64/cy'    { $checksum = '0c7d8eb51b43369f253a616d4a9a3f4107f1a41e3e47dbe77524fb138cb12d8a' }
  'win64/da'    { $checksum = 'a6d98cec0857e348ac06a1ab55cf4f7b946c99296b2551d1cf3fbc0e6209d581' }
  'win64/de'    { $checksum = '6cdfc2820236c4e8a7bb1632bd254699be997d8a82b3a0068c46f7449ee9cf6e' }
  'win64/dsb'   { $checksum = '0d0b7db1b066b4887c560cd23536b02c444303277442b5484dd7855eaca91c54' }
  'win64/el'    { $checksum = '0bd1a86f9c83fba853976d6227a9f310b66af8e456bbe40ae17303833528fd3d' }
  'win64/en-CA' { $checksum = '25b25915caa3b666bdf8ab904fb930508d21bde8d554698ec4b0aba8b4303ae7' }
  'win64/en-GB' { $checksum = '6340ea76d8c52003f162bbce1206dfb14d91c0120edde954be176fbfb661e1ad' }
  'win64/en-US' { $checksum = 'a8a4614a25ef1be15a99aff109b6446a2c4a69b776078a4e5f7cbfcc20dab703' }
  'win64/es-AR' { $checksum = '5dde3d6c374c1446378b5d540fb23d2aa793c027f588eb29c4ec932697ee42c3' }
  'win64/es-ES' { $checksum = '3932f3ed1caa1e05797ceb6009dfabf929797b8d214ce8c9ec09037be4383726' }
  'win64/es-MX' { $checksum = '093a3820031b8bcb0ae5c009d083b6cdab9a47ce99de834678685da3a35e1440' }
  'win64/et'    { $checksum = '071dcebabb331bda4630c08b7d08ac1457430f8ffec5877e033634bcb803fabd' }
  'win64/eu'    { $checksum = '79b035fbc6bbd895767bc87f8bac98f365e753e4988cfe7a174e7d117b7668de' }
  'win64/fi'    { $checksum = '737b59e05f35319a33e6eb94f5391140b39a44fedca2fd828a88197077d061c4' }
  'win64/fr'    { $checksum = 'db143fc26a2ad23d191deb85f54fd2d3b4fb821c54521a68c8709f2d39d3dd1f' }
  'win64/fy-NL' { $checksum = '3a6de896534f6c8c9e700828911f7c4a9bb2072b1b16e78961b629be36809fca' }
  'win64/ga-IE' { $checksum = '93a95f35993b38634c1493c12310989d05b176ffb0f80f4a935788dcf1d95d6d' }
  'win64/gd'    { $checksum = 'c366be41ccc69c8f4cf9dbb4e7214b070f229df069895f30783a62c0fc2d5d9b' }
  'win64/gl'    { $checksum = 'be04c15939b30229a4e52cb1e5914e28e7653e2649df7dd65a6d71ae709b9b48' }
  'win64/he'    { $checksum = '59c29ac81c6445f0d3b0a99bddfef07704beb6f4df170d5af047905e1786dfef' }
  'win64/hr'    { $checksum = 'e8f54a109bebd7daf8b0d705664d81aa5b3c49189d12e3139157ef662a9daa38' }
  'win64/hsb'   { $checksum = '9628809161da8710dfdd5adbddbc3e6f9907390fc572b22b5c39b86a2b3320df' }
  'win64/hu'    { $checksum = '7dbe73ba9caf90da6b7a1809ea27057ee0555333c9b87e369ae1ae794f3cca4e' }
  'win64/hy-AM' { $checksum = 'db9673bbf00b026779f34c88198b0117764a53d7b833473245ca154902cd8ad7' }
  'win64/id'    { $checksum = '124075203e4362c5bece0787272bbb25f6a29c81eee374fe53861d63be3dc15b' }
  'win64/is'    { $checksum = 'e4aca91d3041d131b4d0920a95376e5081d41bcfe8311b7d981fa61dc450a7bd' }
  'win64/it'    { $checksum = '285dfacc2af23d9b6df7f3cfcf899ec7867a1b859a6a28386b50bb2b8a8f19fd' }
  'win64/ja'    { $checksum = '9dea4e248b5c9b458621c4a49bc94a96514e96ace144c5d6b2fe20079603c9a0' }
  'win64/ka'    { $checksum = 'f44812d072de2263a6d7966519ada4a139b114e0ce9470dafa88557c40d31f43' }
  'win64/kab'   { $checksum = '6aa4a096d623fff4e964a3b22b524f3678dc2dd6653011962276cb1d5f619b31' }
  'win64/kk'    { $checksum = '04fe574c957085f3b4451472651818f20bccf18ae5e560da26d9cd14c33b968b' }
  'win64/ko'    { $checksum = '2c6c5c3121953382373632f86de64e80eb0bdc732e01f5653b84125d38c9822d' }
  'win64/lt'    { $checksum = '6de3f988efe9c9e172f3b5dd4dadaf074482bd290dfe99e937d017e4e20a094b' }
  'win64/lv'    { $checksum = 'f084436921ce48ad44cdfd4f85ed4f97dd6381b44ced375a5de58981e785051d' }
  'win64/ms'    { $checksum = 'b4264c94ae2a017ad3c80212d23f64ec76487912d15ac4b5c6b2e9958226d3d6' }
  'win64/nb-NO' { $checksum = 'c0874a300d24cc7be847ccb2017e9013393b274f2820e2797fcbf01fe95fef38' }
  'win64/nl'    { $checksum = 'f8fb58321ac2a2631048b175b323d9a913f129986b3f2edb624a7e83e8339f49' }
  'win64/nn-NO' { $checksum = '6c3dff8a12bcfd44c5b785ea48a88fcc70001598d7281e6bb80efc6afb8cdcbd' }
  'win64/pa-IN' { $checksum = '63c3835971b0b764f84c07b771baf78dee81d6e34beaeafebe073645d6f6099f' }
  'win64/pl'    { $checksum = '3c77ca131330f910355f9f3fb3c551aaec77a396c6550c99d773d1daf4aa90bd' }
  'win64/pt-BR' { $checksum = 'ce27a260c04ffc0c3620fd95f11f6efdf2595fc4b59aa8ced6dc5f2f9b5de6fe' }
  'win64/pt-PT' { $checksum = '8add7710c1f6f66cf16009e9f248f222ab44b82b598ed85bddaf6c93e6d64ff1' }
  'win64/rm'    { $checksum = 'b507079f3d9358424fdd9636b5135073fe00e05fc1fc14b8dd679959ae5b0207' }
  'win64/ro'    { $checksum = '26973074580d70968b5b31f5871a30e9deedc6b34bda02933e1062df9b06bb8b' }
  'win64/ru'    { $checksum = 'bf062e0e5fda06e475c166428d71f9ccfdf4e08291e0ced68829ee30b78a4b6a' }
  'win64/sk'    { $checksum = 'e5f4c352135efc17c1a53e7cb90a7e1ba15f22812541420219fe93589872f44c' }
  'win64/sl'    { $checksum = '0e2636cb3a1b86af064e04b2e1164dddcf66b4c7f99ef2d5bd216c78b45a884b' }
  'win64/sq'    { $checksum = '1d9d474549acf1d60647b5965ed218894085c3ab2f845a42271440d25acaa6f5' }
  'win64/sr'    { $checksum = '6c81588e86373f494da302c4e36dd4c0bdc61141688100bc53d1846a1b29c490' }
  'win64/sv-SE' { $checksum = '791a2f17cf8fb8b5c6c15b7e338a8f46dfde25fa99b2a236d9d94e09d938187f' }
  'win64/th'    { $checksum = 'f7588a7ef0dd04cf1ee329dbfc9749a5f2ede4db527c04f354a4be55dfd20a14' }
  'win64/tr'    { $checksum = '685383e0b0e56e0a0555a7b137c846abdb96f9d22ffdb2abc6bf7914b2e47763' }
  'win64/uk'    { $checksum = 'ccac7a4d37187b42082f5c6a20d451815abe49e819e5e51e81598e6e5bc59cd4' }
  'win64/uz'    { $checksum = '67a4f95a0c83a0da3a3dd2fe468e74bf46bbaade5650d148f205841721d2ee13' }
  'win64/vi'    { $checksum = 'f08757e2c302682feac4a35954833675f218fa4f008bb1a88d1d7294c2367dc9' }
  'win64/zh-CN' { $checksum = '9d5bf2d3ee36371cc868dc7dacfafb0fb31eef173b72980ccac5212e99ab9bc5' }
  'win64/zh-TW' { $checksum = '198b7cbc624287a1bb6f23e092d006b935ade2f20d4582533a48113bc4762a42' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
