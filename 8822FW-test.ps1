# Список IP-адресов без кавычек
$IPList = @(
10.148.196.131
10.148.196.132
10.148.196.133
10.148.196.134
10.148.196.135
10.148.196.201
10.148.196.202
10.148.196.140
10.148.196.141
10.148.196.142
10.148.196.217
10.148.196.145
10.148.196.144
10.148.196.146
10.148.195.131
10.148.195.132
10.148.195.133
10.148.195.201
10.148.195.202
10.148.195.141
10.148.195.142
)

# Список портов для проверки
$PortList = @(22, 80, 443, 502)

foreach ($IP in $IPList) {
    # Пинг
    $output = ping -n 1 $IP
    $timeLine = $output | Where-Object { $_ -match "Reply from" }
    if ($timeLine) {
        if ($timeLine -match "time[=<]\s*(\d+)ms") {
            $time = $matches[1]
        } else {
            $time = "unknown"
        }
        Write-Host "$IP : $time ms"
    } else {
        Write-Host "$IP : No Response"
        $time = "-"
    }

    # Проверка портов
    $openPorts = @()
    foreach ($port in $PortList) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($IP, $port)
            $tcp.Close()
            $openPorts += $port
        } catch {}
    }
    if ($openPorts.Count -eq 0) {
        Write-Host "Open Ports: NoOpenPort"
    } else {
        Write-Host "Open Ports: $($openPorts -join ',')"
    }

    Write-Host "--------------------------------------"
}