# Список правил (как в твоём скрипте New-NetFirewallRule)
$rules = @'
New-NetFirewallRule -DisplayName "ASDU_Modbus_TCP_502" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.128/25,10.148.195.128/25 -RemotePort 502 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_Modbus_UDP_502" -Direction Outbound -Protocol UDP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.128/25,10.148.195.128/25 -RemotePort 502 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_BACnet_UDP_47808" -Direction Outbound -Protocol UDP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.128/25,10.148.195.128/25 -RemotePort 47808 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_OPCUA_TCP_62544" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 62544 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_App_TCP_4572" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 4572 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_Statistics_TCP_3388" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 3388 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_TCPServer_TCP_4388" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 4388 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_Security_TCP_389" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 389 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_Historian_TCP_4950" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 4950 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_AgentNet_TCP_1020" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 1020 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_AgentDomain_TCP_1010" -Direction Outbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 1010 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_KNX_UDP_3671" -Direction Outbound -Protocol UDP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.128/25,10.148.195.128/25 -RemotePort 3671 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_KNX_UDP_3671_IN" -Direction Inbound -Protocol UDP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -RemotePort 3671 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_SNMP_UDP_161" -Direction Outbound -Protocol UDP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.128/25,10.148.195.128/25 -RemotePort 161 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_SNMP_UDP_162" -Direction Inbound -Protocol UDP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.128/25,10.148.195.128/25 -LocalPort 162 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_Postgres_TCP_5432" -Direction Inbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -LocalPort 5432 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_AccessPoint_TCP_4976" -Direction Inbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -LocalPort 4976 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_AccessPoint_TCP_4949" -Direction Inbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -LocalPort 4949 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_License_TCP_15150" -Direction Inbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -LocalPort 15150 -Action Allow
New-NetFirewallRule -DisplayName "ASDU_Statistics_TCP_15151" -Direction Inbound -Protocol TCP -LocalAddress 10.148.207.1 -RemoteAddress 10.148.196.129,10.148.196.130 -LocalPort 15151 -Action Allow
'@ -split "`n"

# Функция пинга
function Test-Ping {
    param($IP)
    try {
        if (Test-Connection -ComputerName $IP -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            return "Ping OK"
        } else {
            return "Ping Fail"
        }
    } catch { return "Ping Error" }
}

# Основной цикл
$results = @()
foreach ($rule in $rules) {
    if ($rule.Trim() -eq "") { continue }

    # Парсим DisplayName, Protocol, Port, RemoteAddress
    $displayName = [regex]::Match($rule, '-DisplayName\s+"([^"]+)"').Groups[1].Value
    $protocol    = [regex]::Match($rule, '-Protocol\s+(\w+)').Groups[1].Value
    $remote      = [regex]::Match($rule, '-RemoteAddress\s+([^\s]+)').Groups[1].Value
    $localPort   = [regex]::Match($rule, '-LocalPort\s+(\d+)').Groups[1].Value
    $remotePort  = [regex]::Match($rule, '-RemotePort\s+(\d+)').Groups[1].Value
    $port        = if ($remotePort) { $remotePort } else { $localPort }

    foreach ($ip in $remote.Split(",")) {
        $ip = $ip.Trim()

        Write-Host "=== Проверка правила $displayName ($protocol $ip:$port) ===" -ForegroundColor Cyan

        $pingResult = Test-Ping $ip

        if ($protocol -eq "TCP") {
            $test = Test-NetConnection -ComputerName $ip -Port $port -WarningAction SilentlyContinue
            $status = if ($test.TcpTestSucceeded) { "OPEN" } else { "CLOSED" }
        }
        elseif ($protocol -eq "UDP") {
            $test = Test-NetConnection -ComputerName $ip -UdpPort $port -WarningAction SilentlyContinue
            $status = if ($test.UdpTestSucceeded) { "OPEN/RESPONDS" } else { "NO RESPONSE" }
        }
        else {
            $status = "UNKNOWN PROTO"
        }

        Write-Host "  Ping: $pingResult"
        Write-Host "  Port status: $status"
        Write-Host ""

        $results += [pscustomobject]@{
            Rule        = $displayName
            Protocol    = $protocol
            RemoteIP    = $ip
            Port        = $port
            Ping        = $pingResult
            PortStatus  = $status
        }
    }
}

Write-Host "`n=== Итоговая таблица ===" -ForegroundColor Yellow
$results | Format-Table -AutoSize