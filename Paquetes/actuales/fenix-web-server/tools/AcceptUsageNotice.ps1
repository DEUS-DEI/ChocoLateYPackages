# The Fenix 3.x setup program shows this notice even in silent mode (/S) and has no switch to skip it, so an
# unattended install waits forever:
#
#   "I understand this application collects non-personally identifiable usage statistics from time to
#    time. This information does not contain any data about you or your company. [...]"   [OK] [Cancel]
#
# chocolateyinstall.ps1 runs this script in the background while the setup runs. It answers OK to that
# notice and to nothing else (a dialog of Fenix whose text mentions the usage statistics), and ends. The
# package description tells the user that installing the pre-release accepts the notice.
param([int] $TimeoutSeconds = 3600)

$ErrorActionPreference = 'Stop'

# The window title is an IntPtr so that "any title" can be passed: PowerShell turns $null into '' for a string
$user32 = Add-Type -Name User32 -Namespace FenixSetup -PassThru -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string className, IntPtr title);
[DllImport("user32.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wParam, System.Text.StringBuilder lParam);
[DllImport("user32.dll")]
public static extern bool PostMessage(IntPtr window, uint message, IntPtr wParam, IntPtr lParam);
'@

function Get-WindowText([IntPtr] $Window) {
  $text = New-Object System.Text.StringBuilder 2048
  [void]$user32::SendMessage($Window, 0x000D, [IntPtr]$text.Capacity, $text)  # WM_GETTEXT
  $text.ToString()
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
  # Message boxes are top-level dialogs (class #32770) with their text in a Static control. The title
  # ("Fenix Setup") could be translated, the product name in it and the notice itself are not.
  $dialog = [IntPtr]::Zero
  while (($dialog = $user32::FindWindowEx([IntPtr]::Zero, $dialog, '#32770', [IntPtr]::Zero)) -ne [IntPtr]::Zero) {
    if ((Get-WindowText $dialog) -notlike '*Fenix*') { continue }
    $label = [IntPtr]::Zero
    while (($label = $user32::FindWindowEx($dialog, $label, 'Static', [IntPtr]::Zero)) -ne [IntPtr]::Zero) {
      if ((Get-WindowText $label) -like '*usage statistics*') {
        # WM_COMMAND with IDOK: the OK button, whatever its caption is in the language of Windows
        [void]$user32::PostMessage($dialog, 0x0111, [IntPtr]1, [IntPtr]::Zero)
        exit 0
      }
    }
  }
  Start-Sleep -Milliseconds 500
}
exit 1
