# Runs the PowerShell part of a Scripts\*.bat in this process, with named parameters given as a hashtable, the way
# the tests ran "& script.ps1 @Parameters" when the scripts were .ps1 files: the section gets this file's script
# scope (its $script: variables do not leak into the test), its exit ends only this file, the Pester mocks of the
# caller apply and its output comes back as objects. Forwarding a hashtable through Lanzar.ps1, which only has
# $args, would turn -Switch:$true into two separate arguments. See docs\pruebas.md.
#   & .\tests\Invoke-Section.ps1 -Bat <copy>\Scripts\vendor_catalog.bat -Parameters @{ PassThru = $true }
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $Bat,
    [hashtable] $Parameters = @{}
)
. (Join-Path (Split-Path -Parent $Bat) 'lib\Lanzar.ps1')
$section = Get-ChocoSeccionBat -Ruta $Bat
& $section @Parameters
