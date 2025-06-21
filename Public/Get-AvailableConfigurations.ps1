function Get-AvailableConfigurations {
    $configDir = Join-Path $PSScriptRoot '..\Configurations'
    $files = Get-ChildItem -Path $configDir -Filter *.ps1 -ErrorAction SilentlyContinue

    $result = @()
    foreach ($file in $files) {
        . $file.FullName
        $funcName = 'New-' + ($file.BaseName) + 'Configuration'
        if (Get-Command $funcName -ErrorAction SilentlyContinue) {
            $conf = & $funcName
            $result += $conf
        }
    }
    return $result
}