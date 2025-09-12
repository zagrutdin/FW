$firewallRules = @(
    @{ Name="ASDU_Modbus_TCP_502"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.128,10.148.195.128"; Port=502 },
    @{ Name="ASDU_Modbus_UDP_502"; Protocol="UDP"; Direction="Outbound"; RemoteAddresses="10.148.196.128,10.148.195.128"; Port=502 },
    @{ Name="ASDU_BACnet_UDP_47808"; Protocol="UDP"; Direction="Outbound"; RemoteAddresses="10.148.196.128,10.148.195.128"; Port=47808 },
    @{ Name="ASDU_OPCUA_TCP_62544"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=62544 },
    @{ Name="ASDU_App_TCP_4572"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=4572 },
    @{ Name="ASDU_Statistics_TCP_3388"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=3388 },
    @{ Name="ASDU_TCPServer_TCP_4388"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=4388 },
    @{ Name="ASDU_Security_TCP_389"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=389 },
    @{ Name="ASDU_Historian_TCP_4950"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=4950 },
    @{ Name="ASDU_AgentNet_TCP_1020"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=1020 },
    @{ Name="ASDU_AgentDomain_TCP_1010"; Protocol="TCP"; Direction="Outbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=1010 },
    @{ Name="ASDU_KNX_UDP_3671"; Protocol="UDP"; Direction="Outbound"; RemoteAddresses="10.148.196.128,10.148.195.128"; Port=3671 },
    @{ Name="ASDU_KNX_UDP_3671_IN"; Protocol="UDP"; Direction="Inbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=3671 },
    @{ Name="ASDU_SNMP_UDP_161"; Protocol="UDP"; Direction="Outbound"; RemoteAddresses="10.148.196.128,10.148.195.128"; Port=161 },
    @{ Name="ASDU_SNMP_UDP_162"; Protocol="UDP"; Direction="Inbound"; RemoteAddresses="10.148.196.128,10.148.195.128"; Port=162 },
    @{ Name="ASDU_Postgres_TCP_5432"; Protocol="TCP"; Direction="Inbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=5432 },
    @{ Name="ASDU_AccessPoint_TCP_4976"; Protocol="TCP"; Direction="Inbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=4976 },
    @{ Name="ASDU_AccessPoint_TCP_4949"; Protocol="TCP"; Direction="Inbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=4949 },
    @{ Name="ASDU_License_TCP_15150"; Protocol="TCP"; Direction="Inbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=15150 },
    @{ Name="ASDU_Statistics_TCP_15151"; Protocol="TCP"; Direction="Inbound"; RemoteAddresses="10.148.196.129,10.148.196.130"; Port=15151 }
)

function Test-TcpPort {
    param($host, $port)
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $tcp.Connect($host, $port)
        return $true
    } catch {
        return $false
    } finally {
        $tcp.Close()
    }
}

function Test-UdpPort {
    param($host, $port, $timeout=2000)
    $udp = New-Object System.Net.Sockets.UdpClient
    try {
        $udp.Client.ReceiveTimeout = $timeout
        $udp.Connect($host, $port)
        $udp.Send([byte[]]@(), 0)
        return $true
    } catch {
        return $false
    } finally {
        $udp.Close()
    }
}

# Массив для итоговых результатов
$results = @()

foreach ($rule in $firewallRules) {
    Write-Host "====================="
    Write-Host "Правило: $($rule.Name)"
    Write-Host "Протокол: $($rule.Protocol)"
    Write-Host "Направление: $($rule.Direction)"
    Write-Host "Порт: $($rule.Port)"
    $addresses = $rule.RemoteAddresses -split ","
    foreach ($addr in $addresses) {
        Write-Host "Проверка адреса: $addr ..."
        $startTime = Get-Date
        $status = if ($rule.Protocol -eq "TCP") {
            Test-TcpPort -host $addr -port $rule.Port
        } else {
            Test-UdpPort -host $addr -port $rule.Port
        }
        $endTime = Get-Date
        $resultText = if ($status) { "ОТКРЫТ" } else { "ЗАКРЫТ" }
        Write-Host ("Результат: {0}, Время проверки: {1:N2} сек" -f $resultText, ($endTime - $startTime).TotalSeconds)

        # Сохраняем результат в массив
        $results += [PSCustomObject]@{
            Правило     = $rule.Name
            Протокол    = $rule.Protocol
            Направление = $rule.Direction
            Адрес       = $addr
            Порт        = $rule.Port
            Статус      = $resultText
        }
    }
    Write-Host "=====================`n"
}

# Итоговая таблица
Write-Host "Итоговая проверка портов:"
$results | Format-Table -AutoSize

Write-Host "Все проверки завершены."