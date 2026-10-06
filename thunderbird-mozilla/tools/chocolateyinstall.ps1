$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '158.0b3'
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
  'win32/af'    { $checksum = 'bf69658e2918a526c7cb82c300e36a20250c3b710a90330d8bea431634c97937' }
  'win32/ar'    { $checksum = 'b661649b3f5db89a76b05ac9b8381df20fd765fea94178e73f099fea0d3c8612' }
  'win32/ast'   { $checksum = '4a19b71de4f4cecd9cb7ff6e0bdeccd8b3af072c99cc36317619b83dc559d35d' }
  'win32/be'    { $checksum = '0cc4ad8de9fd7890765795cf4bb60eb0730cfd390b129a8863c285365cf7a558' }
  'win32/bg'    { $checksum = '9f2bc79edae72e04889f560da27881781ca0966d6cc9e09d83448aa3cd8c40f8' }
  'win32/br'    { $checksum = '6940ca0dbfc582be665fb908c8ee7fa6a0465c366dc78d005901b8b82dc0e3a4' }
  'win32/ca'    { $checksum = '5663afcda9aabc69a8ced47e74a55b0466f8ab1bf66f29cd3287a44af626b4d9' }
  'win32/cak'   { $checksum = 'ad55efbe97f564be3e3f0486cb12aa31143039f2bc4db7a31647a5b516a45b54' }
  'win32/cs'    { $checksum = '458a60bc0d1cf5a084005d184cb6a3638a71ca5ac68029afff3bddb397625edf' }
  'win32/cy'    { $checksum = 'c65ec557194c1b81cbb53a2bf71b466e8b96606c0b9d2a5420ad884e10236a30' }
  'win32/da'    { $checksum = 'c5ecdac8e343105b96fb051b4dc8e2290c283c0ced37f565191f27b5419dc641' }
  'win32/de'    { $checksum = 'fc18a3dd27a4b2f5ae07d55e8bc52a96ea7fbf32a63765fa04b3d354faea8eb7' }
  'win32/dsb'   { $checksum = 'fe92569e20abc7770a7370cfa03a8cbd6162ef23690ac947aaebb4299cc593b6' }
  'win32/el'    { $checksum = '6678caccc7c2a881e5bce7a27c2d1ca4327d0cce458604308a500c4140b9bbc0' }
  'win32/en-CA' { $checksum = '1b950ffcabb4af32accffdccf57386c3b2ed65dc65ff005d237817b71b8190fe' }
  'win32/en-GB' { $checksum = '20a9dd933e9e971578fbb75b1f86eda579c646b968dbdeb4e5427875d101d13a' }
  'win32/en-US' { $checksum = '9fe77544a2aa7a210e61bb8c5ce74fa3a29bffed95762cc844ca25e3c88decb4' }
  'win32/es-AR' { $checksum = '06921bf37716da3224abca06969c1d6ecfd7acafabdb874b44abcefa9263aa8b' }
  'win32/es-ES' { $checksum = '61fc56973f46004256c7e46e400bf2ab2a2297cfbedc2247d42165a93014ecdd' }
  'win32/es-MX' { $checksum = 'b7028f3ebe7202c354faad81db8c945281ec0e72e8dccf2e524bf092e4fadfb6' }
  'win32/et'    { $checksum = 'b7c779ce3d1a66b135347e69acd0dc2a5fac28ffb6df28a2442f48da5b4e7759' }
  'win32/eu'    { $checksum = '9658677f3a64bc98deb787432992f04314b032f3f41c6365d757538046f73702' }
  'win32/fi'    { $checksum = 'acc2cdf5f083d4cf70971af85d23e615f4b788e5e3457c2da35d58ddf6e45da6' }
  'win32/fr'    { $checksum = '0f628476b7ab6c9d4fd4b0305ece2b3fa0de7d447041fad0c9d9758e90c06875' }
  'win32/fy-NL' { $checksum = '234892e35f15200220bb763ff714b702d00cd7cd44874a7215e143061eb8f326' }
  'win32/ga-IE' { $checksum = '53e9087e2fffc57f0eb0b3b923fb09f99e7bab3a485d9dffb3a200212f9abf0d' }
  'win32/gd'    { $checksum = '2959f2903e52bcc31b200a4f2eb86256f2f51160b0f593411a1411e30bf9c997' }
  'win32/gl'    { $checksum = '1bff573cd32bb79dacb291f0481f9f7d7d7f8e6aed0ef5d1b711f6e3543bc0d0' }
  'win32/he'    { $checksum = '89f07608e31c5fe8c37823177abdf5fca242ef02174affc987234bf874e42541' }
  'win32/hr'    { $checksum = 'a7d4878e10eafe236bb3775875ac556a29f4def1790e4c7a6c0487f9d98267c3' }
  'win32/hsb'   { $checksum = 'c2de71f34fbc05323c85e088ede654738ed119b9a424cb55e65130a70007e2cb' }
  'win32/hu'    { $checksum = 'a4e78ffb9386b80824335f1fb40444c184a8516e36d0634e01dbcd343d66c3f3' }
  'win32/hy-AM' { $checksum = 'f9f769222530e93b76c52bd71451b1d5155d0ad380aca652dfe84dbd7705aed5' }
  'win32/id'    { $checksum = '26d89cbba13ee9fb1cbf469e2612a9ff3e2952fdb9894302fdd32f50f707ffe0' }
  'win32/is'    { $checksum = '2019cffd0d8dde7ffdbede3ece4c3203ad1febfd28eee5df8e93839522372625' }
  'win32/it'    { $checksum = 'c7c951bf2ec6d5b3912d4bd0ede7f7bf17aed8588aa7d161040903dccafd6415' }
  'win32/ja'    { $checksum = 'fa716f9257c42e4d067dbdf090267811c925d11879e78371af6d674ba838a244' }
  'win32/ka'    { $checksum = 'f6a3178fecece9063a57285600b4921020c6be59e80183f1dd74d9c969115436' }
  'win32/kab'   { $checksum = '3d45dd0f44e0d835f2264f920d767afd011c1a07ad65b6f19ce469f274cb5361' }
  'win32/kk'    { $checksum = '9be194f54b4745f9b18a70db84c0a0c0a46a420ce5efc412846ecba75c796286' }
  'win32/ko'    { $checksum = 'af4c5703c9ca2a6b9abf9525e3c7db4e6a9299da8dbd72758bf9af3d24f2943a' }
  'win32/lt'    { $checksum = '8bb962d220f1e2b52ef30d9dca3a42fd040964c5be159ab4a3fea3d56ca502a2' }
  'win32/lv'    { $checksum = 'a70caa1abfcc2f7005762135b645f2de9b3c802decd1c3b10bb183c8652ca1ea' }
  'win32/ms'    { $checksum = 'e1e674d88dda508e0ee6ad86fd486b90a6eb9b07269da74474dbc649f02cfca7' }
  'win32/nb-NO' { $checksum = '3445400eab6cfbc5403d538a9c41106e0ddd19dd24d5aca24e67f4ba9cc951af' }
  'win32/nl'    { $checksum = 'd7c627d34cf8aa9173ef2dee1adc6d248860662916c20793ac4f8f98ce7eaeb8' }
  'win32/nn-NO' { $checksum = 'c7b046f94074d514c0bea98820c6d5318c1c69de73cc45b9156887acaa580f1c' }
  'win32/pa-IN' { $checksum = 'eca3b4a57711a2de97d108bc035159b20d3d9f943a7472f436549933234d5962' }
  'win32/pl'    { $checksum = 'c03ec588c0986fc1a773b52f69f3eb7a0f4d4f82372fecaf46e5337320bcd91d' }
  'win32/pt-BR' { $checksum = '0272008614734247160ac16f46d8b6be7137340f250d63ed3c0b0e9f439f3d4b' }
  'win32/pt-PT' { $checksum = '8f2e2aa221adefafa7d9257e18ecf3c21dcf3b8ad3585fc61a7b789e3a4fd2a5' }
  'win32/rm'    { $checksum = '2c15314de8422bfbbe0cb6e7d9a75f018ec2f9a427d3b3d76941746c4426be14' }
  'win32/ro'    { $checksum = 'dd6cca3b67be146c71276d997a4eb506579e3138b7e8bf1acbb0d65a4d6012e5' }
  'win32/ru'    { $checksum = '647d6f7b255cbcf1f563f4198d8d036864409a31cdcc18bc47e952e9ce4c94e5' }
  'win32/sk'    { $checksum = '6f4e8d5052e6db31662320504869e1c667265f21955221ba5cae71ef204e4486' }
  'win32/sl'    { $checksum = '8f810c63ad51f7389c86f74177279e7b634dc45f546d11e94b7f4c6830532945' }
  'win32/sq'    { $checksum = '89bb00d718bfcd18e332554ac4bbdce01fd0a3e57e661d57139a4cbaf9e860cf' }
  'win32/sr'    { $checksum = '3148513b0558de0c356f87b82f6d55df00bafbeb317688e8c23cb37c32b6e8dc' }
  'win32/sv-SE' { $checksum = '0ad9f4ccfb4ca3cb882237d02d00160679718aef32b4f11bdc804d32aabf0de8' }
  'win32/th'    { $checksum = 'd3eb375ca05f19d1187c019e45a0954a48568bdfb6a6c156390b57410bb5dfe7' }
  'win32/tr'    { $checksum = 'ff0926d7f96415a060164aa995d3970bf1d36acb3520244c470b6ba5aac7a18a' }
  'win32/uk'    { $checksum = 'ceb61520d259f93ed7b8a82877e31298aa8754d928a28ac8d3a9cc1004587185' }
  'win32/uz'    { $checksum = '7f955c05dc6bb850c8d51fe0fce4a5898cc5edb08106493f8c587f34e8d241fd' }
  'win32/vi'    { $checksum = '5fbb5c496a224d633fa9a569b710fa153bf140ff88676cd00a4c060dbc88a987' }
  'win32/zh-CN' { $checksum = 'd6ff8abb9a037b6f606bd2dcc266d1b000d3b04b52d6b961f478fee8e00eb313' }
  'win32/zh-TW' { $checksum = 'ea8fdb6714a2df7f454c640b4f1936beab4d1c7510969e557736de26852e73c0' }
  'win64/af'    { $checksum = 'cc2bf54390762d06be23c6297e4ae04fcf77625bbe92185892d7c3d1e5c3198c' }
  'win64/ar'    { $checksum = '9019be3b31d4e5d1a22c3eabd2bdf673bb0e9f3be30a12a2af948216d524e56f' }
  'win64/ast'   { $checksum = '217456ccedb2144a89a8fdb5ad1bbacd72fc4410c1d2809072222b99591209f2' }
  'win64/be'    { $checksum = 'd931e31903e1760d3e079959d29a21934768766e623d8233c927125571bb8229' }
  'win64/bg'    { $checksum = '5c2bba7660e9c2e64b2e025aac9fa5b93f63708af11b634861d2f7caf632aa6d' }
  'win64/br'    { $checksum = 'c67f833e41f95e39903d3b6ca25d7932ba8f523a83e82b09a0c3a971caf915d1' }
  'win64/ca'    { $checksum = 'bf9b18707919fd22dce2caff46ce908132230cb1dcf7662ac70640ca1e0fdbe5' }
  'win64/cak'   { $checksum = '93a65c6aa67f44bc663f4dfd8d61cbd4489f67abc64257b21f762660080d2f3e' }
  'win64/cs'    { $checksum = '18ad5ba4adeb2f4789e8642e6790575f135728a523d3d4391a4f63b26c96a527' }
  'win64/cy'    { $checksum = '9a8175b1055ed8f44730e829228cf520722dc49cf42ca5ea012cdf6af4f1888e' }
  'win64/da'    { $checksum = '57f24aaac7736bc57fdbb4c522c158f310c56ae7236cdf2bfeadadbbf5a28c62' }
  'win64/de'    { $checksum = 'f228f5cfddc09e3dc6cfe981dd48243e465bf1a0c34f33dadcd0419a69146885' }
  'win64/dsb'   { $checksum = 'a3e6ea7add2905121846dfed3e73c225ac1d565d6198534a23c97d11f43e264d' }
  'win64/el'    { $checksum = '31850b6d24e6f9f52ff5d6651415f44f62467e8e2a1c94e53380676850d703a3' }
  'win64/en-CA' { $checksum = '70f990fe2e2a51010e23bbbe13d0ec422550a5be44382aae3ebd1d919b4fa200' }
  'win64/en-GB' { $checksum = '0369230297a6328022bd0b82bd812ec6c975ed45a3ec9659297fafdcd3d30d79' }
  'win64/en-US' { $checksum = '705ab9440f16875d8013ebeef05e44951c2a0ab5944bc08988b9a342ded9b60f' }
  'win64/es-AR' { $checksum = '4996a3ea6ae34b993424393d1bc4f04f112bb1802014a8057182113bfda927a3' }
  'win64/es-ES' { $checksum = '027500e580b34757a6817b49c84a71cc6ded9c1070c818b0af814b8486ec2bbf' }
  'win64/es-MX' { $checksum = 'ee3bc5d167cc5e894db76c58e174f55b691ee12939fe3e2dbbfd71c04d221f10' }
  'win64/et'    { $checksum = 'ac57676e97349fd36e4a4536cac693f62da197d1b74b17f9ab5795a2a405843d' }
  'win64/eu'    { $checksum = '83b61c3434bed794fe49fb50ada3bd1dcc317b5f11518c9138e8165a1ae4335c' }
  'win64/fi'    { $checksum = '41eb9bd17d07dc58ed873570e7b8fa71e76dcbd3510cce148c144f18d6d541e0' }
  'win64/fr'    { $checksum = '514df16bfa269fe077f1127eb75c5505dbaf261f30a47c4b91368071b1c10ba4' }
  'win64/fy-NL' { $checksum = '025fd031a198649ec79e56f6b7c9cb400d82f96a7e29facf50d08dbf82bda7f0' }
  'win64/ga-IE' { $checksum = '94485a53110b5ebe9204535df6a1537acb2513a139a959121c60f14ff1a6d51e' }
  'win64/gd'    { $checksum = 'eb5d247eb032e4eaa74bb77f738448bcc647a5f90b4de63b1b701cec19c7213f' }
  'win64/gl'    { $checksum = '651b44635114306dbdfd0f69ea5c44dcd19ff40be1aca83a033a54d0163b45b2' }
  'win64/he'    { $checksum = '8a29009905b6fc74da9833e091d1feb4430473545b4c7c9332463684d1735c25' }
  'win64/hr'    { $checksum = '8e8ea1ee5316ffe1fe750ddbc43efdae06da9762452fe463bee7830adf353f3f' }
  'win64/hsb'   { $checksum = '92ba54b0c9813f84b26cce7deea174ad7222abb4bd00c92a37fd0ffe91781345' }
  'win64/hu'    { $checksum = '0a636b0d84d54af734b7633f5381bf74dbcc3dfb00eb72679700f5f9c45edd92' }
  'win64/hy-AM' { $checksum = 'd0148119d0b9e2524b337b476a25651c293004cf6366489b5b938761e679bcd1' }
  'win64/id'    { $checksum = '314ef350d1fee93c3a0687324b27c834a62e30af73ce2851a436ae557c2d88ac' }
  'win64/is'    { $checksum = '658fba3d730541d121ecc97089a4c7eec3a4137a7789f42cc7b1316bef24a657' }
  'win64/it'    { $checksum = '235717f2740f988736e0cabdc71b23a11b489e3c194b77bcda5ca5ec1a3fcad6' }
  'win64/ja'    { $checksum = 'f432d5f10b0085887ff311765db71d7801f2e46e32dacb8541f6cdcfdf0b9dfe' }
  'win64/ka'    { $checksum = '5557f263c2ecdeb6c1982ee53eb93185fa95e42ce50a45054eacc04318e4201d' }
  'win64/kab'   { $checksum = '5900d7fba95136e812c7590eb7bd1d49d87728c4d79d1b47277ee4a7a72ad0d5' }
  'win64/kk'    { $checksum = '238f8b5d627f35963a3fbb9eb052da685c5336d34cda212fe6ab7e0e59a2b7a3' }
  'win64/ko'    { $checksum = 'ca0335781ef9f2db0f9f6354e566d78f4d92c0281ae81be92dbc0fabbad5a92c' }
  'win64/lt'    { $checksum = '4c62fb9bd95eae3cff4549b67ecfe4ef0358241e7160417f18bcfba6f28ac41e' }
  'win64/lv'    { $checksum = '709bb43c1e3983d947cbf466fede6ed4eb2c5435f6810971e9791b4796a23bb7' }
  'win64/ms'    { $checksum = 'ee9d8c0873a627909d212898049282c5dcdf8b0abeb1fc63add61977fe508279' }
  'win64/nb-NO' { $checksum = 'fd42bba81114b138b44197f4522aeb42ab2e2b4ad5a21beab337ce15460e8c18' }
  'win64/nl'    { $checksum = 'b8b6a6d01a47ee715abfd9c48941f54de5111c09d18ab9f4eedc1ecf1143ebfd' }
  'win64/nn-NO' { $checksum = 'cfde904e359ef16cf0157934d11ece495979b60d99198aed1e083ebf41a7bb1c' }
  'win64/pa-IN' { $checksum = '36863635791567c607b72c7be26bc506b12ec4272b4d3b11c77f27fc696b9c21' }
  'win64/pl'    { $checksum = 'c444f96530f4f87fb108b57307f552e916b16a9609b90d3c1385829ef83ddf67' }
  'win64/pt-BR' { $checksum = 'b17cfeaf9f354aff297f611f2ac88cd1dccd0cfeb6946e874da2e24854002599' }
  'win64/pt-PT' { $checksum = '4c2dba9293a357a33409dc62f31a2dd2dd32502469f7ccd994b0838d849c2908' }
  'win64/rm'    { $checksum = '2a4cbadbcb559eb6568669e63f590899354f39ba4a5e49722ec5c3367aa8bb0d' }
  'win64/ro'    { $checksum = 'e58af0dcc8e2b6875b532b4d3c20215abc07b19374c1c701c4b7afdf86ee24ac' }
  'win64/ru'    { $checksum = '53c7c9e25249de789e29d6622b43ae1c52a8dbbda8b52d440b9be6a8da4af869' }
  'win64/sk'    { $checksum = '232261b843aa8e347dcaa4d1261f9d6a895b90d8acd540a6a974c9e8e54edbdf' }
  'win64/sl'    { $checksum = 'fd330268520cd3ef7f6ce5ed6d68aa39bbe554ac08045591b7a6f6088e68615b' }
  'win64/sq'    { $checksum = '9cb9d078d918a9f4c11b720c2a162615a03a981248f3f34a1e0f4f21fdf1d7e0' }
  'win64/sr'    { $checksum = '1a9623f8bce64d413b30d2c710023e1d996ee44aad810059aa8940f2d48df21d' }
  'win64/sv-SE' { $checksum = '8ff35e283dba6a46d03ef374ce7d2e77bdfa2ec83ece8f37635c3f08888acc89' }
  'win64/th'    { $checksum = 'b109db4b1d920c1cd5958a133bc9dd5aab07821ab1da23cadf1dd10a35525ceb' }
  'win64/tr'    { $checksum = '82f249ceac075e8af0d6825f936dcd773f4b6715a3ac5aa407b86de001e82a32' }
  'win64/uk'    { $checksum = '56af06c8885d4afd331e61083156c30871ef902713f1ad0b53e332270fb1fc43' }
  'win64/uz'    { $checksum = 'c78937be1dc36e432a25acafe2b5e5feffeb60c6841322c8137aa41f5a221ae0' }
  'win64/vi'    { $checksum = '483375c8d6a6acba8e31440337ba041a9b2651f51a0964d48c67303beb3012eb' }
  'win64/zh-CN' { $checksum = '66691edc98b670dcd2315df8894dfc1cd1351a40a342de96185573c0ebad9d18' }
  'win64/zh-TW' { $checksum = 'b7ac01bf295d75c736f99fee6fa5dd0ccceb06e4c40fe11462287d7abd6f70cb' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
