Write-Host "IPA_Downloader 1.1.4" -ForegroundColor Black -BackgroundColor Yellow
if (!(Test-Path ipatool.exe)) {
	Write-Host "Ошибка: ipatool.exe не найден в папке со скриптом." -ForegroundColor Red
	Read-Host "Нажмите Enter для выхода"
	exit
}
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory"
}
if (Test-Path ".\*.ipa.tmp") {
	Remove-Item .\*.ipa.tmp -ErrorAction SilentlyContinue
}
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}
if (Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.") {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с Apple ID выполнен.`nДанные Apple ID:"
	.\ipatool auth info --keychain-passphrase "1"
}
while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с Apple ID не выполнен."
	$AppleID = Read-Host "Введите Apple ID"
	.\ipatool auth login --email $AppleID --keychain-passphrase "1"
}
function Move-IPA-Files {
	if (Test-Path ".\*.ipa.tmp") {
		Start-Sleep -Milliseconds 500
		Remove-Item .\*.ipa -ErrorAction SilentlyContinue
		Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
	}
	$IPAFiles = Get-ChildItem *.ipa
	if ($IPAFiles) {
		$IPAFiles | Move-Item -Destination ".\Apps" -Force
		Write-Host "Готово. Файл сохранен в папку Apps." -ForegroundColor Green
	}
}
function IPA-Download {
	if ([string]::IsNullOrWhiteSpace($AppID)) {
		Write-Host "Ошибка: ID приложения не введен." -ForegroundColor Red
		return
	}
	if ($AppID -notmatch '^\d+$') {
		Write-Host "Ошибка: ID приложения должен состоять только из цифр." -ForegroundColor Red
		return
	}
	.\ipatool download -i $AppID --keychain-passphrase "1"
	Move-IPA-Files
}
function IPA-Download-With-Version {
	if ([string]::IsNullOrWhiteSpace($AppID)) {
		Write-Host "Ошибка: ID приложения не введен." -ForegroundColor Red
		return
	}
	if ($AppID -notmatch '^\d+$') {
		Write-Host "Ошибка: ID приложения должен состоять только из цифр." -ForegroundColor Red
		return
	}
	.\ipatool list-versions -i $AppID --keychain-passphrase "1"
	$AppVersion = Read-Host "Введите версию приложения для загрузки"
	if ([string]::IsNullOrWhiteSpace($AppVersion)) {
		Write-Host "Ошибка: Версия приложения не введена." -ForegroundColor Red
		return
	}
	if ($AppVersion -notmatch '^\d+$') {
		Write-Host "Ошибка: Версия приложения должна состоять только из цифр." -ForegroundColor Red
		return
	}
	.\ipatool get-version-metadata -i $AppID --external-version-id $AppVersion --keychain-passphrase "1"
	.\ipatool download -i $AppID --external-version-id $AppVersion --keychain-passphrase "1"
	Move-IPA-Files
}
function Get-AppID-From-List {
	$AppsIDList = Invoke-WebRequest https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt -UseBasicParsing | Select-Object -Expand Content
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
	} else {
		if ($Selection -match '^\d+$' -and $Selection.Length -lt 6) {
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
}
$MainMenu = @"
Введите команду:
1.Поиск приложения и загрузка последней версии
2.Ввод ID приложения и загрузка последней версии
3.Ввод ID приложения и загрузка (с выбором версии)
4.Вывод списка ID приложений и загрузка последней версии
5.Вывод списка ID приложений и загрузка (с выбором версии)
6.Отозвать Apple ID из IPATool
7.Перейти на страницу проекта в GitHub`n
"@
while (Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.") {
	Write-Host "========================================" -ForegroundColor Green
	$SwitchValue = Read-Host $MainMenu
	while ("1","2","3","4","5","6","7" -notcontains $SwitchValue) {
		Write-Host "========================================" -ForegroundColor Green
		$SwitchValue = Read-Host "Неверное значение! Введите команду (от 1 до 7)`n"
	}
	switch ($SwitchValue) {
		1 {
			Write-Host "========================================" -ForegroundColor Green
			$AppName = Read-Host "Введите название приложения для поиска"
			.\ipatool search $AppName --keychain-passphrase "1" --limit 10 2> $null
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download
		}
		2 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download
		}
		3 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для поиска"
			IPA-Download-With-Version
		}
		4 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download
			}
		}
		5 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download-With-Version
			}
		}
		6 {
			Write-Host "========================================" -ForegroundColor Green
			Write-Host "Apple ID отозван."
			.\ipatool auth revoke
			while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
				Write-Host "========================================" -ForegroundColor Green
				Write-Host "Вход в Apple ID не выполнен."
				$AppleID = Read-Host "Введите Apple ID"
				.\ipatool auth login --email $AppleID --keychain-passphrase "1"
			}
		}
		7 {
			Start-Process "https://github.com/kda2495/IPA_Downloader"
		}
	}
}
