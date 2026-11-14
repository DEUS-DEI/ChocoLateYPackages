# The loader of the scripts in Scripts\: runs the PowerShell part of a .bat.
#
# Since 2026-11-14 each script of this repository is ONE file, Scripts\<name>.bat, that also runs with a double
# click: on top a batch header that runs this loader with Windows PowerShell 5.1, and after the line
# "### POWERSHELL ###" the PowerShell code of the script (until then update_all.ps1 and vendor_catalog.ps1 were
# separate files, each with a small .bat that launched it). Same design as the scripts of the owner's other
# repositories (RQR, QRCBPS, kb).
#
# Usage:
#   powershell.exe -File Scripts\lib\Lanzar.ps1 "<path of the .bat>" [arguments]   (what the header does; also how to
#                                                                                   run a script from PowerShell
#                                                                                   without cmd.exe)
#   & Scripts\lib\Lanzar.ps1 Scripts\vendor_catalog.bat -NoDiscover -PassThru     (in the same process: the objects
#                                                                                   of -PassThru come back as objects)
#   . Scripts\lib\Lanzar.ps1                  (dot-sourced: only defines Get-ChocoSeccionBat, for the Pester tests
#                                              and the analysis of the .bat files in CI)
#
# Why this way:
# - powershell.exe -File only takes a file that ends in .ps1, and passing the arguments through a variable
#   (set VAR=%*) breaks with an & between quotes. With -File <this loader> "<.bat>" %* each argument arrives as cmd
#   sends it and is forwarded here with splatting, so the param() block of the script binds them as before.
# - The section is read with the PowerShell parser, giving it the path of the .bat as its file name: inside,
#   $PSScriptRoot is the folder of the .bat (Scripts) and $PSCommandPath the .bat, as in a .ps1 placed there. The
#   lines of the header become empty lines, so an error gives the line number of the .bat.
# - The .bat is ASCII (UTF-8 without BOM: with a BOM cmd does not recognize @echo off) and is always read as UTF-8.
# - It runs with & inside this script: each launch has its own script scope ($script:), and an exit in the section
#   ends this script with that code, like the exit of a .ps1.
# - Nothing is written to disk: no temporary files nor copies of the code.

function Get-ChocoSeccionBat {
    <#
    .SYNOPSIS
    The PowerShell part of a .bat (what follows the line "### POWERSHELL ###") as a script block, with the path of
    the .bat as its file and the line numbers of the .bat.
    .DESCRIPTION
    To run it: & (Get-ChocoSeccionBat -Ruta x.bat) @arguments. With -Texto it returns the code of the section (the
    header as empty lines) instead of the block, for PSScriptAnalyzer and to read its functions without running it.
    Throws when the .bat does not exist, has no marker line or has syntax errors.
    #>
    [CmdletBinding()]
    [OutputType([scriptblock], [string])]
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [switch]$Texto
    )
    # A relative path is relative to the current folder of PowerShell (not to the one of .NET, which does not follow
    # Set-Location).
    $completa = $Ruta
    if (-not [IO.Path]::IsPathRooted($completa)) { $completa = Join-Path -Path (Get-Location -PSProvider FileSystem).ProviderPath -ChildPath $completa }
    $completa = [IO.Path]::GetFullPath($completa)
    if (-not [IO.File]::Exists($completa)) { throw ('No existe el archivo ' + $completa + ': no hay nada que lanzar.') }
    $contenido = [IO.File]::ReadAllText($completa, (New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false))
    $lineas = [regex]::Split($contenido, '\r?\n')
    $marca = -1
    for ($i = 0; $i -lt $lineas.Length; $i++) {
        if ($lineas[$i].TrimEnd() -ceq '### POWERSHELL ###') { $marca = $i; break }
    }
    if ($marca -lt 0) { throw ('No encuentro la linea ### POWERSHELL ### en ' + $completa + ': sin ella no se donde empieza el codigo PowerShell.') }
    # One empty line for each line of the header and the marker: the first line of the section keeps its number.
    $codigo = ("`n" * ($marca + 1)) + [string]::Join("`n", $lineas, $marca + 1, $lineas.Length - $marca - 1)
    if ($Texto) { return $codigo }
    $tokens = $null
    $errores = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($codigo, $completa, [ref]$tokens, [ref]$errores)
    if ($errores.Count -gt 0) {
        throw (New-Object -TypeName System.Management.Automation.ParseException -ArgumentList (, [System.Management.Automation.Language.ParseError[]]$errores))
    }
    return $ast.GetScriptBlock()
}

if ($MyInvocation.InvocationName -ne '.') {
    # In constrained language mode (AppLocker or WDAC) the parser and [IO.File] are not allowed: say so here.
    if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
        Write-Warning 'El script no puede abrirse: la directiva del equipo (AppLocker o WDAC) pone PowerShell en modo restringido.'
        exit 1
    }
    if ($args.Count -lt 1 -or -not [string]$args[0]) { throw 'Uso: Lanzar.ps1 <ruta del .bat> [argumentos]' }
    # Odd names: the section runs inside this scope and sees them.
    $chocoLanzarSeccion = Get-ChocoSeccionBat -Ruta ([string]$args[0])
    $chocoLanzarResto = @()
    if ($args.Count -gt 1) { $chocoLanzarResto = @($args[1..($args.Count - 1)]) }
    # The arguments are bound first to a block with only the param() of the section: an unknown parameter gives the
    # error with the path of the .bat, not with a line of this loader.
    $chocoLanzarParam = $chocoLanzarSeccion.Ast.ParamBlock
    if ($chocoLanzarParam) {
        $chocoLanzarPrueba = [scriptblock]::Create(((@($chocoLanzarParam.Attributes | ForEach-Object { $_.Extent.Text }) + $chocoLanzarParam.Extent.Text) -join "`n"))
        try { & $chocoLanzarPrueba @chocoLanzarResto }
        catch [System.Management.Automation.ParameterBindingException] {
            $host.UI.WriteErrorLine($chocoLanzarSeccion.File + ' : ' + $_.Exception.Message)
            exit 1
        }
    }
    # No exit after it: the one of the section counts (if it does not exit, like a .ps1 that ends without exit).
    & $chocoLanzarSeccion @chocoLanzarResto
}
