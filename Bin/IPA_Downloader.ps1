Write-Host "IPA_Downloader 2.0" -ForegroundColor Black -BackgroundColor Yellow
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory"
}
if (Test-Path ".\*.ipa.tmp") {
	$null = Remove-Item .\*.ipa.tmp -ErrorAction SilentlyContinue
}
$BinFolder = ".\Bin"
$CheckBinFiles = @(
	"ipatool.exe"
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
$MissingBinFiles = @()

foreach ($file in $CheckBinFiles) {
    if (-not (Test-Path (Join-Path $BinFolder $file))) {
        $MissingBinFiles += $file
    }
}

if ($MissingBinFiles.Count -gt 0) {
    Write-Host "Ошибка: следующие файлы не найдены в папке Bin:" -ForegroundColor Red
    $MissingBinFiles | ForEach-Object { Write-Host "$_" -ForegroundColor Red }
    Read-Host "Нажмите Enter для выхода"
    exit
}
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}
$kp = "1"
if (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с Apple ID выполнен.`nДанные Apple ID:"
	.\Bin\ipatool auth info --keychain-passphrase $kp
}
while (!(Test-Path "$env:USERPROFILE\.ipatool\account")) {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с Apple ID не выполнен."
	$AppleID = Read-Host "Введите Apple ID"
	.\Bin\ipatool auth login --email $AppleID --keychain-passphrase $kp
}
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
function IPA-Download($AppID) {
	if ([string]::IsNullOrWhiteSpace($AppID)) {
		Write-Host "Ошибка: ID приложения не введен." -ForegroundColor Red
		return
	}
	if ($AppID -notmatch '^\d+$') {
		Write-Host "Ошибка: ID приложения должен состоять только из цифр." -ForegroundColor Red
		return
	}
	.\Bin\ipatool download -i $AppID --keychain-passphrase $kp
	Move-IPA-Files
}
function IPA-Download-With-Version($AppID) {
	if ([string]::IsNullOrWhiteSpace($AppID)) {
		Write-Host "Ошибка: ID приложения не введен." -ForegroundColor Red
		return
	}
	if ($AppID -notmatch '^\d+$') {
		Write-Host "Ошибка: ID приложения должен состоять только из цифр." -ForegroundColor Red
		return
	}
	.\Bin\ipatool list-versions -i $AppID --keychain-passphrase $kp
	$AppVersion = Read-Host "Введите версию приложения для загрузки"
	if ([string]::IsNullOrWhiteSpace($AppVersion)) {
		Write-Host "Ошибка: Версия приложения не введена." -ForegroundColor Red
		return
	}
	if ($AppVersion -notmatch '^\d+$') {
		Write-Host "Ошибка: Версия приложения должна состоять только из цифр." -ForegroundColor Red
		return
	}
	.\Bin\ipatool get-version-metadata -i $AppID --external-version-id $AppVersion --keychain-passphrase $kp
	.\Bin\ipatool download -i $AppID --external-version-id $AppVersion --keychain-passphrase $kp
	Move-IPA-Files
}
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
$MainMenu = @"
Введите команду:
1. Поиск приложения и загрузка последней версии
2. Ввод ID приложения и загрузка последней версии
3. Ввод ID приложения и загрузка (с выбором версии)
4. Вывод списка ID приложений и загрузка последней версии
5. Вывод списка ID приложений и загрузка (с выбором версии)
6. Установить приложения, загруженные в папку Apps
7. Очистить папку Apps
8. Отозвать Apple ID из IPATool
9. Перейти на страницу проекта на GitHub`n
"@
while (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Write-Host "========================================" -ForegroundColor Green
	$SwitchValue = Read-Host $MainMenu
	while ("1", "2", "3", "4", "5", "6", "7", "8", "9" -notcontains $SwitchValue) {
		Write-Host "========================================" -ForegroundColor Green
		$SwitchValue = Read-Host "Неверное значение! Введите команду (от 1 до 8)`n"
	}
	switch ($SwitchValue) {
		1 {
			Write-Host "========================================" -ForegroundColor Green
			$AppName = Read-Host "Введите название приложения для поиска"
			.\Bin\ipatool search $AppName --keychain-passphrase $kp --limit 10 2> $null
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		2 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		3 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для поиска"
			IPA-Download-With-Version $AppID
		}
		4 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download $AppID
			}
		}
		5 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download-With-Version $AppID
			}
		}
		6 {
			if (Test-Path ".\Apps\*.ipa") {
				Get-ChildItem .\Apps\*.ipa | ForEach-Object {
					.\Bin\ideviceinstaller.exe -i $_.FullName
				}
			}
			else {
				Write-Host "Ошибка: В папке Apps отсутствуют приложения." -ForegroundColor Red
			}
		}
		7 {
			$null = Remove-Item .\Apps\*
			Write-Host "========================================" -ForegroundColor Green
			Write-Host "Готово. Файлы в папке Apps удалены." -ForegroundColor Green
		}
		8 {
			Write-Host "========================================" -ForegroundColor Green
			Write-Host "Apple ID отозван."
			.\Bin\ipatool auth revoke
			while (!(Test-Path "$env:USERPROFILE\.ipatool\account")) {
				Write-Host "========================================" -ForegroundColor Green
				Write-Host "Вход в Apple ID не выполнен."
				$AppleID = Read-Host "Введите Apple ID"
				.\Bin\ipatool auth login --email $AppleID --keychain-passphrase $kp
			}
		}
		9 {
			Start-Process "https://github.com/kda2495/IPA_Downloader"
		}
	}

}
