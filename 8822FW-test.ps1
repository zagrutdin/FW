# Автор: Флорит Загрутдинов
# Телефон: +7917 272-22-88

# Список объектов для обновления (без явных кавычек в коде)
$groups = @"
A722-Archestra
A722-Audit-MES
A722-MES_app7
A722-MESAppSvc
G722FSM-3c6aacd5-a281-4138-a09a-f8a6f223e475
G722FSM-67a347b8-4a59-4037-be7b-ac249706f788
G722FSM-A18_4806-Asodu-FS_ТехДокEP-600_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокБК_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокГексен-1_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокДБиУВС_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокДБО_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокИМ_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокОиГ_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокПластики_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокСК_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокСПС_ТМБОтчет
G722FSM-A18_4806-Asodu-FS_ТехДокЭтилен_ТМБОтчет
G722FSM-b19b95d5-afa8-42bb-aca0-a27c51de41c6
G722FSM-d6f85e31-ce2d-447e-89ad-33817a8481f7
G722FSM-FS01-CIIT_Digital
G722FSM-FS01-CIIT_Digital_MES
G722FSM-FS01-CIIT_Polz_KorzhavinAB
G722FSR-3c6aacd5-a281-4138-a09a-f8a6f223e475
G722FSR-67a347b8-4a59-4037-be7b-ac249706f788
G722FSR-A18_4806-Asodu-FS_ASData_АСОДУ
G722FSR-b19b95d5-afa8-42bb-aca0-a27c51de41c6
G722FSR-d6f85e31-ce2d-447e-89ad-33817a8481f7
G722FSR-FS01-CIIT_Digital
G722FSR-FS01-CIIT_Digital_MES
G722FSR-FS01-CIIT_Polz_KorzhavinAB
G722GA-S722AS-MES_L2Support
G722GA-S722DB-ASODUSQL_L2Support
G722GGZ-A18_4806-Asodu-Plant_4806_Users
G722TSU-asodu-sp-09
G722TSU-S722TS-004002
G722TSU-S722TS-004003
G722TSU-S722TS-004004
G722TSU-S722TS-004011
g722tsu-s722ts-tst-mes1
M722-ALARMSERV
M722-ASODUSQL
MES NKNH
SendAs MES NKNH
"@ -split "`n" | ForEach-Object { $_.Trim() }

# Указываем пользователя и ID
$user = 'VasinaAM'
$id = '#TSK22521842, Доп согласующий: Котляров Алексей Викторович'

# Получаем информацию о пользователе из AD
try {
    $adUser = Get-ADUser -Identity $user -Properties mail, GivenName, Surname, MiddleName -ErrorAction Stop
}
catch {
    Write-Host -ForegroundColor Magenta "ОШИБКА: Пользователь '$user' не найден в AD."
    Write-Host -ForegroundColor Red $_.Exception.Message
    exit
}

# Формируем описание
$description = "$($adUser.Surname) $($adUser.GivenName) $($adUser.MiddleName) <$($adUser.mail)>, $id"
Write-Host -ForegroundColor Cyan "[INFO] Сформировано описание: $description`n"

# Перебор объектов и обновление их описания
foreach ($objectName in $groups) {
    Write-Host "Обработка объекта: $objectName" -ForegroundColor Gray

    # Попытка найти объект стандартным методом
    $object = Get-ADObject -Filter "Name -eq '$objectName' -or DisplayName -eq '$objectName'" -Properties Description, ObjectClass -ErrorAction SilentlyContinue

    # Если не найдено, пробуем искать как группу
    if (-not $object) {
        $object = Get-ADGroup -Filter "Name -eq '$objectName'" -Properties Description -ErrorAction SilentlyContinue
        if ($object) { $object.ObjectClass = 'group' }
    }

    # Если не найдено, пробуем искать как пользователя
    if (-not $object) {
        $object = Get-ADUser -Filter "SamAccountName -eq '$objectName'" -Properties Description -ErrorAction SilentlyContinue
        if ($object) { $object.ObjectClass = 'user' }
    }

    # Если найден какой-то объект
    if ($object) {
        Write-Host -NoNewline -ForegroundColor Gray "$objectName "

        if (($object | Measure-Object).Count -eq 1) {
            if ($object.ObjectClass -in @('user', 'group')) {
                Write-Host -ForegroundColor Cyan "Текущее описание: $($object.Description)"

                if ($object.Description -notlike "*$description*") {
                    $newDescription = $description
                    Write-Host -ForegroundColor Green "Новое описание: $newDescription"

                    Set-ADObject -Identity $object.ObjectGUID -Description $newDescription
                    Write-Host -ForegroundColor Yellow "[УСПЕХ] Описание обновлено для '$objectName'`n"
                }
                else {
                    Write-Host -ForegroundColor Magenta "Описание уже соответствует нужному`n"
                }
            }
            else {
                Write-Host -ForegroundColor DarkYellow "Объект '$objectName' не является группой или пользователем (тип: $($object.ObjectClass))`n"
            }
        }
        else {
            Write-Host -ForegroundColor Red "Найдено несколько объектов для '$objectName'. Требуется уточнение.`n"
            pause
        }
    }
    else {
        Write-Host -ForegroundColor Red "$objectName не найдено`n"
    }
}