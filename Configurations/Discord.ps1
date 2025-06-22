function New-ZapretConfiguration {
    $config = [ZapretConfiguration]::new("Discord")
    $config.Description = "Optimized configuration for Discord"
    $config.GameFilterEnabled = $false
    
    $filter1 = [ZapretFilter]::new("UDP", "443", "fake")
    $filter1.HostList = "list-discord.txt"
    $filter1.Parameters = @{
        "dpi-desync-repeats" = "6"
        "dpi-desync-fake-quic" = "%BIN%quic_initial_www_google_com.bin"
    }
    $config.AddFilter($filter1)
    
    $filter2 = [ZapretFilter]::new("UDP", "50000-50100", "fake")
    $filter2.IpSet = "ipset-discord.txt"
    $filter2.Parameters = @{
        "dpi-desync-any-protocol" = "1"
        "dpi-desync-cutoff" = "d3"
        "dpi-desync-repeats" = "6"
    }
    $config.AddFilter($filter2)
    
    $filter3 = [ZapretFilter]::new("TCP", "443", "split")
    $filter3.HostList = "list-discord.txt"
    $filter3.Parameters = @{
        "dpi-desync-split-pos" = "1"
        "dpi-desync-autottl" = "1"
        "dpi-desync-fooling" = "badseq"
        "dpi-desync-repeats" = "8"
    }
    $config.AddFilter($filter3)
    
    return $config
}