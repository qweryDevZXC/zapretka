function New-ZapretConfiguration {
    $config = [ZapretConfiguration]::new("General (2)")
    $config.Description = "Universal configuration for most websites and services"
    $config.GameFilterEnabled = $true
    
    $filter1 = [ZapretFilter]::new("UDP", "443", "fake")
    $filter1.HostList = "list-general.txt"
    $filter1.Parameters = @{
        "dpi-desync-repeats" = "6"
        "dpi-desync-fake-quic" = "%BIN%quic_initial_www_google_com.bin"
    }
    $config.AddFilter($filter1)
    
    $filter2 = [ZapretFilter]::new("UDP", "50000-50100", "fake")
    $filter2.Parameters = @{
        "filter-l7" = "discord,stun"
        "dpi-desync-repeats" = "6"
    }
    $config.AddFilter($filter2)
    
    $filter3 = [ZapretFilter]::new("TCP", "80", "fake,split2")
    $filter3.HostList = "list-general.txt"
    $filter3.Parameters = @{
        "dpi-desync-autottl" = "2"
        "dpi-desync-fooling" = "md5sig"
    }
    $config.AddFilter($filter3)
    
    $filter4 = [ZapretFilter]::new("TCP", "443", "fake,multidisorder")
    $filter4.HostList = "list-general.txt"
    $filter4.Parameters = @{
        "dpi-desync-split-pos" = "midsld"
        "dpi-desync-repeats" = "8"
        "dpi-desync-fooling" = "md5sig,badseq"
    }
    $config.AddFilter($filter4)

    return $config
}