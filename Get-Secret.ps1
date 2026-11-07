# Get-ChocoSecret: one secret (an API key or a token) for the scripts of this repository, looked up in the order
# every repository of the owner uses (2026-11-07):
#   1. the environment of this run (in GitHub Actions the workflow puts the repository secrets there);
#   2. the environment variables saved in Windows (user, then machine), even if this console is older than them;
#   3. the Windows Credential Manager: a generic credential named like the variable (kb's "Boveda.bat sincronizar"
#      puts them there), in UTF-8 or, made by hand in its window, in UTF-16;
#   4. a .env.var, .dev.var, .env or .dev.vars file in the root of the repository (NAME=value; all of them are in
#      .gitignore and never go to GitHub).
# Returns '' when there is none. It never prints the value nor where it came from. Dot-source it:
#   . (Join-Path $PSScriptRoot 'Get-Secret.ps1')
# A .bat runs it instead (push_deprecated.bat): "powershell -File Get-Secret.ps1 -Name NAME" writes only the value,
# for "for /f" to catch it, and nothing else. No param block on purpose: dot-sourced, it must not create a $Name
# variable in the caller's scope.
# Windows PowerShell 5.1 (also PowerShell 7). ASCII.

function Get-ChocoWindowsCredential {
    # The generic credential $Name of the Windows Credential Manager, trimmed, or '' (also outside Windows).
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$Name)
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { return '' }
    if (-not ('ChocoSecret.Credential' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace ChocoSecret {
    public static class Credential {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct Cred {
            public uint Flags;
            public uint Type;
            public string TargetName;
            public string Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public uint CredentialBlobSize;
            public IntPtr CredentialBlob;
            public uint Persist;
            public uint AttributeCount;
            public IntPtr Attributes;
            public string TargetAlias;
            public string UserName;
        }

        [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool CredRead(string target, uint type, uint flags, out IntPtr credential);

        [DllImport("advapi32.dll", EntryPoint = "CredFree")]
        private static extern void CredFree(IntPtr buffer);

        // The bytes of the generic credential (CRED_TYPE_GENERIC), or null if there is none.
        public static byte[] Read(string target) {
            IntPtr p;
            if (!CredRead(target, 1, 0, out p)) return null;
            try {
                Cred c = (Cred)Marshal.PtrToStructure(p, typeof(Cred));
                byte[] b = new byte[c.CredentialBlobSize];
                if (b.Length > 0) Marshal.Copy(c.CredentialBlob, b, 0, b.Length);
                return b;
            } finally {
                CredFree(p);
            }
        }
    }
}
'@
    }
    try { $bytes = [ChocoSecret.Credential]::Read($Name) } catch { return '' }
    if ($null -eq $bytes -or $bytes.Length -eq 0) { return '' }
    if ([Array]::IndexOf($bytes, [byte]0) -ge 0) { $text = [Text.Encoding]::Unicode.GetString($bytes) }
    else { $text = [Text.Encoding]::UTF8.GetString($bytes) }
    [Array]::Clear($bytes, 0, $bytes.Length)
    return $text.Trim()
}

function Get-ChocoEnvFileValue {
    # The value of $Name in a NAME=value file ('' if it is not there). Comments with #, "export " in front,
    # values between single or double quotes; the last line with the name wins.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )
    $found = ''
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $text = $line.Trim()
        if (-not $text -or $text.StartsWith('#')) { continue }
        $text = $text -replace '^export\s+', ''
        $equals = $text.IndexOf('=')
        if ($equals -lt 1 -or $text.Substring(0, $equals).Trim() -ne $Name) { continue }
        $value = $text.Substring($equals + 1).Trim()
        if ($value.Length -ge 2 -and ($value[0] -eq [char]'"' -or $value[0] -eq [char]"'") -and $value[$value.Length - 1] -eq $value[0]) {
            $value = $value.Substring(1, $value.Length - 2)
        } else {
            $value = ($value -split '\s#', 2)[0].Trim()
        }
        $found = $value
    }
    return $found
}

function Get-ChocoSecret {
    # One secret, in the order described at the top of this file, or ''. Never printed.
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true, Position = 0)][string]$Name)
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ($value -and $value.Trim()) { return $value.Trim() }
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        foreach ($scope in @('User', 'Machine')) {
            $value = [Environment]::GetEnvironmentVariable($Name, $scope)
            if ($value -and $value.Trim()) { return $value.Trim() }
        }
        $value = Get-ChocoWindowsCredential -Name $Name
        if ($value) { return $value }
    }
    # The root of the repository: the folder of this file, wherever the function is called from.
    $root = Split-Path -Parent $MyInvocation.MyCommand.ScriptBlock.File
    foreach ($file in @('.env.var', '.dev.var', '.env', '.dev.vars')) {
        $path = Join-Path $root $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $value = Get-ChocoEnvFileValue -Path $path -Name $Name
        if ($value) { return $value }
    }
    return ''
}

# Run by a .bat with "-Name NAME" (not dot-sourced): only the value, for "for /f".
if ($MyInvocation.InvocationName -ne '.' -and $args.Count -eq 2 -and $args[0] -eq '-Name') {
    $chocoSecretValue = Get-ChocoSecret -Name ([string]$args[1])
    if ($chocoSecretValue) { [Console]::Out.Write($chocoSecretValue) }
}
