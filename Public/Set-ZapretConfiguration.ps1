function Set-ZapretConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, ParameterSetName = "ByName")]
        [string] $Name,
        
        [Parameter(Position = 0, ParameterSetName = "ByObject")]
        [ZapretConfiguration] $Configuration
    )
    
    try {
        if (-not (Test-IsAdmin)) {
            throw "Administrator rights required to manage Zapret service"
        }
        
        if ($Name) {
            $Configuration = Get-ZapretConfiguration -Name $Name
        }
        
        if (-not $Configuration) {
            throw "No configuration specified"
        }
        
        $paths = Get-ZapretPaths
        $service = [ZapretService]::new($paths.BinPath, $paths.ListsPath, $paths.ConfigPath)
        
        if ($PSCmdlet.ShouldProcess($Configuration.Name, "Apply Zapret Configuration")) {
            Write-Host "Applying configuration: $($Configuration.Name)" -ForegroundColor Green
            Write-Host "Description: $($Configuration.Description)" -ForegroundColor Gray
            
            $service.Install($Configuration)
            
            Write-Host "Starting Zapret service..." -ForegroundColor Yellow
            $service.Start()
            
            Start-Sleep -Seconds 2
            $status = $service.GetStatus()
            
            if ($status.Running) {
                Write-Host "✅ Zapret service started successfully" -ForegroundColor Green
                Write-Host "Configuration: $($Configuration.Name)" -ForegroundColor Green
            }
            else {
                Write-Warning "⚠️ Service installed but not running. Status: $($status.Status)"
            }
        }
    }
    catch {
        Write-Error "Failed to set configuration: $_"
        throw
    }
}