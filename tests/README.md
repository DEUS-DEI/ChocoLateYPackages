# Pruebas (Pester 5 en Windows PowerShell 5.1)

Prueban lo que solo se puede ver en Windows: `cmd.exe` con los `.bat`, Windows PowerShell 5.1 y los helpers reales de Chocolatey. Corren en el workflow `Tests` (`.github/workflows/tests.yml`) en cada PR y se pueden ejecutar en local sin permisos de administrador:

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -Force -SkipPublisherCheck   # solo la primera vez
Import-Module Pester -RequiredVersion 5.7.1
Invoke-Pester .\tests -Output Detailed
```

**No publican nada ni cambian el sistema:**

- `choco` es un falso (`fakes/FakeChoco.cs`, compilado con `Add-Type` en la carpeta temporal de Pester) que solo anota sus argumentos, con la API key enmascarada. Antes de empezar se comprueba con `where.exe $PATH:choco` que va antes que el `choco` real en el `PATH`; si no, las pruebas se detienen. (`where.exe choco` sin `$PATH:` busca primero en la carpeta actual y siempre encontraría el falso; la prueba `test safety net` comprueba que la verificación sí salta.)
- `update_all.ps1` se prueba con un módulo Chocolatey-AU de mentira y un repositorio Git cuyo remoto es una carpeta local.
- Los scripts de `tools/` se ejecutan con los helpers reales de Chocolatey, pero las funciones que instalan o desinstalan están simuladas (`Mock`), y el registro de programas instalados es una lista de entradas falsas. Solo `flarectl` descarga y descomprime de verdad, desde un `.tar.gz` pequeño creado en la carpeta temporal (URL `file:`).

| Archivo | Qué prueba |
| :--- | :--- |
| `Scripts.Tests.ps1` | `push_deprecated.bat` (solo publica los bridges y nunca en la carpeta de quien lo llama, código de salida, también cuando `choco` revienta con un código negativo), `update_all.bat` (argumentos y código de salida), `menu.bat` (opciones 1-3, entradas hostiles, fin de la entrada) y `update_all.ps1` (`-NoPush`, `-Force`, push fallido, versión ya publicada en Chocolatey, rutas con corchetes y que todos los paquetes reales pasan la comprobación previa al empaquetado) desde una ruta con `^ ( ) & !` y espacios |
| `Packages.Tests.ps1` | Desinstaladores (0, 1 o 2 coincidencias, rutas con espacios, argumentos, MSI, Fenix 2.x/3.x), una descarga con sha256 por instalador, `/Arch` y `/Language` de Thunderbird y la extracción real de `flarectl`. Los scripts corren con `Set-StrictMode -Version 2`, una aproximación a PowerShell v2 (no la sustituye). Se omiten si Chocolatey no está instalado |

`TestHelpers.ps1` tiene las funciones comunes: ejecutar un `.bat` con la entrada desde un archivo (como teclas pulsadas una tras otra; desde una tubería `set /p` leería de más) y matar el árbol de procesos si no termina a tiempo.
