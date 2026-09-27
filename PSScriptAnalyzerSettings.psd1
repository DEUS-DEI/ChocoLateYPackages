# PSScriptAnalyzer settings of this repository. Expected result: zero findings.
#   Invoke-ScriptAnalyzer -Path . -Recurse -Settings .\PSScriptAnalyzerSettings.psd1
# Every rule turned off here says why it does not apply; real findings are fixed in the code.
@{
    Severity     = @('Error', 'Warning', 'Information')

    ExcludeRules = @(
        # update_all.ps1 (and menu.bat's API key prompt) are interactive console scripts: the colored
        # progress messages and the summary table are meant for the person (or CI log) watching the run.
        # Since PowerShell 5.0 Write-Host writes to the Information stream, so it can still be captured or
        # silenced. Write-Output is not a replacement: it would turn the messages into return values
        # (au_GetLatest of thunderbird-nightly must return only 'ignore', and update_all.ps1 reads the last
        # object that each update.ps1 outputs).
        'PSAvoidUsingWriteHost'
    )

    Rules        = @{
        # Invoke-Tool (update_all.ps1) is a pass-through wrapper for native programs (choco, git): it has no
        # parameters and forwards $args as the program's command line, so its arguments cannot be named.
        PSAvoidUsingPositionalParameters = @{
            Enable           = $true
            CommandAllowList = @('Invoke-Tool')
        }

        # The scripts are run with Windows PowerShell 5.1 (update_all.bat, menu.bat and the GitHub workflow
        # call "powershell"); 7.0 keeps them valid in pwsh too.
        PSUseCompatibleSyntax            = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
    }
}
