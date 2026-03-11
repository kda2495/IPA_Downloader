Write-Host "IPA_Downloader 2.1" -ForegroundColor Black -BackgroundColor Yellow
#Для версии IPATool на Go:
#Постоянная переменная $kp
#Переменная $AppleID и использование в функции Connect-AppleID
#В командах ipatool.exe добавлен параметр --keychain-passphrase $kp
#Убран --purchase в функции IPA-Download в связи с нестабильной работой
#Переименование .ipa.tmp в .ipa и перемещение в папку Apps в функции Move-IPA-Files
#Очистка файла .ipatool\cookies при выходе из аккаунта в команде 8

#Проверка на наличие папки Apps:
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory" -Force
}
#Проверка на наличие папки .ipatool:
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}
#Проверка на наличие всех необходимых файлов для работы:
$CheckMainAppFiles = @(
	"ipatool.exe",
	"ideviceinstaller.exe",
	"libbz2-1.dll",
	"libcrypto-3-x64.dll",
	"libimobiledevice-1.0.dll",
	"libimobiledevice-glue-1.0.dll",
	"liblzma-5.dll",
	"libplist-2.0.dll",
	"libssl-3-x64.dll",
	"libusbmuxd-2.0.dll",
	"libzip.dll",
	"libzstd.dll",
	"zlib1.dll"
)
$MissingMainAppFiles = @()
foreach ($file in $CheckMainAppFiles) {
	if (!(Test-Path ".\MainApp\$file")) {
		$MissingMainAppFiles += $file
	}
}
if ($MissingMainAppFiles.Count -gt 0) {
	Write-Host "Ошибка: Следующие файлы не найдены в папке MainApp:" -ForegroundColor Red
	$MissingMainAppFiles | ForEach-Object { Write-Host "$_" -ForegroundColor Red }
	Read-Host "Нажмите Enter для выхода"
	exit
}
#Удаление файлов .ipa.tmp при запуске (в случае неудачной загрузки приложения):
if (Get-ChildItem -Filter "*.ipa.tmp") {
	Remove-Item ".\*.ipa.tmp" -Force -ErrorAction SilentlyContinue
}
#Проверка на Windows 7 и включение TLS 1.2 для запросов:
$OSVersion = [System.Environment]::OSVersion.Version
if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 1) {
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
$kp = "1"
#Проверка наличия файла account в папке .ipatool:
if (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход в аккаунт Apple ID выполнен.`nДанные аккаунта Apple ID:"
	.\MainApp\ipatool.exe auth info --keychain-passphrase $kp
}
#Функция входа в аккаунт Apple ID:
function Connect-AppleID {
	while (!(Test-Path "$env:USERPROFILE\.ipatool\account")) {
		Remove-Item "$env:USERPROFILE\.ipatool\cookies" -Force -ErrorAction SilentlyContinue
		Write-Host "========================================" -ForegroundColor Green
		Write-Host "Вход в аккаунт Apple ID не выполнен."
		$AppleID = Read-Host "Введите Apple ID"
		.\MainApp\ipatool.exe auth login --email $AppleID --keychain-passphrase $kp
	}
}
#Функция перемещения загруженных файлов в папку Apps:
function Move-IPA-Files {
	if (Test-Path ".\*.ipa.tmp") {
		Start-Sleep -Milliseconds 500
		$null = Remove-Item .\*.ipa -ErrorAction SilentlyContinue
		Get-ChildItem -Filter "*.ipa.tmp" | Rename-Item -NewName { $_.Name -replace '\.ipa\.tmp$', '.ipa' }
	}
	$IPAFiles = Get-ChildItem -Filter "*.ipa"
	if ($IPAFiles) {
		$IPAFiles | Move-Item -Destination ".\Apps" -Force
		Write-Host "Готово. Файл сохранен в папку Apps." -ForegroundColor Green
	}
}
#Универсальная функция валидации числового ввода:
function Test-NumericInput {
	param (
		[string]$InputValue,
		[string]$Type
	)
	if ([string]::IsNullOrWhiteSpace($InputValue)) {
		if ($Type -eq "ID") {
			Write-Host "Ошибка: ID приложения не введен." -ForegroundColor Red
		} else {
			Write-Host "Ошибка: Версия приложения не введена." -ForegroundColor Red
		}
		return $false
	}
	if ($InputValue -notmatch '^\d+$') {
		if ($Type -eq "ID") {
			Write-Host "Ошибка: ID приложения должен состоять только из цифр." -ForegroundColor Red
		} else {
			Write-Host "Ошибка: Версия приложения должна состоять только из цифр." -ForegroundColor Red
		}
		return $false
	}
	return $true
}
#Функция загрузки ipa файлов:
function IPA-Download($AppID) {
	if (!(Test-NumericInput -InputValue $AppID -Type "ID")) { return }
	.\MainApp\ipatool.exe download -i $AppID --keychain-passphrase $kp
	Move-IPA-Files
}
#Функция загрузки ipa файлов с выбором версии:
function IPA-Download-With-Version($AppID) {
	if (!(Test-NumericInput -InputValue $AppID -Type "ID")) { return }
	.\MainApp\ipatool.exe list-versions -i $AppID --keychain-passphrase $kp
	$AppVersion = Read-Host "Введите версию приложения для загрузки"
	if (!(Test-NumericInput -InputValue $AppVersion -Type "Version")) { return }
	.\MainApp\ipatool.exe get-version-metadata -i $AppID --external-version-id $AppVersion --keychain-passphrase $kp
	.\MainApp\ipatool.exe download -i $AppID --external-version-id $AppVersion --keychain-passphrase $kp
	Move-IPA-Files
}
#Функция получения списка приложений со страницы проекта на GitHub:
function Get-AppID-From-List {
	try {
		$AppsIDList = Invoke-WebRequest "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt" -UseBasicParsing -ErrorAction Stop | Select-Object -Expand Content
	} catch {
		Write-Host "Ошибка загрузки списка приложений." -ForegroundColor Red
		return $null
	}
	$Lines = $AppsIDList -split "`n" | Where-Object { $_.Trim() -ne "" }
	for ($i = 0; $i -lt $Lines.Count; $i++) {
		$Index = $i + 1
		Write-Host ("{0}. {1}" -f $Index, $Lines[$i])
	}
	$Selection = Read-Host "Введите номер (1-$($Lines.Count)) или ID приложения для загрузки"
	if ([string]::IsNullOrWhiteSpace($Selection)) {
		Write-Host "Ошибка: ID приложения не введен." -ForegroundColor Red
		return $null
	}
	$SelectedIndex = 0
	if ($Selection -match '^\d+$' -and [int]::TryParse($Selection, [ref]$SelectedIndex) -and $SelectedIndex -ge 1 -and $SelectedIndex -le $Lines.Count) {
		$SelectedLine = $Lines[$SelectedIndex - 1]
		$AppID = [System.Text.RegularExpressions.Regex]::Match($SelectedLine, '\b\d{6,}\b').Value
		if ([string]::IsNullOrWhiteSpace($AppID)) {
			Write-Host "Ошибка: ID не найден в строке списка." -ForegroundColor Red
			return $null
		}
		Write-Host "Выбран ID: $AppID"
		return $AppID.Trim()
	}
	elseif ($Selection -match '^\d+$' -and $Selection.Length -lt 6) {
		Write-Host "Ошибка: Приложение под номером $Selection отсутствует в списке." -ForegroundColor Red
		return $null
	}
	elseif ($Selection -match '\d{6,}') {
		$AppID = [System.Text.RegularExpressions.Regex]::Match($Selection, '\b\d{6,}\b').Value
		if ($AppsIDList -notlike "*$AppID*") {
			Write-Host "Ошибка: Приложение с ID $AppID отсутствует в списке." -ForegroundColor Red
			return $null
		}
		Write-Host "Выбран ID: $AppID"
		return $AppID.Trim()
	}
	else {
		Write-Host "Ошибка: Введите номер или ID приложения." -ForegroundColor Red
		return $null
	}
}
#Вход с Apple ID:
Connect-AppleID
#Вывод меню:
$MainMenu = @"
Введите команду:
1. Поиск приложения и загрузка последней версии
2. Ввод ID приложения и загрузка последней версии
3. Ввод ID приложения и загрузка (с выбором версии)
4. Вывод списка ID приложений и загрузка последней версии
5. Вывод списка ID приложений и загрузка (с выбором версии)
6. Установка приложений, загруженных в папку Apps
7. Очистка папки Apps
8. Выход из аккаунта Apple ID
9. Страница проекта на GitHub`n
"@
while (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Write-Host "========================================" -ForegroundColor Green
	$SwitchValue = Read-Host $MainMenu
	#Пункты меню:
	switch ($SwitchValue) {
		#1. Поиск приложения и загрузка последней версии:
		1 {
			Write-Host "========================================" -ForegroundColor Green
			$AppName = Read-Host "Введите название приложения для поиска"
			.\MainApp\ipatool.exe search $AppName --keychain-passphrase $kp --limit 10 2> $null
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		#2. Ввод ID приложения и загрузка последней версии:
		2 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		#3. Ввод ID приложения и загрузка (с выбором версии):
		3 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для поиска"
			IPA-Download-With-Version $AppID
		}
		#4. Вывод списка ID приложений и загрузка последней версии:
		4 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download $AppID
			}
		}
		#5. Вывод списка ID приложений и загрузка (с выбором версии):
		5 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download-With-Version $AppID
			}
		}
		#6. Установка приложений, загруженных в папку Apps:
		6 {
			if (Test-Path ".\Apps\*.ipa") {
				Get-ChildItem ".\Apps\*.ipa" | ForEach-Object {
					.\MainApp\ideviceinstaller.exe -i "$($_.FullName)"
				}
			}
			else {
				Write-Host "Ошибка: В папке Apps отсутствуют приложения." -ForegroundColor Red
			}
		}
		#7. Очистка папки Apps:
		7 {
			Remove-Item ".\Apps\*" -Force -ErrorAction SilentlyContinue
			Write-Host "========================================" -ForegroundColor Green
			Write-Host "Готово. Файлы в папке Apps удалены." -ForegroundColor Green
		}
		#8. Отзыв Apple ID из IPATool:
		8 {
			Write-Host "========================================" -ForegroundColor Green
			Write-Host "Выполнен выход из аккаунта Apple ID."
			.\MainApp\ipatool.exe auth revoke --keychain-passphrase $kp
			$null = Remove-Item "$env:USERPROFILE\.ipatool\cookies" -ErrorAction SilentlyContinue
			Connect-AppleID
		}
		#9. Страница проекта на GitHub:
		9 {
			Start-Process "https://github.com/kda2495/IPA_Downloader"
		}
		default {
			Write-Host "Неверное значение! Введите команду от 1 до 9." -ForegroundColor Red
		}
	}
}
