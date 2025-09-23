# Список IP-адресов
$IPs = @(
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
$Ports = @(22, 80, 443, 502)

foreach ($IP in $IPs) {
    $PingResult = Test-Connection -ComputerName $IP -Count 1 -Quiet
    if ($PingResult) {
        Write-Host "$IP is reachable"
        foreach ($Port in $Ports) {
            $PortResult = Test-NetConnection -ComputerName $IP -Port $Port -InformationLevel Quiet
            if ($PortResult) {
                Write-Host "Port $Port is open on $IP"
            } else {
                Write-Host "Port $Port is closed on $IP"
            }
        }
    } else {
        Write-Host "$IP is not reachable"
    }
}