# Helpers shared by the Pester tests (Windows PowerShell 5.1). See tests\README.md.

function Invoke-TestProcess {
    # Runs a program hidden, with stdin/stdout/stderr redirected and extra environment variables, and
    # kills the whole process tree if it does not finish in time (a hung .bat must not hang the tests).
    param(
        [Parameter(Mandatory = $true)] [string] $FilePath,
        [string] $Arguments = '',
        [Parameter(Mandatory = $true)] [string] $WorkingDirectory,
        [hashtable] $Environment = @{},
        [string] $InputText = '',
        [int] $TimeoutSeconds = 120
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $Arguments
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    foreach ($name in $Environment.Keys) {
        if ($null -eq $Environment[$name]) { $psi.EnvironmentVariables.Remove($name) }
        else { $psi.EnvironmentVariables[$name] = [string] $Environment[$name] }
    }
    $process = [System.Diagnostics.Process]::Start($psi)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if ($InputText) { $process.StandardInput.Write($InputText) }
    $process.StandardInput.Close()
    $finished = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $finished) {
        & "$env:SystemRoot\System32\taskkill.exe" /PID $process.Id /T /F | Out-Null
        $process.WaitForExit()
    }
    [pscustomobject]@{
        ExitCode = if ($finished) { $process.ExitCode } else { $null }
        TimedOut = -not $finished
        Output   = $stdout.Result
        Error    = $stderr.Result
    }
}

function Invoke-TestBatch {
    # Runs a .bat through cmd.exe the way a user does: "cmd /c <script> <args>" (no AutoRun, no delayed
    # expansion). $Script may be a full path or a path relative to $WorkingDirectory such as .\menu.bat.
    # The input comes from a file ("< file"), like keys typed one after another: from a pipe, "set /p"
    # would read ahead and lose the following lines. Without input, stdin is NUL.
    param(
        [Parameter(Mandatory = $true)] [string] $Script,
        [string] $Arguments = '',
        [Parameter(Mandatory = $true)] [string] $WorkingDirectory,
        [hashtable] $Environment = @{},
        [string] $InputText = '',
        [int] $TimeoutSeconds = 120
    )
    $inputFile = [System.IO.Path]::GetTempFileName()
    try {
        [System.IO.File]::WriteAllText($inputFile, $InputText, (New-Object System.Text.ASCIIEncoding))
        $cmd = Join-Path $env:SystemRoot 'System32\cmd.exe'
        $commandLine = ('/d /v:off /s /c ""{0}" {1} < "{2}""' -f $Script, $Arguments, $inputFile)
        Invoke-TestProcess -FilePath $cmd -Arguments $commandLine -WorkingDirectory $WorkingDirectory `
            -Environment $Environment -TimeoutSeconds $TimeoutSeconds
    } finally {
        Remove-Item -LiteralPath $inputFile -ErrorAction SilentlyContinue
    }
}

function Install-FakeChoco {
    # Compiles tests\fakes\FakeChoco.cs into <Directory>\choco.exe and checks that cmd.exe finds it before
    # any real choco when <Directory> is first in PATH. Returns the PATH value to give to the scripts.
    param([Parameter(Mandatory = $true)] [string] $Directory)
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    $source = Get-Content -Path (Join-Path $PSScriptRoot 'fakes\FakeChoco.cs') -Raw
    $exe = Join-Path $Directory 'choco.exe'
    Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $exe -OutputType ConsoleApplication
    $path = "$Directory;$env:PATH"
    $where = Invoke-TestProcess -FilePath (Join-Path $env:SystemRoot 'System32\where.exe') -Arguments 'choco' `
        -WorkingDirectory $Directory -Environment @{ PATH = $path }
    $first = @($where.Output -split "`r?`n" | Where-Object { $_ })[0]
    if ($first -ne $exe) { throw "The fake choco is not the first one in PATH ($first): the tests could publish for real." }
    $path
}

function Get-FakeLog {
    # Lines written by the fake choco (empty array when it was never called)
    param([Parameter(Mandatory = $true)] [string] $Path)
    if (Test-Path -LiteralPath $Path) { @(Get-Content -LiteralPath $Path) } else { @() }
}

function Clear-ReadOnlyAttribute {
    # Git makes its object files read-only, which stops Pester from deleting TestDrive
    param([Parameter(Mandatory = $true)] [string] $Path)
    Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
        Where-Object { $_.IsReadOnly } | ForEach-Object { $_.IsReadOnly = $false }
}
