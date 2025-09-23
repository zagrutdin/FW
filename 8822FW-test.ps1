# Список IP-адресов
$IPList = @(
"10.148.196.131",
"10.148.196.132",
"10.148.196.133",
"10.148.196.134",
"10.148.196.135",
"10.148.196.201",
"10.148.196.202",
"10.148.196.140",
"10.148.196.141",
"10.148.196.142",
"10.148.196.217",
"10.148.196.145",
"10.148.196.144",
"10.148.196.146",
"10.148.195.131",
"10.148.195.132",
"10.148.195.133",
"10.148.195.201",
"10.148.195.202",
"10.148.195.141",
"10.148.195.142"
)

# Список портов для проверки
$PortList = @(22, 80, 443, 502)

foreach ($IP in $IPList) {
    # Пинг
    $pingOutput = ping -n 1 $IP
    $pingLine = $pingOutput | Where-Object { $_ -match "Reply from" }
    if ($pingLine -match "time[=<]\s*(\d+)ms") {
        $pingTime = "$($matches[1]) ms"
    } elseif ($pingLine) {
        $pingTime = "Response"
    } else {
        $pingTime = "NoPing"
    }

    # Параллельная проверка портов через Jobs
    $jobs = @()
    $openPorts = @()
    foreach ($port in $PortList) {
        $jobs += Start-Job -ArgumentList $IP,$port -ScriptBlock {
            param($IP, $port)
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $iar = $tcp.BeginConnect($IP, $port, $null, $null)
                if ($iar.AsyncWaitHandle.WaitOne(500)) {
                    $tcp.EndConnect($iar)
                    $tcp.Close()
                    return $port
                } else {
                    $tcp.Close()
                    return $null
                }
            } catch { return $null }
        }
    }

    # Собираем результаты портов
    foreach ($job in $jobs) {
        $result = Receive-Job $job -Wait
        if ($result) { $openPorts += $result }
        Remove-Job $job
    }

    if ($openPorts.Count -eq 0) { $portsResult = "NoOpenPort" }
    else { $portsResult = ($openPorts -join ",") }

    # Вывод в одну строку
    Write-Host "$IP`tPing: $pingTime`tOpen Ports: $portsResult"
}