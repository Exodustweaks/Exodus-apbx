$CabPath = "C:\Windows\NoDefender.cab"

if (Test-Path $CabPath) {
    Remove-WindowsPackage -Online -PackagePath $CabPath
}
