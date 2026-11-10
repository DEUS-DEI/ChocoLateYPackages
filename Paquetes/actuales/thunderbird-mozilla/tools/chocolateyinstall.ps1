$ErrorActionPreference = 'Stop'

# Fail instead of reporting a successful install that did nothing
if ([System.Environment]::OSVersion.Version -lt [version]'10.0') {
  throw 'Thunderbird requires Windows 10 or newer.'
}

$version = '161.0b1'
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
  'win32/af'    { $checksum = 'b2855d5796c39e0c050827c93f16b8463751398723a7e86bb38dc29a42abd08e' }
  'win32/ar'    { $checksum = 'd53667655fd24714ca692afc01475352b151da8dca54f5beef83df5ad8c89afa' }
  'win32/ast'   { $checksum = 'c5f1b1cca2e47b0230d200bcac7a50a7f24764983a724f3dbee79620b96d6a60' }
  'win32/be'    { $checksum = '2106409bf8dadc0df4de2edcee6e39924e0b599b8de15fb37949f734d88297be' }
  'win32/bg'    { $checksum = 'a08c12ca6df96d428c1259b421d864ce23bf0ab89e76fdc2ba367df0199ae15b' }
  'win32/br'    { $checksum = 'bd6e98238fa3b5ba18f06dfda63c81afca6b4c943809df66a8c1280d33223053' }
  'win32/ca'    { $checksum = 'a2160800249cd91408a14af643840587a59281569dec7a9b9694512b5376e7a8' }
  'win32/cak'   { $checksum = '543b731caf2afa01fdfca542647f5da836bda650f6fef4be81a1f6356d1f2860' }
  'win32/cs'    { $checksum = '133284ab31433bc6ed32ee2d8d408bdf253a5ecab249c55423a684830951eaf5' }
  'win32/cy'    { $checksum = '434bd212b1615ad847f0800b024c7613e2881cfda88aa1921dff8a25f105b122' }
  'win32/da'    { $checksum = 'dde61b02b85a76a6e86961480b0b78b8f26a4a0b153089c19d3d8ff05dd161db' }
  'win32/de'    { $checksum = '493e566b1c1204328b9f5454a7d15c1c7ca1550e2d1bc7952e1a15bd0e64817e' }
  'win32/dsb'   { $checksum = '2fa277603666e35cc03c740c385e311ccdd487c69ad9afebb2362d48bed2bc98' }
  'win32/el'    { $checksum = 'b2c14a4986dc35f0016e872bbcd13f9cb03a7b273d880cdf9ed0f57b3db88932' }
  'win32/en-CA' { $checksum = '1158621c2950a7567103b7136a8c0fa28d31b799dd2b5fb439f81ef3189ab65e' }
  'win32/en-GB' { $checksum = '91f442ad144a560d84ac2575d2b5c3a71201cc8a3092e40a088e8f28278ccaf0' }
  'win32/en-US' { $checksum = '85194b9bc7cc1e35c5dfb3f836dba7e2947a682306b25f279f5f083889fc2566' }
  'win32/es-AR' { $checksum = '4dc9591dce6b6350db572de1fbbed7c1eab353c6bb428b43ca6b05da933ea9a6' }
  'win32/es-ES' { $checksum = '473326a521941ae3f0c318d4e7aabd927055d24834a9be337269b639d31a75ff' }
  'win32/es-MX' { $checksum = 'f204cb997ded2cf38f86c6f326f6131b4742ef16a5acad5a7672466852f4729e' }
  'win32/et'    { $checksum = '873ffbf9e5a1d8ac21b71d40b389872621857e74d05e3862a9cb276bc4f74f5c' }
  'win32/eu'    { $checksum = 'c41e53b285eec1251e786c3387999120561ab623ff111d30eebb31d2067d4138' }
  'win32/fi'    { $checksum = 'a5af0eb429cb8591e5c7f299951f930a856b2d20c3a5ff6bb71c3c334b481a80' }
  'win32/fr'    { $checksum = '5676a6f6be2c759974854b1a02c7ac35af27daa60d450288717a3f4e1557496e' }
  'win32/fy-NL' { $checksum = 'a685b70cb77d2ce4c1a122c6f3f13baa91efa963101b003c71fae6c8e88f61bc' }
  'win32/ga-IE' { $checksum = '805fe614b27527aca980dbbe4ebfab4fa7c7b7c18b4076e383db98dfe7a3fdce' }
  'win32/gd'    { $checksum = '6a2711b30d88086f7ffba3733112640e9862c1c828b2bcb568de2995eb380fb5' }
  'win32/gl'    { $checksum = '6b6d027da789c99722e7e9892bcf3f87d18876e437e202bd7976bc0fb6a19c64' }
  'win32/he'    { $checksum = 'a68ba725689928e41786ce56739386569c3dad9f472da20aee00c8ab8a7a4fc7' }
  'win32/hr'    { $checksum = '917b96616117c8de37ea348be9cdd7ae7389e5ee19750709cf950c1b7666872c' }
  'win32/hsb'   { $checksum = '74126113d03770413b627bc1382128de0364d126d5cbae4a0ac4d97eedaf420f' }
  'win32/hu'    { $checksum = 'c7f8d3ee71665e4d7873cdd20b41835d4b409110711816605ba030c62de09fb6' }
  'win32/hy-AM' { $checksum = '3cf9cfecebd12d8071e6549ad4b656abb156bf19b00e52f068e674610e70472a' }
  'win32/id'    { $checksum = '2de9eab52b236e155d1e0f0874dd018b3ad9873d0a988279a1608c67466dc48c' }
  'win32/is'    { $checksum = '9bcc951c92bc300feecc4ee09c6ca3f3922e9dd60626c4052eef164e621a7857' }
  'win32/it'    { $checksum = '320f486fc35c669af8ba29e304f8e99be66adde0d80ef8b647b0c2aba44f97c2' }
  'win32/ja'    { $checksum = '59b52f27fe970f10662759c6f08e2db9efaa283a49dd186181266746c39cae65' }
  'win32/ka'    { $checksum = 'eb49ac59a47c8906676f5b2495ca2a3ee7021f3f2850d05234bc44bb099651a8' }
  'win32/kab'   { $checksum = '9e4add154b3685ae96fe53382d7a47b5c12299f2eb22200c143f53b7090ee9df' }
  'win32/kk'    { $checksum = '12c127e9d8e508caf57cf9a60a70c83fadea11aa2795bccf8fb42a99719d9872' }
  'win32/ko'    { $checksum = '5be2a8c96eb2d9ef023fa98a1c553979011b34a6936eee4762e8c994cb82e539' }
  'win32/lt'    { $checksum = 'bc04860bbf8347bb6fb6c38900c85a9f1b4882b137023395ce139518fa2a452b' }
  'win32/lv'    { $checksum = '38437e1fccaca47eb6a388c74173b617bbf7b5a403f2c82dba91829bf9b5288f' }
  'win32/ms'    { $checksum = '2d4d03d59b15d92a498d52e3c8e115899e57be185b8e25d6def99437c70c97f2' }
  'win32/nb-NO' { $checksum = 'a4c2116f0872323bd5857e60a04896ee18e40d4c8c793ceba974b90eaf2a6a99' }
  'win32/nl'    { $checksum = '4246118acba8c5fea68d0ef1a72a0080ad479198069dc52eddf88b942f03d7fd' }
  'win32/nn-NO' { $checksum = '44d23966b2323d5518681b85f658c0fee7be83dbf967c54a21caefb4cf79a6f0' }
  'win32/pa-IN' { $checksum = 'd6a1df52e23e9a5d25136595bceef9c29b657980a5a414df44279946cfd30168' }
  'win32/pl'    { $checksum = 'c53ec1afb84a2273ae6a91edd6a1fe94fdd2e5a5c38b87b108f17dd5ff18c2eb' }
  'win32/pt-BR' { $checksum = 'ecf1931a50393fe00a37ea4f7e05afcb046e32366e68df2907f39ef0c4639791' }
  'win32/pt-PT' { $checksum = '31de60bcc57475a8ed6fe16f404cb0df9642223f350961a6d4fb769f68ba2590' }
  'win32/rm'    { $checksum = '0670861b9f13a3ac807b62328332721e7251d135911ae20f17ce890d8b11ef0b' }
  'win32/ro'    { $checksum = '2c64163f103fb2f53cd3fd331e39a58c010319c95df7b12cd280bd704f510386' }
  'win32/ru'    { $checksum = 'c3a9c34a6067bea9f6937d025c356cd68373083820843a57881782ba6ae2feb8' }
  'win32/sk'    { $checksum = '5442a9977623ebcd49dc1c3a90efc74519eaedcff4baa6d27d9c090a06b48cd2' }
  'win32/sl'    { $checksum = 'f1c9ba459551b8a734babd195906021997f1ab240e84d41917bca40df89c7edb' }
  'win32/sq'    { $checksum = '7c5c5836285ce2b0bd3853553b24c31e70bab4748c8fd1d6f64614314346a67b' }
  'win32/sr'    { $checksum = '5af16588c03ae1ea290e697251a794de18b45e705d05d8afb56afb0d8297c138' }
  'win32/sv-SE' { $checksum = 'ed05efe8d763520053620333bfa956434f8e01f23af2fc8e774453de37d60cca' }
  'win32/th'    { $checksum = 'e7038af7bcf55e14f7a064f393fa7b8646df32351f0d2414bee7efc026c197f6' }
  'win32/tr'    { $checksum = 'fb09d45a7330436db27f140d1d08a07c857def6b4f39a0908b51a509b842465c' }
  'win32/uk'    { $checksum = 'b81f1c66b96e5f5f3c26a4ec0fb594cf6b63529edaff7e94766a8c9b8d2d9da6' }
  'win32/uz'    { $checksum = '306ccf63173bab3ef61aa1f613ea311f60e321548eb768138faf0d76c8407f53' }
  'win32/vi'    { $checksum = '18030c10240863e838a24e2f759b548c9b9eb6b9c595b23f30cec801247a17f7' }
  'win32/zh-CN' { $checksum = '4611b1828b1856f3f17f888921af7f8ab384463d4650d5d198fa418221ba2416' }
  'win32/zh-TW' { $checksum = '966acd7debe0bd7ed08465f17b60ef90ed5f958255fcf6eee441eabfe8e13aea' }
  'win64/af'    { $checksum = 'a397c226ca40516d7af3b7014459ad5bff9373d463f2a97bf93d07b0cf5ab35e' }
  'win64/ar'    { $checksum = '3a44daa4acf5708cc2cd421b9c05fed2b6573d192a5171067b1d3e18ce74f59e' }
  'win64/ast'   { $checksum = '5d35c2a736a50b2b2a19095cfee922a4d2019863890ff3845efb192a263c0437' }
  'win64/be'    { $checksum = '2fe93fe0cf260612e45cf19cd28cef95fb542ecb8b24ef06749501e2f37a6091' }
  'win64/bg'    { $checksum = '318dcd117d7147882bc18ccd6114cd79020cec8eb5bf98aeb158604dc186353c' }
  'win64/br'    { $checksum = '991bd678b31fb5a980b6766f2e8277c368e0e6168adcdffcdf797671afe2a321' }
  'win64/ca'    { $checksum = '73def1acb63b8f2245753e4c90304f58d696ceaef1ffc0ac6ca60af46216b277' }
  'win64/cak'   { $checksum = 'b0e2ab0c0052ca29bb46b2d7d7454961e92568c2213322bf04eee9631dd3fbb1' }
  'win64/cs'    { $checksum = '2922a3d4d44a1cb47297b89f274fee1c080ab5fea1353a0e0e8bc9ef54ce17f2' }
  'win64/cy'    { $checksum = 'b572b2ad64d3180c53c15a681c84812205f965111e6db4a33273db6246a2925c' }
  'win64/da'    { $checksum = '6694ab793897b3a122dd350b4ce52d9bd859c980e1cbb5f354eb92186dfea1c7' }
  'win64/de'    { $checksum = 'fccd9e2b1a21f41fd4f3bd759e840b73a495fe4465631d7db8c6ac57164910f4' }
  'win64/dsb'   { $checksum = '7d9f320429fee0fe89fdadc155fdabb6c507bdc07cbf1b0a74d1f5b01f000b6d' }
  'win64/el'    { $checksum = '27374914d7c33ffc7099a4ba1446c15b73c3050a1a9ad9a455a339c9c1f1de4e' }
  'win64/en-CA' { $checksum = '75f037eaf6420da0d915ebbc2efc7c31407f4b2c90caca45a457db1cfc123078' }
  'win64/en-GB' { $checksum = '8bd6a90db2c429fd86bdc63504cb0f5ef7bc87635281ecc02a296c8436c1ff8c' }
  'win64/en-US' { $checksum = '8805f5f3fc0d35753f157db971aaad142fe808ab0efa8f909bf49bb71bc79216' }
  'win64/es-AR' { $checksum = '63d379680b1469f58eb82bcbbcc76bd7d41af2a79adbd8d5a25d7f195839d541' }
  'win64/es-ES' { $checksum = '85703511b6213c67d0eb7e0a0db2e6f8a4b3dbb74756aeca9cfa292a9225d882' }
  'win64/es-MX' { $checksum = '6711155db783040781d01ece60b1471f7dba8c469e055d11c394a24a33c9bcaa' }
  'win64/et'    { $checksum = '98d0822098826da334a9f3135efb09d7a6b5f261bddacae87bab72a118226a1b' }
  'win64/eu'    { $checksum = '8e68c22bc5d1d49e77cc38e54e810e389c4cfa9cbc58ebac43e2bc494ff6e631' }
  'win64/fi'    { $checksum = 'd9d649b5331ffde8cc3f89ec3d894c3415e1718aeece9c69491f4a4861c9193b' }
  'win64/fr'    { $checksum = '3ffc5bf0af7ea963c79268fb9d8703cdb84c4f3e39514a27a42beaa634707d2b' }
  'win64/fy-NL' { $checksum = '0b595fae8d3cef7c8ed6c21361b93f4a1c45904d0d4faf37e1bdbfa252cfd341' }
  'win64/ga-IE' { $checksum = 'a59f0512d4b5fe8847ba8d818f5f966c45aa70acfa424abd777b64d41aa5b54b' }
  'win64/gd'    { $checksum = 'c8b7dbedc7689057b9609b1361a3df5d4959933c9b16e4653fe2bfdc462f518e' }
  'win64/gl'    { $checksum = '7d4f831b36f29f5438ead6928ad6b9c18768ca1843840aacb8214675beb8508b' }
  'win64/he'    { $checksum = '46080266f51bf85b222867756b0ffcf3c1df9a815cc45deaa00a69ff5a666db6' }
  'win64/hr'    { $checksum = 'acc745a7d88b912a2eed121b3224c129263fc16416e6f7b2df1f4b06ac94daa5' }
  'win64/hsb'   { $checksum = '113d966d064c04c9ff365919db7013c06b1972732e10f0fd8ac495e53a211837' }
  'win64/hu'    { $checksum = '3502d23fb069865e735e584417eafd21405117a82a6086ee92f6da7d7fb44623' }
  'win64/hy-AM' { $checksum = 'acdc5819d19c4ebed63e7b006d2921b84dd9bc68e9394c5ed8f697b405b5865a' }
  'win64/id'    { $checksum = 'dab4748b2d63b0bec7925347172aeef689b823e2909a215653673916bc227bf2' }
  'win64/is'    { $checksum = '179f2bddd41e0dfdaf5dafb78e51dfd20db51350ddea70dcad8021ac78aace05' }
  'win64/it'    { $checksum = '971367e8c8b7b691c8fcb544ad3cbb4d6cf3ab62ebe6a308abb27168692cbe0a' }
  'win64/ja'    { $checksum = '98e7a55e9068942cd1fd66ffdd63528b83942ed76d1ec9ff399286060edfca2d' }
  'win64/ka'    { $checksum = '42d611140b8b4d0cd96720ea94f49210dddde00b56a8ab7cda3726ebae55fb2d' }
  'win64/kab'   { $checksum = 'e6cd9da68176535086c10903be3fbd333f11efe123d0a68139eba3dc826339c8' }
  'win64/kk'    { $checksum = '8aac716a72d4c6840f33512d392db9d5ac79b186c94a4348d61ae456564f11e5' }
  'win64/ko'    { $checksum = '7ed517a0f115eb84a428820b2cd78fb3b6a44eb9f5ced16a72fe4cf549dd70e0' }
  'win64/lt'    { $checksum = 'f73a581c2441f564ee3194398e35c655611477b2e0a211024672980b23af0283' }
  'win64/lv'    { $checksum = '8aacdef98dd102560e51479318f573c7a6d7a4ef8f0a42482e7d568c02e0be60' }
  'win64/ms'    { $checksum = 'ec2ac3fffc6835d151ed38b1821868acdf08dfebd6aebe99dbe966f1ea3e1811' }
  'win64/nb-NO' { $checksum = 'ebf69b805cae71dfb52c054e5c78530a739a2f4b521a55d5dde86a1a0cb45c3a' }
  'win64/nl'    { $checksum = '329988eaee40f8e992ddcab461834319c020d85e03d64458ab84f435d6a38151' }
  'win64/nn-NO' { $checksum = '77944546d8344d00c536f2ac52ca6b234bef766998bed04d115dbf3456d7b4f3' }
  'win64/pa-IN' { $checksum = '93b646d5f74acfa68e9cfd08dac13e68f53fa1f3446a1b77358d7ee65b06b71b' }
  'win64/pl'    { $checksum = 'dcfa9fa587b026b2469f8cc9c133cd22651a27302b41c9667622f5858ad3be98' }
  'win64/pt-BR' { $checksum = '14a790d0b989e6cb2e7d8d4cf7bc67f7e24be485f8445e7422db447a6e919c2d' }
  'win64/pt-PT' { $checksum = 'f6e3e02f41ccae1c0f1ffaea68c2fd6adf1627f487dd7110247ab62f82316190' }
  'win64/rm'    { $checksum = '03b4d51aff900247377b2aa25eba165fe62e5ef841bce98842e35a473efd44ff' }
  'win64/ro'    { $checksum = 'e83400bcdeb738d21df47eed0b75592dbf6d3571dc2f6532a2446c198c263de5' }
  'win64/ru'    { $checksum = 'a6a7bee7e13fb2c9a42b9d2f8cdbcc4f1c6fbc5ba105412c98da52133d10a741' }
  'win64/sk'    { $checksum = '0a22311bd37829c3aeafaac5b21e0712ab1cb1aee1d0e509072f158f554f3929' }
  'win64/sl'    { $checksum = 'c25f97810546a1383a60583b8da2b500ffc5d5e25fd28accc306e6db7751df6f' }
  'win64/sq'    { $checksum = '6c01abcc4b906af6e0641c431e74a32e7e31b94130d4e5e14b6b15b23b8d48aa' }
  'win64/sr'    { $checksum = 'cf950e25f18e053669357557458afa650f31299bc71a96fc10209b4d131bbaa8' }
  'win64/sv-SE' { $checksum = 'e371215bdb3a3417cd6c302e71a6b863f33e8a8401fc3cb3b8116b46344ba005' }
  'win64/th'    { $checksum = '127e60c2887403afa2df449462ad22b679cd56ec7a26256a3c817389ade6b1ad' }
  'win64/tr'    { $checksum = '786f097ae3f8db94361d74b219100729034e0e4cfb19f69706c3e8a023197d1f' }
  'win64/uk'    { $checksum = '69b239ae132aafeaa62076011a42c5ab43c83236b4a813da7a8f1957e1768522' }
  'win64/uz'    { $checksum = '0412e5fa5edbabada083b1e43f7cc0a409ea23eeed4ff86dea0b11137d544967' }
  'win64/vi'    { $checksum = 'ed457dd0b4e978f06f1a89a099e39011c5f212799a8666eb0b52cd795ca18d22' }
  'win64/zh-CN' { $checksum = '98e24186199fec82909a2b784bdfce16270c0db077a5a121f5ea5b4ac32fb43a' }
  'win64/zh-TW' { $checksum = '0685bbf0ecac3d5147f04574bcf52f277003f87d2c69165441f02d00d5c2b9ae' }
  default       { throw "No Thunderbird $version installer found for '$arch/$language'." }
}
# </checksums>

$url = "$baseUrl/$arch/$language/Thunderbird%20Setup%20$version.exe"

Install-ChocolateyPackage -PackageName $env:ChocolateyPackageName -FileType 'exe' -Url $url `
                          -Checksum $checksum -ChecksumType 'sha256' -SilentArgs '-ms' -ValidExitCodes @(0)
