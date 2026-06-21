
Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' | 
    Where-Object { $_.Name -notmatch 'Xbl|Xbox' } |
    ForEach-Object {
        $regPath = "Registry::" + $_.PSPath.Substring($_.PSPath.IndexOf("HKEY_LOCAL_MACHINE"))

        try {
            $props = Get-ItemProperty -Path $regPath -ErrorAction Stop
            if ($null -ne $props.Start) {
                Set-ItemProperty -Path $regPath -Name 'SvcHostSplitDisable' -Value 1 -Type DWord -Force
                Write-Host "Set SvcHostSplitDisable for: $regPath"
            }
        } catch {
            Write-Warning "Could not access: $regPath"
        }
    }