#Requires -RunAsAdministrator

# ==============================
# Load Dependencies
# ==============================
$path = Join-Path $PSScriptRoot 'RapidResources\YamlDotNet.dll'
if (!(Test-Path $path)) {return}
Add-Type -Path $path

function ConvertFrom-Yaml {
    [CmdletBinding()]
    param ([Parameter(Position=0)]$path)
    
    $parse = {
        param ($item)
        $type = $item.GetType().Name
        switch ($type) {
            'YamlMappingNode' {
                $map = [ordered]@{}
                foreach ($entry in $item) {$map.($entry.Key.Value) = & $parse $entry.Value}
                return $map
            }
            'YamlSequenceNode' {
                $arr = @()
                foreach ($entry in $item) {$arr += & $parse $entry}
                return ,$arr
            }
            'YamlScalarNode' {
                $value = $item.Value
                if ($item.Tag -eq 'tag:yaml.org,2002:int' -or $value -match '^-?\d+$') {return [int]$value}
                if ($item.Tag -eq 'tag:yaml.org,2002:bool' -or $value -match '^(true|false|yes|no|on|off)$') {return [bool]::Parse($value.Replace('yes','true').Replace('no','false').Replace('on','true').Replace('off','false'))}
                return $value
            }
            default {return $item}
        }
    }

    if ($path) {
        $input = [System.IO.File]::OpenText($path)
        try {
            $obj = New-Object YamlDotNet.RepresentationModel.YamlStream
            $obj.Load([System.IO.TextReader]$input)
            if ($obj.Documents.Count -gt 0) {return & $parse $obj.Documents[0].RootNode}
        }
        finally {$input.Close()}
    }
}

# ==============================
# Execution
# ==============================
$src = Join-Path $PSScriptRoot '..\Configuration'
$mount = 'HKU\AME_UserHive_Default'
$arr = @()

if (!(Test-Path "Registry::$mount")) {
    return
}

if (Test-Path $src) {
    $list = gci $src -Filter *.yml -Recurse
    
    foreach ($item in $list) {
        $data = ConvertFrom-Yaml $item.FullName
        if ($data.actions) {
            foreach ($entry in $data.actions) {
                if ($entry.path) {
                    $values = @($entry.path)
                    foreach ($value in $values) {
                        if (![string]::IsNullOrWhiteSpace($value) -and $value -match '^HKCU\\') {
                            $regKey = $value.Substring(5)
                            if ($arr -notcontains $regKey) {
                                $arr += $regKey
                            }
                        }
                    }
                }
            }
        }
    }
}

foreach ($regKey in $arr) {
    $srcPath  = "Registry::HKCU\$regKey"
    $destPath = "HKU:\AME_UserHive_Default\$regKey" 
    
    if (Test-Path $srcPath) {
        if (!(Test-Path $destPath)) {mkdir $destPath *>$null}

        $sk = Get-Item $srcPath -EA 1
        foreach ($valName in $sk.GetValueNames()) {
            $valData = $sk.GetValue($valName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            $valKind = $sk.GetValueKind($valName).ToString()
            
            Set-RegistryValue -Path $destPath -Name $valName -Value $valData -Type $valKind
        }
    }
}