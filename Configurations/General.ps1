function New-ZapretConfiguration {
    $ModuleRoot = Split-Path $PSScriptRoot -Parent
    $BinPath    = Join-Path $ModuleRoot 'bin'
    $ListsPath  = Join-Path $ModuleRoot 'lists'

    $GameFlagFile = Join-Path $BinPath 'game_filter.enabled'
    if (Test-Path $GameFlagFile) {
        $GameFilterStatus = 'enabled'
        $GameFilter = '1024-65535'
    } else {
        $GameFilterStatus = 'disabled'
        $GameFilter = '0'
    }

    $config = [ZapretConfiguration]::new("General")
    $config.Description = "Universal robust DPI bypass for most websites, Discord, games, and QUIC, with both hostlist and IP set rules."
    $config.GameFilterEnabled = $GameFilterStatus -eq 'enabled'

    $f1 = [ZapretFilter]::new("UDP", "443", "fake")
    $f1.HostList = "list-general.txt"
    $f1.Parameters = @{
        "dpi-desync-repeats" = "6"
        "dpi-desync-fake-quic" = Join-Path $BinPath "quic_initial_www_google_com.bin"
    }
    $config.AddFilter($f1)

    $f2 = [ZapretFilter]::new("UDP", "50000-50100", "fake")
    $f2.Parameters = @{
        "filter-l7" = "discord,stun"
        "dpi-desync-repeats" = "6"
    }
    $config.AddFilter($f2)

    $f3 = [ZapretFilter]::new("TCP", "80", "fake,split2")
    $f3.HostList = "list-general.txt"
    $f3.Parameters = @{
        "dpi-desync-autottl" = "2"
        "dpi-desync-fooling" = "md5sig"
    }
    $config.AddFilter($f3)

    $f4 = [ZapretFilter]::new("TCP", "443", "split2")
    $f4.HostList = "list-general.txt"
    $f4.Parameters = @{
        "dpi-desync-repeats" = "2"
        "dpi-desync-split-seqovl" = "681"
        "dpi-desync-split-pos" = "1"
        "dpi-desync-fooling" = "badseq,hopbyhop2"
        "dpi-desync-split-seqovl-pattern" = Join-Path $BinPath "tls_clienthello_www_google_com.bin"
    }
    $config.AddFilter($f4)

    $f5 = [ZapretFilter]::new("UDP", "443", "fake")
    $f5.IpSet = "ipset-all.txt"
    $f5.Parameters = @{
        "dpi-desync-repeats" = "6"
        "dpi-desync-fake-quic" = Join-Path $BinPath "quic_initial_www_google_com.bin"
    }
    $config.AddFilter($f5)

    $f6 = [ZapretFilter]::new("TCP", "80", "fake,split2")
    $f6.IpSet = "ipset-all.txt"
    $f6.Parameters = @{
        "dpi-desync-autottl" = "2"
        "dpi-desync-fooling" = "md5sig"
    }
    $config.AddFilter($f6)

    $f7 = [ZapretFilter]::new("TCP", "443,$GameFilter", "split2")
    $f7.IpSet = "ipset-all.txt"
    $f7.Parameters = @{
        "dpi-desync-split-seqovl" = "681"
        "dpi-desync-split-pos" = "1"
        "dpi-desync-fooling" = "badseq,hopbyhop2"
        "dpi-desync-split-seqovl-pattern" = Join-Path $BinPath "tls_clienthello_www_google_com.bin"
    }
    $config.AddFilter($f7)

    $f8 = [ZapretFilter]::new("UDP", $GameFilter, "fake")
    $f8.IpSet = "ipset-all.txt"
    $f8.Parameters = @{
        "dpi-desync-autottl" = "2"
        "dpi-desync-repeats" = "12"
        "dpi-desync-any-protocol" = "1"
        "dpi-desync-fake-unknown-udp" = Join-Path $BinPath "quic_initial_www_google_com.bin"
        "dpi-desync-cutoff" = "n2"
    }
    $config.AddFilter($f8)

    return $config
}