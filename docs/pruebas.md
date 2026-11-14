# Pruebas y análisis estático

Hasta el 2026-11-14 esto estaba repartido entre `tests/README.md` y las secciones «Análisis estático» y «Pruebas en
Windows» del README.

## Análisis estático (PSScriptAnalyzer)

`tests/PSScriptAnalyzerSettings.psd1` guarda la configuración del analizador: cada regla desactivada explica por qué no aplica y además se comprueba que la sintaxis funcione en Windows PowerShell 5.1. Desde la raíz del repo debe dar **cero avisos**:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser   # solo la primera vez
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\tests\PSScriptAnalyzerSettings.psd1
```

El analizador no lee los `.bat`, así que la parte PowerShell de cada `Scripts\*.bat` (lo que va detrás de la línea `### POWERSHELL ###`) se analiza aparte, como hace el workflow `Tests`; la línea que da es la del `.bat`:

```powershell
. .\Scripts\lib\Lanzar.ps1
Get-ChildItem .\Scripts\*.bat | Where-Object { Select-String -LiteralPath $_.FullName -Pattern '^### POWERSHELL ###\s*$' -Quiet } | ForEach-Object {
    Invoke-ScriptAnalyzer -ScriptDefinition (Get-ChocoSeccionBat -Ruta $_.FullName -Texto) -Settings .\tests\PSScriptAnalyzerSettings.psd1
}
```

**PowerShell v2 no lo comprueba el analizador.** Los scripts de `tools/` se ejecutan al instalar y tienen que funcionar en PowerShell v2 ([mantenimiento](mantenimiento.md), «Cumplimiento», punto 7), pero PSScriptAnalyzer solo sabe comprobar la sintaxis desde la 3.0 (con `2.0` no comprueba nada y no avisa), así que los cero avisos no lo garantizan. Esta búsqueda aparte no debe encontrar nada; cada patrón es algo que no existe en v2 (`[ordered]`, `[pscustomobject]`, `-in`/`-notin`, `$PSItem`, `$using:`, `$PSScriptRoot` fuera de módulos, `Where-Object Nombre -eq ...`, `::new()`, `class`, `#requires -Version 3` o más, `Get-Content -Raw`, `-NoNewline` y los cmdlets de la 3.0 en adelante). **No es exhaustiva**: busca lo más común, y que no encuentre nada no garantiza que el script funcione en v2; eso solo lo asegura probarlo con PowerShell v2.

```powershell
Select-String -Path .\Paquetes\actuales\*\tools\*.ps1 -Pattern '\[ordered\]', '\[pscustomobject\]', '\$PSItem\b', '\s-(not)?in\s', '::new\(', '\$using:', '^\s*class\s', '\$PSScriptRoot', 'Where-Object\s+\w+\s+-\w', 'Invoke-WebRequest', 'Invoke-RestMethod', 'ConvertFrom-Json', 'ConvertTo-Json', 'Get-CimInstance', '#requires\s+-version\s+[3-9]', 'Get-Content\b.*\s-Raw\b', '-NoNewline\b', '\[array\]\s*\$\w+\s*=.*Get-UninstallRegistryKey'
```

El último patrón busca `[array]$x = Get-UninstallRegistryKey ...`: el helper devuelve `$null` cuando no encuentra nada, y en v2 `$null` no tiene `.Count`. Se usa `@(Get-UninstallRegistryKey ... | Where-Object { $_ })`, que siempre es un array.

## Pruebas en Windows (Pester 5 en Windows PowerShell 5.1)

`tests/` prueba lo que solo se puede ver en Windows: `cmd.exe` con los `.bat`, Windows PowerShell 5.1 y los helpers reales de Chocolatey. Corren en el workflow `Tests` (`.github/workflows/tests.yml`) en cada PR y se pueden ejecutar en local sin permisos de administrador:

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -Force -SkipPublisherCheck   # solo la primera vez
Import-Module Pester -RequiredVersion 5.7.1
Invoke-Pester .\tests -Output Detailed
```

**No publican nada ni cambian el sistema:**

- `choco` es un falso (`tests/fakes/FakeChoco.cs`, compilado con `Add-Type` en la carpeta temporal de Pester) que solo anota sus argumentos, con la API key enmascarada. Antes de empezar se comprueba con `where.exe $PATH:choco` que va antes que el `choco` real en el `PATH`; si no, las pruebas se detienen. (`where.exe choco` sin `$PATH:` busca primero en la carpeta actual y siempre encontraría el falso; la prueba `test safety net` comprueba que la verificación sí salta.)
- `Scripts\update_all.bat` se prueba con un módulo Chocolatey-AU de mentira y un repositorio Git cuyo remoto es una carpeta local.
- Los scripts de `tools/` se ejecutan con los helpers reales de Chocolatey, pero las funciones que instalan o desinstalan están simuladas (`Mock`), y el registro de programas instalados es una lista de entradas falsas. Solo `flarectl` descarga y descomprime de verdad, desde un `.tar.gz` pequeño creado en la carpeta temporal (URL `file:`).
- `Scripts\vendor_catalog.bat` corre desde una copia en la carpeta temporal, con un catálogo de fabricantes inventados. Ninguna petición sale a la red: `Invoke-RestMethod` e `Invoke-WebRequest` están simulados y fallan ante cualquier dirección que no conozcan. El token de GitHub es uno falso y el `gh` real no se llega a ejecutar.

**Cómo se prueban los `.bat` con su PowerShell dentro** (desde el 2026-11-14): cada prueba copia el `.bat` con su cargador a `<carpeta temporal>\Scripts\` (`Copy-RepoScript` de `TestHelpers.ps1`), con `Paquetes\` y los datos al lado, como en el repositorio. Por `cmd.exe` se corre el `.bat` tal cual; `update_all.bat` en otro proceso como lo hace su cabecera (`powershell.exe -File Scripts\lib\Lanzar.ps1 "<el .bat>" <argumentos>`); y `vendor_catalog.bat` en el mismo proceso, con los `Mock` de Pester, por `tests\Invoke-Section.ps1`, que corre la parte PowerShell con una tabla de parámetros y su propio ámbito de script. Para leer funciones sueltas sin correr el script, `Get-ChocoSeccionBat -Texto` (de `Scripts\lib\Lanzar.ps1`) da el código de la sección.

| Archivo | Qué prueba |
| :--- | :--- |
| `Scripts.Tests.ps1` | Los nuspec de `Paquetes/descontinuados/` (guía de deprecación, y que un bridge con dependencia prerelease sea también prerelease, porque si no `choco` no la resuelve), `Scripts\push_deprecated.bat` (solo publica los bridges y nunca en la carpeta de quien lo llama, código de salida, también cuando `choco` revienta con un código negativo), la cabecera de `Scripts\update_all.bat` (argumentos y código de salida, con un cargador de mentira), `Scripts\menu.bat` (opciones 1-3, entradas hostiles, fin de la entrada) y la parte PowerShell de `update_all.bat` (`-NoPush`, `-Force`, push fallido, versión ya publicada en Chocolatey, rutas con corchetes y que todos los paquetes reales pasan la comprobación previa al empaquetado) desde una ruta con `^ ( ) & !` y espacios |
| `Packages.Tests.ps1` | Desinstaladores (0, 1 o 2 coincidencias, rutas con espacios, argumentos, MSI, Fenix 2.x/3.x), una descarga con sha256 por instalador, `/Arch` y `/Language` de Thunderbird, el ayudante que acepta el aviso del instalador de Fenix 3.x (contra cuadros de diálogo reales, que se cierran solos en un instante) y la extracción real de `flarectl` (que no deja la descarga en la carpeta temporal, tampoco si falla el checksum). Los scripts corren con `Set-StrictMode -Version 2`, una aproximación a PowerShell v2 (no la sustituye). Se omiten si Chocolatey no está instalado, salvo la comprobación estática de que cada descarga lleva un checksum escrito en el script (regla CPMR0073 del validador de Chocolatey), que solo lee los scripts |
| `Catalog.Tests.ps1` | `Scripts\lib\vendor_catalog.psd1` (cada producto con su fabricante, canal y los campos de su fuente; sin duplicados; patrones válidos) y la parte PowerShell de `Scripts\vendor_catalog.bat`: la comparación de versiones con el paquete de Chocolatey (estables, *fix versions*, betas y candidatas, y lo que no se puede ordenar), qué descargas cuentan como programa para Windows, qué release se toma en un canal de prereleases, y el informe completo con respuestas simuladas (cada tipo de fuente, descontinuados por repositorio archivado o por el catálogo, «sin versiones desde», la columna «En este repo», la búsqueda paginada en GitHub, los IDs supuestos con `(?)`, las preguntas exactas que se hacen a Chocolatey, que el token solo va a `api.github.com`, que no escribe nada en el repositorio, `-Vendor`, `-NoDiscover`, `-OutFile`, `-PassThru`, la ejecución sin token y los reintentos) y el modo `-Install` con descargas, firmas y ejecuciones simuladas: de dónde sale cada instalador (dirección fija, archivo de un release, la fuente de versiones), el idioma y su alternativa en inglés, cómo se ejecuta un `.msi` y un `.exe`, que un instalador de usuario no pide elevación, que no se ejecuta nada sin firma válida o con otro firmante, los códigos de salida, `-WhatIf`, `-Yes` y que una descarga que no sea `https` se rechaza; y el índice de winget con su árbol y sus manifiestos simulados: qué carpetas son paquetes, cuál es la última versión, qué instalador del manifiesto se elige (arquitectura, idioma, ámbito), sus argumentos silenciosos, y que no se ejecuta nada cuyo SHA256 no sea el del manifiesto |

`TestHelpers.ps1` tiene las funciones comunes: copiar un script de `Scripts\` con su cargador a una carpeta temporal, ejecutar un `.bat` con la entrada desde un archivo (como teclas pulsadas una tras otra; desde una tubería `set /p` leería de más) y matar el árbol de procesos si no termina a tiempo.
