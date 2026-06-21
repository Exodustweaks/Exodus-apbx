$Path = "HKCU:\AppEvents\Schemes"
$Keyname = "(Default)"
$SetValue = ".None"

New-ItemProperty -Path $Path -Name $Keyname -Value $SetValue -Force

Get-ChildItem -Path "HKCU:\AppEvents\Schemes\Apps" | 
    Get-ChildItem | 
    Get-ChildItem | 
    Where-Object { $_.PSChildName -eq ".Current" } |
    Set-ItemProperty -Name $Keyname -Value ""
