using namespace System.Collections.Generic

class ZapretFilter {
    [string] $Type
    [string] $Port
    [string] $Strategy
    [hashtable] $Parameters
    [string] $HostList
    [string] $IpSet
    
    ZapretFilter([string]$Type, [string]$Port, [string]$Strategy) {
        $this.Type = $Type
        $this.Port = $Port
        $this.Strategy = $Strategy
        $this.Parameters = @{}
    }
    
    [string] BuildFilterString([string]$BinPath, [string]$ListsPath) {
        $filterParts = @()
        $filterParts += "--filter-$($this.Type.ToLower())=$($this.Port)"
        
        if ($this.HostList) {
            $hostListPath = Join-Path $ListsPath $this.HostList
            $filterParts += "--hostlist=`"$hostListPath`""
        }
        
        if ($this.IpSet) {
            $ipSetPath = Join-Path $ListsPath $this.IpSet
            $filterParts += "--ipset=`"$ipSetPath`""
        }
        
        $filterParts += "--dpi-desync=$($this.Strategy)"
        foreach ($param in $this.Parameters.GetEnumerator()) {
            if ($param.Value -is [string] -and $param.Value.Contains('\')) {
                # Путь к файлу
                $filePath = $param.Value.Replace('%BIN%', $BinPath)
                $filterParts += "--$($param.Key)=`"$filePath`""
            }
            else {
                $filterParts += "--$($param.Key)=$($param.Value)"
            }
        }
        
        return $filterParts -join ' '
    }
}

class ZapretConfiguration {
    [string] $Name
    [string] $Description
    [List[ZapretFilter]] $Filters
    [hashtable] $GlobalParameters
    [bool] $GameFilterEnabled
    
    ZapretConfiguration([string]$Name) {
        $this.Name = $Name
        $this.Filters = [List[ZapretFilter]]::new()
        $this.GlobalParameters = @{}
        $this.GameFilterEnabled = $false
    }
    
    [void] AddFilter([ZapretFilter]$Filter) {
        $this.Filters.Add($Filter)
    }
    
    [string] BuildCommandLine([string]$BinPath, [string]$ListsPath) {
        $commandParts = @()
        
        $gameFilter = if ($this.GameFilterEnabled) { "1024-65535" } else { "0" }
        for ($i = 0; $i -lt $this.Filters.Count; $i++) {
            $filter = $this.Filters[$i]
            $filterString = $filter.BuildFilterString($BinPath, $ListsPath)
            
            $filterString = $filterString.Replace('%GameFilter%', $gameFilter)
            $commandParts += $filterString
            if ($i -lt ($this.Filters.Count - 1)) {
                $commandParts += '--new'
            }
        }
        
        return $commandParts -join ' '
    }
    
    [hashtable] ToHashtable() {
        return @{
            Name = $this.Name
            Description = $this.Description
            Filters = $this.Filters | ForEach-Object {
                @{
                    Type = $_.Type
                    Port = $_.Port
                    Strategy = $_.Strategy
                    Parameters = $_.Parameters
                    HostList = $_.HostList
                    IpSet = $_.IpSet
                }
            }
            GlobalParameters = $this.GlobalParameters
            GameFilterEnabled = $this.GameFilterEnabled
        }
    }
    
    static [ZapretConfiguration] FromHashtable([hashtable]$Data) {
        $config = [ZapretConfiguration]::new($Data.Name)
        $config.Description = $Data.Description
        $config.GlobalParameters = $Data.GlobalParameters
        $config.GameFilterEnabled = $Data.GameFilterEnabled
        
        foreach ($filterData in $Data.Filters) {
            $filter = [ZapretFilter]::new($filterData.Type, $filterData.Port, $filterData.Strategy)
            $filter.Parameters = $filterData.Parameters
            $filter.HostList = $filterData.HostList
            $filter.IpSet = $filterData.IpSet
            $config.AddFilter($filter)
        }
        
        return $config
    }
}

class ZapretService {
    [string] $ServiceName
    [string] $BinaryPath
    [string] $ListsPath
    [string] $ConfigPath
    
    ZapretService([string]$BinaryPath, [string]$ListsPath, [string]$ConfigPath) {
        $this.ServiceName = "zapret"
        $this.BinaryPath = $BinaryPath
        $this.ListsPath = $ListsPath
        $this.ConfigPath = $ConfigPath
    }
    
    [bool] IsInstalled() {
        return $null -ne (Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue)
    }
    
    [bool] IsRunning() {
        $service = Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue
        return $service -and $service.Status -eq 'Running'
    }
    
    [void] Install([ZapretConfiguration]$Configuration) {
        $winwsPath = Join-Path $this.BinaryPath "winws.exe"
        if (-not (Test-Path $winwsPath)) {
            throw "winws.exe not found at: $winwsPath"
        }
        
        $commandLine = $Configuration.BuildCommandLine($this.BinaryPath, $this.ListsPath)
        $serviceCommand = "`"$winwsPath`" $commandLine"
        
        if ($this.IsInstalled()) {
            $this.Remove()
        }
        
        $result = Start-Process -FilePath "sc.exe" -ArgumentList @(
            "create", $this.ServiceName,
            "binPath=", $serviceCommand,
            "DisplayName=", "Zapret DPI Bypass",
            "start=", "auto"
        ) -Wait -PassThru -NoNewWindow
        
        if ($result.ExitCode -ne 0) {
            throw "Failed to create service. Exit code: $($result.ExitCode)"
        }
        
        Start-Process -FilePath "sc.exe" -ArgumentList @(
            "description", $this.ServiceName,
            "Zapret DPI bypass software - Configuration: $($Configuration.Name)"
        ) -Wait -NoNewWindow
    }
    
    [void] Remove() {
        if ($this.IsRunning()) {
            $this.Stop()
        }
        
        if ($this.IsInstalled()) {
            $result = Start-Process -FilePath "sc.exe" -ArgumentList @("delete", $this.ServiceName) -Wait -PassThru -NoNewWindow
            if ($result.ExitCode -ne 0) {
                throw "Failed to remove service. Exit code: $($result.ExitCode)"
            }
        }
    }
    
    [void] Start() {
        if (-not $this.IsInstalled()) {
            throw "Service is not installed"
        }
        
        Start-Service -Name $this.ServiceName
    }
    
    [void] Stop() {
        if ($this.IsRunning()) {
            Stop-Service -Name $this.ServiceName -Force
        }
    }
    
    [hashtable] GetStatus() {
        $service = Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue
        
        return @{
            Installed = $this.IsInstalled()
            Running = $this.IsRunning()
            Status = if ($service) { $service.Status.ToString() } else { "Not Installed" }
            StartType = if ($service) { $service.StartType.ToString() } else { "N/A" }
        }
    }
}