param ([Parameter(Mandatory)][ValidateSet("Desktop","LockScreen")][string]$Mode, [Parameter(Mandatory)][string]$ImagePath)
$marker = Join-Path $env:windir 'FSOS\.personalization-applied'
if (Test-Path $marker) { exit 0 }
$img = (Get-Item $ImagePath -Force).FullName
if (-not (Test-Path $img)) { Write-Error "Not found: $img"; exit 1 }
if ($Mode -eq "Desktop") {
    Get-ChildItem "Registry::HKU" | ForEach-Object { [Microsoft.Win32.Registry]::SetValue("$($_.Name)\Control Panel\Desktop","WallPaper",$img,[Microsoft.Win32.RegistryValueKind]::String) }
    $cs = 'using System.Runtime.InteropServices; public class WPHelper { [DllImport("user32.dll",SetLastError=true,CharSet=CharSet.Auto)] static extern int SystemParametersInfo(int a,int b,string c,int d); public static void Set(string p){SystemParametersInfo(20,0,p,3);} }'
    if (-not ([System.Management.Automation.PSTypeName]'WPHelper').Type) { Add-Type -TypeDefinition $cs }
    [WPHelper]::Set($img)
} else {
    $tmp = Join-Path ([IO.Path]::GetDirectoryName($img)) ([Guid]::NewGuid().ToString() + [IO.Path]::GetExtension($img))
    Copy-Item $img $tmp
    [Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $m = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
    function Await($op,$rt) { $t = $m.MakeGenericMethod($rt).Invoke($null,@($op)); $t.Wait(-1)|Out-Null; $t.Result }
    function AwaitV($op) { $t = ([System.WindowsRuntimeSystemExtensions].GetMethods()|Where-Object{$_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and -not $_.IsGenericMethod})[0].Invoke($null,@($op)); $t.Wait(-1)|Out-Null }
    [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
    $f = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($tmp)) ([Windows.Storage.StorageFile])
    AwaitV ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($f))
    Remove-Item $tmp -Force
    [Microsoft.Win32.Registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization","LockScreenImage",$img,[Microsoft.Win32.RegistryValueKind]::String)
}