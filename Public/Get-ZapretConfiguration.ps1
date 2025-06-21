function Get-ZapretConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Name
    )
    
    try {
        $configurations = Get-AvailableConfigurations
        
        if ($Name) {
            $config = $configurations | Where-Object { $_.Name -eq $Name }
            if (-not $config) {
                throw "Configuration '$Name' not found"
            }
            return $config
        }
        
        return $configurations
    }
    catch {
        Write-Error "Failed to get configuration: $_"
        throw
    }
}