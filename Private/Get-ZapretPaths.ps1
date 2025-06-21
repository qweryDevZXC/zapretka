function Get-ZapretPaths {
    $moduleRoot = (Get-Module ZapretManager).ModuleBase
    if (-not $moduleRoot) {
        $moduleRoot = $PSScriptRoot
    }
    
    return @{
        ModuleRoot = $moduleRoot
        BinPath = Join-Path $moduleRoot "bin"
        ListsPath = Join-Path $moduleRoot "lists"
        ConfigPath = Join-Path $moduleRoot "config"
    }
}