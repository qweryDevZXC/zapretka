function Initialize-ZapretModule {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Warning "PowerShell 5.1 or higher is recommended"
    }
    
    $requiredCommands = @('sc.exe', 'net.exe')
    foreach ($cmd in $requiredCommands) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Warning "Required command not found: $cmd"
        }
    }
    
    Write-Verbose "ZapretManager module initialized"
}