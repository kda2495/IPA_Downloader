Write-Host "IPA_Downloader 1.0.8 (скрипт создан kda2495)" -ForegroundColor Black -BackgroundColor Yellow
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory"
}
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}
if (Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.") {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с AppleID выполнен.`nДанные AppleID:"
	.\ipatool.exe auth info --keychain-passphrase "1"
}
while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с AppleID не выполнен."
	$apple_ID = Read-Host "Введите AppleID"
	.\ipatool.exe auth login --email $apple_ID --keychain-passphrase "1"
}
while (Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.") {
	Write-Host "========================================" -ForegroundColor Green
	$switch_value = Read-Host "Введите команду:
1.Поиск приложения и загрузка последней версии
2.Ввод ID приложения и загрузка последней версии
3.Ввод ID приложения и загрузка (с выбором версии)
4.Вывод списка ID приложений и загрузка последней версии
5.Вывод списка ID приложений и загрузка (с выбором версии)
6.Отозвать AppleID из IPATool`n"
	while ("1","2","3","4","5","6" -notcontains $switch_value) {
		Write-Host "========================================" -ForegroundColor Green
		$switch_value = Read-Host "Неверное значение! Введите команду (от 1 до 6)`n"
	}
	switch ($switch_value) {
		1 {
		Write-Host "========================================" -ForegroundColor Green
		$app_name = Read-Host "Введите название приложения для поиска"
		.\ipatool.exe search $app_name --keychain-passphrase "1" --limit 20
		$app_ID = Read-Host "Введите ID приложения для загрузки"
		.\ipatool.exe download -i $app_ID --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa){
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		2 {
		Write-Host "========================================" -ForegroundColor Green
		$app_ID = Read-Host "Введите ID приложения для загрузки"
		.\ipatool.exe download -i $app_ID --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa){
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		3 {
		Write-Host "========================================" -ForegroundColor Green
		$app_ID = Read-Host "Введите ID приложения для поиска"
		.\ipatool.exe list-versions -i $app_ID --keychain-passphrase "1"
		$app_version = Read-Host "Введите версию для загрузки"
		.\ipatool.exe get-version-metadata -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
		.\ipatool.exe download -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa){
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		4 {
		Write-Host "========================================" -ForegroundColor Green
		$apps_ID_list = Invoke-WebRequest https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt | Select-Object -Expand Content
		Write-Host $apps_ID_list
		$app_ID = Read-Host "Введите ID приложения для загрузки"
		.\ipatool.exe download -i $app_ID --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa){
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		5 {
		Write-Host "========================================" -ForegroundColor Green
		$apps_ID_list = Invoke-WebRequest https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt | Select-Object -Expand Content
		Write-Host $apps_ID_list
		$app_ID = Read-Host "Введите ID приложения для поиска"
		.\ipatool.exe list-versions -i $app_ID --keychain-passphrase "1"
		$app_version = Read-Host "Введите версию для загрузки"
		.\ipatool.exe get-version-metadata -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
		.\ipatool.exe download -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa){
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		6 {
		Write-Host "========================================" -ForegroundColor Green
		Write-Host "AppleID отозван."
		.\ipatool.exe auth revoke
			while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
				Write-Host "========================================" -ForegroundColor Green
				Write-Host "Вход в AppleID не выполнен."
				$apple_ID = Read-Host "Введите AppleID"
				.\ipatool.exe auth login --email $apple_ID --keychain-passphrase "1"
			}
		}
	}
}