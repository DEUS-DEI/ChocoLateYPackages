# PSScriptAnalyzer settings of this repository (in tests\ since 2026-11-14). Expected result: zero findings.
#   Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\tests\PSScriptAnalyzerSettings.psd1
# plus the PowerShell part of each Scripts\*.bat, with -ScriptDefinition (the workflow Tests and docs\pruebas.md).
# Every rule turned off here says why it does not apply; real findings are fixed in the code.
@{
    Severity     = @('Error', 'Warning', 'Information')

    ExcludeRules = @(
        # Scripts\update_all.bat (and menu.bat's API key prompt) are interactive console scripts: the colored
        # progress messages and the summary table are meant for the person (or CI log) watching the run.
        # Since PowerShell 5.0 Write-Host writes to the Information stream, so it can still be captured or
        # silenced. Write-Output is not a replacement: it would turn the messages into return values
        # (au_GetLatest of thunderbird-nightly must return only 'ignore', and update_all.bat reads the last
        # object that each update.ps1 outputs).
        'PSAvoidUsingWriteHost'
    )

    Rules        = @{
        # Invoke-Tool (Scripts\update_all.bat) is a pass-through wrapper for native programs (choco, git): it has
        # no parameters and forwards $args as the program's command line, so its arguments cannot be named.
        PSAvoidUsingPositionalParameters = @{
            Enable           = $true
            CommandAllowList = @('Invoke-Tool')
        }

        # The scripts are run with Windows PowerShell 5.1 (the header of each Scripts\*.bat, menu.bat and the
        # GitHub workflow call "powershell"); 7.0 keeps them valid in pwsh too.
        # The install scripts in tools/ of each package must also run on PowerShell v2 (docs\mantenimiento.md,
        # point 7). This rule cannot check that: its lowest target is 3.0, and '2.0' is silently ignored.
        # docs\pruebas.md has a separate Select-String check for the v3+ constructs to avoid in tools/.
        PSUseCompatibleSyntax            = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
    }
}
