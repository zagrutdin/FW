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

# Функция проверки пинга
function Check-Ping {
    param([string]$IP)
    $output = ping -n 1 $IP
    $timeLine = $output | Where-Object { $_ -match "Reply from" }
    if ($timeLine) {
        if ($timeLine -match "time[=<]\s*(\d+)ms") {
            return "$($matches[1]) ms"
        } else {
            return "Response received"
        }
    } else {
        return "No Response"
    }
}

# Функция проверки открытых портов
function Check-Ports {
    param([string]$IP, [int[]]$Ports)
    $openPorts = @()
    foreach ($port in $Ports) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect($IP, $port)
            $tcp.Close()
            $openPorts += $port
        } catch {}
    }
    if ($openPorts.Count -eq 0) { return "No Open Ports" }
    return ($openPorts -join ",")
}

# Основной цикл
foreach ($IP in $IPList) {
    $pingResult = Check-Ping -IP $IP
    Write-Host "$IP : $pingResult"

    # Проверка портов только если пинг прошёл
    if ($pingResult -ne "No Response") {
        $portsResult = Check-Ports -IP $IP -Ports $PortList
        Write-Host "Ports open on $IP : $portsResult"
    } else {
        Write-Host "Ports check skipped for $IP (host unreachable)"
    }

    Write-Host "-------------------------------------------"
}




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

foreach ($IP in $IPList) {
    $output = ping -n 1 $IP

    # Ищем строку с временем ответа
    $timeLine = $output | Where-Object { $_ -match "Reply from" }
    if ($timeLine) {
        if ($timeLine -match "time[=<]\s*(\d+)ms") {
            $time = $matches[1]
            Write-Host "$IP : $time ms"
        } else {
            Write-Host "$IP : Response received (time unknown)"
        }
    } else {
        Write-Host "$IP : No Response"
    }
}