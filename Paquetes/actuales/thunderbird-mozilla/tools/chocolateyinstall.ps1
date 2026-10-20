$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '159.0b3'
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
  'win32/af'    { $checksum = '9e036bd5341c38697262cd5f7d29d4c31d34d48ce5f7d41917468f6629a0463c' }
  'win32/ar'    { $checksum = 'd22ed1a04bae0f501ae42cd2312bc6347589150c01b63ac232729ec1f70f5926' }
  'win32/ast'   { $checksum = 'fd9a181b82420b81a48852e8e6c80f1b27a774634c74b69f1d6cb52ab1137600' }
  'win32/be'    { $checksum = '33d826da5162e657f8893d50f9072ec8a546c755c1926b6ee7d0dbe0b75480bc' }
  'win32/bg'    { $checksum = 'f9c5d7a10f3cf05f69239aefc9def8ef919f8415ecf495bea937921d2a217c91' }
  'win32/br'    { $checksum = '0bb986b295ee617594d9bc834a624ecd09ab91eff4f0a2a2efadd3daccbf1010' }
  'win32/ca'    { $checksum = '005f123a82aa28e3405cfedb863e812c7729d0e1232c7735c8797c6d3f0955ed' }
  'win32/cak'   { $checksum = 'd4c3e196ed0033f10b9b0605bc6a83a7718bd160f92f3483bace50bc5af576ec' }
  'win32/cs'    { $checksum = '111f91c718c6c469a91c213539f65fe7a8a9ff3f688b2ec50c618a1a94b610b4' }
  'win32/cy'    { $checksum = 'cb0a78a1061a74fb8ca11934a7b79468f27834aa45457c7382a2bdce3fba532f' }
  'win32/da'    { $checksum = 'f90a6d4e6ae56893c3ea36d491170eb8b6dd4caa493dee11f55faa1bab03afde' }
  'win32/de'    { $checksum = '94a383346f55f8546c80d17ff82543679b3f82781e687ef1d052c72c946316b7' }
  'win32/dsb'   { $checksum = '24954a026753ae2f33463b8c79e7411a3276bf0557ee3b9d53567bb2b4617763' }
  'win32/el'    { $checksum = '4bf95180706fdade00398ff830ff259ac2debfba8df513eae61858f87d8fc24a' }
  'win32/en-CA' { $checksum = 'bc1cee60dae6e5425abab044f18af790bb524c1c89da97137f54b5b046f12813' }
  'win32/en-GB' { $checksum = '49ac6477bfbc78c852c040b02ebdadbea7e3706a305d56da47d75412e1d589f5' }
  'win32/en-US' { $checksum = 'ac5b43a1ed9639a7cf4cbb3b8b10d99dcd0281cd8208545ac440556d867c0540' }
  'win32/es-AR' { $checksum = 'd3273ab09962e48c142ecc195dc9261ef8f60c2fc3aa0d49c60c1d6c8ab8d786' }
  'win32/es-ES' { $checksum = 'af3be505474011f9f24d8bb7fa19c681609de234c000d1b6b58ab05cf7b5c257' }
  'win32/es-MX' { $checksum = 'fbf1390a401fbfe1e03f76082703b3f76039555d2f43952a6dfe7397d1f6319f' }
  'win32/et'    { $checksum = 'ac29a2d8c5d2f00d2f092975c7d6211231bbd07cdb32162add18714a4d3673d7' }
  'win32/eu'    { $checksum = '4082bf01358b0663dd7ce1922ccc9731f012d4a25dec45dd8764b3ceb4039306' }
  'win32/fi'    { $checksum = '715c5ed03f38c80802cd163fa4adfcb2893ec06167c7df99e579f29d1858976a' }
  'win32/fr'    { $checksum = 'a725687e9fbfeaefece81e8e024509e96425916180d1749be1ab7e72c7d127d1' }
  'win32/fy-NL' { $checksum = '7c9b47bed9d31bddd3380a4cddfc78846b8f429545f52e7b86c2760e8ff10978' }
  'win32/ga-IE' { $checksum = 'dc233c0f977e036f12f648a627f71388d3a27f6637837ddb18449920ed422d3a' }
  'win32/gd'    { $checksum = 'b44a73f3c8a4b9e75e36ee83112717242c385f569849ac48cf5590ba8b84946d' }
  'win32/gl'    { $checksum = 'b896d0832b4b0bcf2267f0cd99d3272a2908ceaf6f07a18e94962f0b9c6939c9' }
  'win32/he'    { $checksum = 'b41448647a0a54867c2d2674cdf16e97e13042e78f5d35d72d2b644017e49e7a' }
  'win32/hr'    { $checksum = 'd495ec6f7dcfbc3f22305951d4222efb10da10fba2e36c5a4dfe59959948f11f' }
  'win32/hsb'   { $checksum = '71590b6c2dcda43360793bf3d9238b502ce9a2e454917ba848ca46cdd9b2c0ab' }
  'win32/hu'    { $checksum = '6e1dd2ccb285aa6944d5748ebf110bb57f846b151c15d62feafd5e66d269b03b' }
  'win32/hy-AM' { $checksum = '28668a058bbe2058c880d32fd38b396bfad505425117166367cc0fa1a0a8c3db' }
  'win32/id'    { $checksum = 'a5f50b0735ca8abc63d55001e231f3df2fa08edb0bc4db8655b9e82f232df3c9' }
  'win32/is'    { $checksum = '80ffa8ad060f792f12de734673305dcdfb1bb2ee58ff13d0f62844c79626c84c' }
  'win32/it'    { $checksum = '2563455134fce7f913c848e5687607cdb62d538de12b22b69fe2bd396d82391a' }
  'win32/ja'    { $checksum = '4b4d097b551689855f3ca4118a7b87c0543d5cca94e76ea13cbd4c7d9d3a5c36' }
  'win32/ka'    { $checksum = 'ae8388ef9a0c942837bc06aa9dbc568cb6629fd65f5d15001355f720edc3d44f' }
  'win32/kab'   { $checksum = '728a33ebe7f1145c49939480044f4b0967aaea841424dd405eaaf96d51b73dea' }
  'win32/kk'    { $checksum = 'e6fae46c04200f57850bb5942a14012b43d984a5eda62b88a015b01734bd8b93' }
  'win32/ko'    { $checksum = '34a2a8cbd81880a61329e0cfffc048d747d4240ff935ff253e09a7446812aeb2' }
  'win32/lt'    { $checksum = 'b735b88583c40c0ebe5acfc3338ff5d2a1793b13d5286ed58d526639ddc76d25' }
  'win32/lv'    { $checksum = '86aa636e848a99d060b5369625e3568280de275d5745b1ab5fc5ad6fe4b7287c' }
  'win32/ms'    { $checksum = 'dbde815b20dac032ab5551801a2b1309479b93602f91958816149c42f77c9b60' }
  'win32/nb-NO' { $checksum = 'c0bdbb7d3fa6c681cff63aec7bfd411e7ab7be0fcd9e7eb9a2d555ac24e3c1a7' }
  'win32/nl'    { $checksum = '6f10ca80f48da3baad08c44601267ecc58a08efedab45157cf5d3473bf912d75' }
  'win32/nn-NO' { $checksum = '11d65d7b283586557a08649f1e6c9ebab5e28dc7189d3323ee5315e2509565d6' }
  'win32/pa-IN' { $checksum = '16eec602b0eba7175466f9f770d3b256cbc8ebab1260d9e4abacfb1eca6f5789' }
  'win32/pl'    { $checksum = '900a3c622686d145875ce7ea477606c9914d6a6e8b3398cc84514ac559c055b7' }
  'win32/pt-BR' { $checksum = 'f57b0c10e75b9dfa655a8ae21207a7c102d307162a3791a67bcda085d230cb1e' }
  'win32/pt-PT' { $checksum = '0591597a3b0d4e2d7a9e8536dbf5ae53e198c5eb06d18ebc7e604c0e0eec4855' }
  'win32/rm'    { $checksum = 'c56b10feb061e053c7081de36460b8797ff7a469515a10ab32823effe30bf80f' }
  'win32/ro'    { $checksum = 'b5f6e9cb396a3fb04f776e9193db6c7e6dbd7ee3ff7bc50bd4c760e84ae75128' }
  'win32/ru'    { $checksum = 'd5b0641b07b975d7aa8b672e7dbb0a668765350416e46203d07408c678bebacf' }
  'win32/sk'    { $checksum = '1c4749561bcc1cccfd79d4e82caa845d8af091f1d642d6442acc2af70e38640e' }
  'win32/sl'    { $checksum = '41bdf6a56ecdabfc0296530e2fd5ee14a9378b1b2a45dc5308aea35853406c2f' }
  'win32/sq'    { $checksum = '7f4e38c3663e8dbc135bb08cbf8e472ac6f0032b746199fa37ce4b9b1b5a59ae' }
  'win32/sr'    { $checksum = '09ba08500a15eb81c9215ddb3f9f4cd747cd502e0c3c84aa0e1979323bc59069' }
  'win32/sv-SE' { $checksum = 'a5cf507aeffd62b90b5970a96eb739274f3d1077ae3b357d6ea70b17060c08f8' }
  'win32/th'    { $checksum = '5d7e24d6c0022c88f8a8a56f70ec1dc9ed3cd91083d2fcf93477b1d1a45f2410' }
  'win32/tr'    { $checksum = 'be8316878f286b4f8803ee50b1b439cc4c40c44127003625b3aef4ec1102de46' }
  'win32/uk'    { $checksum = '1f8f2bc90ae627e03ef42e54a80ede4ff167911025033a85e848cd956c5d4f52' }
  'win32/uz'    { $checksum = 'accc2e630ee67a8fcd9fd4abc0b30cb0198bfe6692a08661a8f424850c95d562' }
  'win32/vi'    { $checksum = 'bb227f6d6dfdffaaebe1167aac1131636720623b3f8a01fe56e588d3d6a0bd21' }
  'win32/zh-CN' { $checksum = '32473eb9ca64dc517959a0eb7f9199501bd793748eaae5404d6e38f14766da8a' }
  'win32/zh-TW' { $checksum = 'f32d16a6a892c5c2dd1259e67c909d764a323f267ee5d647e3070781027508c3' }
  'win64/af'    { $checksum = '57a2a0a4d2b1419ebf3efbec5d81ef44b2b61e27305b6bfc3fd426645f768d56' }
  'win64/ar'    { $checksum = 'c3e206d19129c7c039fec2214e8c8e630451c62d94d99247571b7c327062eeeb' }
  'win64/ast'   { $checksum = 'd537541cfddddd67f786c55869ff10299d810433804d20709d8646dcc0f1f253' }
  'win64/be'    { $checksum = '70ada416c31ee4540b495aed31f6b47df9c58e5230b36ada8e480415165fc20d' }
  'win64/bg'    { $checksum = 'b31f92db153d81a0001ab225c9467f4333d8a987e83926a6450fa7df7d9b680e' }
  'win64/br'    { $checksum = '71749155020d57b54ee5d4b01bedfa4cf6c1271327907d60817b9f76917b13cc' }
  'win64/ca'    { $checksum = '05b8b79823f831d4709ec0cb7acbacee1b283c5570c5aa22f8a262935e65ed0e' }
  'win64/cak'   { $checksum = '19b960969418597daa2e668c4f109882e7aedb4abbfc17bd0f7b6108f3a5bb78' }
  'win64/cs'    { $checksum = '72b65c2716e42c2ed888857e73f3a50ea6c53b9a22f6a28a9084d95a24e4b3f8' }
  'win64/cy'    { $checksum = '1bc75feaa63b84128aaa79982762a14f5d54821d4d7a640f7f02d4cd55fe471f' }
  'win64/da'    { $checksum = '9f62d0f8b66bc8083a49040cdf9cc6c3963870b28b64eef4540254173cdf0407' }
  'win64/de'    { $checksum = '8ac9656435815bc85e23ede919211abdfe470ffad30ebeabbba047e9b40f79f6' }
  'win64/dsb'   { $checksum = '195c8d877bb8cb593f643365d6efbbf0274a985eaca63f5454908324400e64ae' }
  'win64/el'    { $checksum = '61db78cf05a21be9d405ada7489f45b960fb6a65f738d494815e7cbcf4226310' }
  'win64/en-CA' { $checksum = '7b04e679f7f54ba808a23ba773d7d043bd49fc38fec6d33ebc11a2ff60976ea3' }
  'win64/en-GB' { $checksum = '4eb2e2424aba095aa4f3506f95f1e644ef9287288d58b68e59a3dd366e74cb43' }
  'win64/en-US' { $checksum = '9fbc70dbb35aab658ac535819819237b37d4a84dedad62739e0b97af1d59766b' }
  'win64/es-AR' { $checksum = 'e9fae023056a34a28f457651b39c19e24243294c5a1353bc008d43bf2e26ebf7' }
  'win64/es-ES' { $checksum = '4cc290253c755e68b5e4b14415adc1d4582337aa80f081b0907b627ccb7dd352' }
  'win64/es-MX' { $checksum = '57e6ee1a2fadcffb44298eafb4f610e1306955c0d695c37419add4546b966a1d' }
  'win64/et'    { $checksum = '1603a8f884be9c6b079e1af3dccbdeab5bf37dca06afdf733fc88a4c62a42fd2' }
  'win64/eu'    { $checksum = 'bcb8a9c3ee2704470edb49ecce01712c0277c45dd43bb4e14541ca8e0ac611b8' }
  'win64/fi'    { $checksum = 'ac1e4d755919a4f0429c60439ba1b6aef874e95d5b9ae4d053b5610b658390df' }
  'win64/fr'    { $checksum = 'c1517a626c0b5eca142a57912902ff4bf3af2e29554b96ef864c25b05fafb2bc' }
  'win64/fy-NL' { $checksum = 'aa0d828786f7cad2b11a65fc9de04815deabcd0b43a4ddbf15cc6324c1d3b892' }
  'win64/ga-IE' { $checksum = '37fcd5f7d004716c4d8f3421611b21355cbc0b64668ac4483d9f4bec5f97d31d' }
  'win64/gd'    { $checksum = '837116a4f297004de2b1e13f8a7ebc9c53ed8a65bc9f80fe48920185f70baa72' }
  'win64/gl'    { $checksum = '676796d60edf7ee47e2bd2150dfa89c7ff81d061d0598f045e96acb732d225c2' }
  'win64/he'    { $checksum = 'daa249913447f5caeb5d0fd1bb25854dba7a06fbbc4e33e4b63241ae4fff90d4' }
  'win64/hr'    { $checksum = 'e9d4730278f5def686925805d88110ba36b75cc924c707c9171f3cafb3a09862' }
  'win64/hsb'   { $checksum = 'eabc37e7a27ca750dfd596a79666d14d28f500a0bf72e4b569fcb0ae44953684' }
  'win64/hu'    { $checksum = 'b639938c121ba7e8c0ea18f1d4b70b708a52afce1fd007ae2a4fade575d58ae7' }
  'win64/hy-AM' { $checksum = '22a3a22e7c1e514190cd92c0ed8c33fe7262b235bf3b08026a551c7d7435bbf2' }
  'win64/id'    { $checksum = '3fe58e2a64e76c97555545154bf742157e73cba112a220e4c43d83e13440a4f3' }
  'win64/is'    { $checksum = '824be397f065a1ac5d0593eaf7e35c2a73990a6c6edb2ff008044d9e9e6bdad1' }
  'win64/it'    { $checksum = '2293d6d3f91f0eb4bd2141007f8fb3380961971014bf6beb8188dc0f8fa7d65c' }
  'win64/ja'    { $checksum = 'e3e172bf4088f4add5cb745aa2aeaeabebfdbebe1264a6b9abdda7b3ac0dcbe7' }
  'win64/ka'    { $checksum = 'c9148fa9870671d70ae95964fd82194e622c6b61bb26ee4efbf9bdb41fe34ee9' }
  'win64/kab'   { $checksum = '7d5eba31f054daed00eb354404c5c8d5d259b5b02ab510d3d4a612d9d434ccb0' }
  'win64/kk'    { $checksum = '42f188d0ea36233d7ebaac51bf2f55655ac375ac110f12fcab4728360f732144' }
  'win64/ko'    { $checksum = '1ee782e309d865d62e0d5a00b24d61980571764330a853b4b2c9710ddf0f8ceb' }
  'win64/lt'    { $checksum = '1dfa34ed659642f6fd3e43c2243fb985e34ef0e62525456d128574406550f18e' }
  'win64/lv'    { $checksum = 'daafc5842daa1d1556f3b3b1248ffb7bbdb8d7441ab460fcba638a11dec977b5' }
  'win64/ms'    { $checksum = '089eb9660cc641a0d500fddf4622fb55a159912d2266a3e73f8d58ca2edf2c12' }
  'win64/nb-NO' { $checksum = 'e45cec3b7f38aa70f48da053fe34677a308909815ce4c1ef277bb1f3c8a4c03c' }
  'win64/nl'    { $checksum = '0651e7e13a988b2befdafcc722b098aa216e6793ae62c1a04eb8b5bf2eb2c742' }
  'win64/nn-NO' { $checksum = '6a807ebb40a24f9db5955158b3fddc32cb0b631be30e09ca4baec7387ffa7dd1' }
  'win64/pa-IN' { $checksum = 'd862ea998fd1f4e771b421024f5291541650b423b78397fa3444657c2b29d0e4' }
  'win64/pl'    { $checksum = '80242d248a055df7b3f4c95a7504cf73d4944322b44c9e6a0ac297bf6215806f' }
  'win64/pt-BR' { $checksum = 'ba9f278eab7e920f4e5334ba39ccaed1d6a80db7c7aef80967e8c89623385abf' }
  'win64/pt-PT' { $checksum = 'a4e9ab79ae40a399b7953f78984c406eadcdb85f285aac08473d713738daea79' }
  'win64/rm'    { $checksum = '0b7a6963ae6f3f0af6ac894b30139351178c6a8da9deaa6e1aaf132d22afc47a' }
  'win64/ro'    { $checksum = '556d20300d02f38fc330e74080724c1a36eebfa54b1c3fdedac192a0a27c1e2f' }
  'win64/ru'    { $checksum = '973ef03b05a5e8a3b1372bd3c6e5c53bc15cf962c022015606508369b401f079' }
  'win64/sk'    { $checksum = '4fc9adcb4915e63de9959e6c68cb497208154c5d382a52d0971d02da2ed72972' }
  'win64/sl'    { $checksum = '351f909b76d1f2186c2bb0995a9877599f7da4f28091dd718a5ff69258a41aec' }
  'win64/sq'    { $checksum = '167ef8e5c057018758b2379eb028fbc31ef480684054de8334c9e3a7674baa6e' }
  'win64/sr'    { $checksum = 'bea35336e266245b93489e79b11527d2918e99cce9620b8d488426e06de80767' }
  'win64/sv-SE' { $checksum = '41428f95e3b42ee5d8aa3de06f1db34236288b7f3e15156465c78a69e609b66c' }
  'win64/th'    { $checksum = '40c4e1c3517e147e763f7c985fab0a9348165b06293a99cedea4af328df07656' }
  'win64/tr'    { $checksum = 'e41703ed5ab689deae6159d1b9406318ab4bf1f60b3d528d713f40537e4bf618' }
  'win64/uk'    { $checksum = 'c0dd555278d81a3e8eb725a1c0e20e417b8872953c063dd30105e9bf1b0976d9' }
  'win64/uz'    { $checksum = '53a93b192efdcc7fcca24ef6b5046eca02632929e016b8fb3e6d3c97aed2f3eb' }
  'win64/vi'    { $checksum = 'b2f095772991968defdd9a4851c96371f9868510ced61fa31e04cbdec19d5323' }
  'win64/zh-CN' { $checksum = '03219e288ed21c01e1296884ce9f250a21178b43d2e12e85d7a949f17fee508e' }
  'win64/zh-TW' { $checksum = '6cb2c24678d1c3444cb312055da86a98d4b389a0f536813d7b23a0d3d3a1740c' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
