<#
Автор: Флорит Загрутдинов
Телефон: +7 917 272-22-88
Скрипт обновляет атрибут "info" у gMSA M722-ALARMSERV$.
Делает проверки: существует ли gMSA, права доступа, попытки записи.
#>

# === Конфигурация ===
$GmsaName = "M722-ALARMSERV$"

$DescriptionText = @"
Васина Анна Михайловна <vasinaam@tnhk.sibur.ru>, #TSK22521842
Доп согласующий: Котляров Алексей Викторович #CR200000754
Доменная СУЗ на сервере S722DB-ASODUSQL
Предоставить права Owner в БД ALARMDATA
После миграции серверов приложений по CR00054479 под этой УЗ настроить запуск служб приложений 
на серверах S722AS-ASODUAPP.sibur.local, S722WS-ASODUWEB.sibur.local
"@

# === Проверка существования gMSA ===
Write-Host "=== Проверка существования gMSA: $GmsaName ===" -ForegroundColor Cyan
try {
    $gmsa = Get-ADServiceAccount -Identity $GmsaName -Properties info, distinguishedName, objectSid -ErrorAction Stop
    Write-Host "Найден gMSA:" -ForegroundColor Green
    $gmsa | Select-Object Name, SamAccountName, DistinguishedName, info, objectSid | Format-List
} catch {
    Write-Host "❌ gMSA $GmsaName не найден!" -ForegroundColor Red
    exit
}

# === Проверка ACL ===
Write-Host "`n=== Проверка ACL (прав доступа) ===" -ForegroundColor Cyan
try {
    $acl = Get-ACL "AD:$($gmsa.DistinguishedName)"
    $acl.Access | Where-Object {
        $_.IdentityReference -like "*$env:USERNAME" -or $_.IdentityReference -like "*Domain Admins*"
    } | Format-Table IdentityReference, ActiveDirectoryRights, AccessControlType, InheritanceType
} catch {
    Write-Host "Не удалось получить ACL для объекта $GmsaName" -ForegroundColor Red
}

# === Попытка обновления через Set-ADServiceAccount ===
Write-Host "`n=== Попытка обновления через Set-ADServiceAccount ===" -ForegroundColor Cyan
try {
    Set-ADServiceAccount -Identity $GmsaName -Replace @{info=$DescriptionText} -ErrorAction Stop
    Write-Host "✅ Успешно обновлено через Set-ADServiceAccount" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Ошибка Set-ADServiceAccount: $($_.Exception.Message)" -ForegroundColor Yellow
}

# === Попытка обновления через Set-ADObject ===
Write-Host "`n=== Попытка обновления через Set-ADObject ===" -ForegroundColor Cyan
try {
    Set-ADObject -Identity $gmsa.DistinguishedName -Replace @{info=$DescriptionText} -ErrorAction Stop
    Write-Host "✅ Успешно обновлено через Set-ADObject" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Ошибка Set-ADObject: $($_.Exception.Message)" -ForegroundColor Yellow
}

# === Итоговое состояние ===
Write-Host "`n=== Итоговое состояние объекта ===" -ForegroundColor Cyan
$final = Get-ADServiceAccount -Identity $GmsaName -Properties info
$final | Select-Object Name, info | Format-List