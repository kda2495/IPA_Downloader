Write-Host "IPA_Downloader 1.0.9 (скрипт создан kda2495)" -ForegroundColor Black -BackgroundColor Yellow
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory"
}
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}
if (Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.") {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с AppleID выполнен.`nДанные AppleID:"
	.\ipatool auth info --keychain-passphrase "1"
}
while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход с AppleID не выполнен."
	$apple_ID = Read-Host "Введите AppleID"
	.\ipatool auth login --email $apple_ID --keychain-passphrase "1"
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
		.\ipatool search $app_name --keychain-passphrase "1" --limit 20
		$app_ID = Read-Host "Введите ID приложения для загрузки"
		.\ipatool download -i $app_ID --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa) {
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		2 {
		Write-Host "========================================" -ForegroundColor Green
		$app_ID = Read-Host "Введите ID приложения для загрузки"
		.\ipatool download -i $app_ID --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa) {
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		3 {
		Write-Host "========================================" -ForegroundColor Green
		$app_ID = Read-Host "Введите ID приложения для поиска"
		.\ipatool list-versions -i $app_ID --keychain-passphrase "1"
		$app_version = Read-Host "Введите версию приложения для загрузки"
		.\ipatool get-version-metadata -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
		.\ipatool download -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa) {
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		4 {
		Write-Host "========================================" -ForegroundColor Green
		$apps_ID_list = Invoke-WebRequest https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt | Select-Object -Expand Content
		$lines = $apps_ID_list -split "`n" | Where-Object { $_.Trim() -ne "" }
		for ($i = 0; $i -lt $lines.Count; $i++) {
			$index = $i + 1
			Write-Host ("{0}. {1}" -f $index, $lines[$i])
		}
		$selection = Read-Host "Введите номер (1-$($lines.Count)) или ID приложения для загрузки"
		$idx = 0
		if ($selection -match '^\d{1,3}$' -and [int]::TryParse($selection, [ref]$idx) -and $idx -ge 1 -and $idx -le $lines.Count) {
			$selectedLine = $lines[$idx - 1]
			$ids = @([System.Text.RegularExpressions.Regex]::Matches($selectedLine, '\b\d{6,}\b') | ForEach-Object { $_.Value })
			if ($ids.Count -eq 1) {
				$app_ID = $ids[0]
			} elseif ($ids.Count -gt 1) {
				Write-Host "В строке найдено несколько ID приложений: " ($ids -join ', ')
				$app_ID = Read-Host "Уточните, какой ID приложения использовать"
			} else {
				$app_ID = Read-Host "ID приложения не найден в выбранной строке. Введите ID приложения вручную"
			}
		} else {
			$app_ID = $selection
		}
		$app_ID = [string]$app_ID
		if ([System.Text.RegularExpressions.Regex]::IsMatch($app_ID, '\b\d{6,}\b')) {
			$app_ID = [System.Text.RegularExpressions.Regex]::Match($app_ID, '\b\d{6,}\b').Value
		}
		$app_ID = $app_ID.Trim()
		Write-Host ("Выбран ID: {0}" -f $app_ID)
		.\ipatool download -i $app_ID --keychain-passphrase "1"
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
		$lines = $apps_ID_list -split "`n" | Where-Object { $_.Trim() -ne "" }
		for ($i = 0; $i -lt $lines.Count; $i++) {
			$index = $i + 1
			Write-Host ("{0}. {1}" -f $index, $lines[$i])
		}
		$selection = Read-Host "Введите номер (1-$($lines.Count)) или ID приложения для поиска"
		$idx = 0
		if ($selection -match '^\d{1,3}$' -and [int]::TryParse($selection, [ref]$idx) -and $idx -ge 1 -and $idx -le $lines.Count) {
			$selectedLine = $lines[$idx - 1]
			$ids = @([System.Text.RegularExpressions.Regex]::Matches($selectedLine, '\b\d{6,}\b') | ForEach-Object { $_.Value })
			if ($ids.Count -eq 1) {
				$app_ID = $ids[0]
			} elseif ($ids.Count -gt 1) {
				Write-Host "В строке найдено несколько ID приложений: " ($ids -join ', ')
				$app_ID = Read-Host "Уточните, какой ID приложения использовать"
			} else {
				$app_ID = Read-Host "ID приложения не найден в выбранной строке. Введите ID приложения вручную"
			}
		} else {
			$app_ID = $selection
		}
		$app_ID = [string]$app_ID
		if ([System.Text.RegularExpressions.Regex]::IsMatch($app_ID, '\b\d{6,}\b')) {
			$app_ID = [System.Text.RegularExpressions.Regex]::Match($app_ID, '\b\d{6,}\b').Value
		}
		$app_ID = $app_ID.Trim()
		Write-Host ("Выбран ID: {0}" -f $app_ID)
		.\ipatool list-versions -i $app_ID --keychain-passphrase "1"
		$app_version = Read-Host "Введите версию приложения для загрузки"
		.\ipatool get-version-metadata -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
		.\ipatool download -i $app_ID --external-version-id $app_version --keychain-passphrase "1"
			if (Test-Path ".\*.ipa.tmp") {
				Start-Sleep 1
				Remove-Item .\*.ipa
				Get-ChildItem *.ipa.tmp | Rename-Item -NewName { $_.Name -replace '.ipa.tmp','.ipa' }
			}
			foreach ($file in Get-ChildItem *.ipa) {
				Move-Item -Path $file.fullname -Destination .\Apps -Force
			}
		}
		6 {
		Write-Host "========================================" -ForegroundColor Green
		Write-Host "AppleID отозван."
		.\ipatool auth revoke
			while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
				Write-Host "========================================" -ForegroundColor Green
				Write-Host "Вход в AppleID не выполнен."
				$apple_ID = Read-Host "Введите AppleID"
				.\ipatool auth login --email $apple_ID --keychain-passphrase "1"
			}
		}
	}
}
