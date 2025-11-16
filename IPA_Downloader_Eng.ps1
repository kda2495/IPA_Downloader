Write-Host "IPA_Downloader 1.0.9.1 (script by kda2495)" -ForegroundColor Black -BackgroundColor Yellow
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory"
}
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}
if (Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.") {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Login with AppleID is completed.`nYour AppleID:"
	.\ipatool auth info --keychain-passphrase "1"
}
while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Login with AppleID isn't completed."
	$apple_ID = Read-Host "Enter AppleID"
	.\ipatool auth login --email $apple_ID --keychain-passphrase "1"
}
while (Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.") {
	Write-Host "========================================" -ForegroundColor Green
	$switch_value = Read-Host "Enter the command:
1.Search for the app and download the latest version
2.Enter the app ID and download the latest version
3.Enter the app ID and download (with a choice of version)
4.Display the list of app IDs and download the latest version
5.Display the list of app IDs and download (with a choice of version)
6.Revoke your AppleID data from IPATool`n"
	while ("1","2","3","4","5","6" -notcontains $switch_value) {
		Write-Host "========================================" -ForegroundColor Green
		$switch_value = Read-Host "Incorrect value! Enter the command (from 1 to 6)`n"
	}
	switch ($switch_value) {
		1 {
		Write-Host "========================================" -ForegroundColor Green
		$app_name = Read-Host "Enter the name of the app to search"
		.\ipatool search $app_name --keychain-passphrase "1" --limit 20
		$app_ID = Read-Host "Enter the app ID to download"
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
		$app_ID = Read-Host "Enter the app ID to download"
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
		$app_ID = Read-Host "Enter the app ID to search"
		.\ipatool list-versions -i $app_ID --keychain-passphrase "1"
		$app_version = Read-Host "Enter the version of the app to download"
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
		$selection = Read-Host "Enter the number (1-$($lines.Count)) or the app ID to download"
		$idx = 0
		if ($selection -match '^\d{1,3}$' -and [int]::TryParse($selection, [ref]$idx) -and $idx -ge 1 -and $idx -le $lines.Count) {
			$selectedLine = $lines[$idx - 1]
			$ids = @([System.Text.RegularExpressions.Regex]::Matches($selectedLine, '\b\d{6,}\b') | ForEach-Object { $_.Value })
			if ($ids.Count -eq 1) {
				$app_ID = $ids[0]
			} elseif ($ids.Count -gt 1) {
				Write-Host "Multiple app IDs found in the row: " ($ids -join ', ')
				$app_ID = Read-Host "Specify which app ID to use"
			} else {
				$app_ID = Read-Host "The app ID was not found in the selected row. Enter the app ID manually"
			}
		} else {
			$app_ID = $selection
		}
		$app_ID = [string]$app_ID
		if ([System.Text.RegularExpressions.Regex]::IsMatch($app_ID, '\b\d{6,}\b')) {
			$app_ID = [System.Text.RegularExpressions.Regex]::Match($app_ID, '\b\d{6,}\b').Value
		}
		$app_ID = $app_ID.Trim()
		Write-Host ("Selected app ID: {0}" -f $app_ID)
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
		5 {
		Write-Host "========================================" -ForegroundColor Green
		$apps_ID_list = Invoke-WebRequest https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt | Select-Object -Expand Content
		$lines = $apps_ID_list -split "`n" | Where-Object { $_.Trim() -ne "" }
		for ($i = 0; $i -lt $lines.Count; $i++) {
			$index = $i + 1
			Write-Host ("{0}. {1}" -f $index, $lines[$i])
		}
		$selection = Read-Host "Enter the number (1-$($lines.Count)) or the app ID to download"
		$idx = 0
		if ($selection -match '^\d{1,3}$' -and [int]::TryParse($selection, [ref]$idx) -and $idx -ge 1 -and $idx -le $lines.Count) {
			$selectedLine = $lines[$idx - 1]
			$ids = @([System.Text.RegularExpressions.Regex]::Matches($selectedLine, '\b\d{6,}\b') | ForEach-Object { $_.Value })
			if ($ids.Count -eq 1) {
				$app_ID = $ids[0]
			} elseif ($ids.Count -gt 1) {
				Write-Host "Multiple app IDs found in the row: " ($ids -join ', ')
				$app_ID = Read-Host "Specify which app ID to use"
			} else {
				$app_ID = Read-Host "The app ID was not found in the selected row. Enter the app ID manually"
			}
		} else {
			$app_ID = $selection
		}
		$app_ID = [string]$app_ID
		if ([System.Text.RegularExpressions.Regex]::IsMatch($app_ID, '\b\d{6,}\b')) {
			$app_ID = [System.Text.RegularExpressions.Regex]::Match($app_ID, '\b\d{6,}\b').Value
		}
		$app_ID = $app_ID.Trim()
		Write-Host ("Selected ID: {0}" -f $app_ID)
		.\ipatool list-versions -i $app_ID --keychain-passphrase "1"
		$app_version = Read-Host "Enter the version of the app to download"
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
		Write-Host "AppleID revoked."
		.\ipatool auth revoke
			while (!(Get-ChildItem -Path "$env:USERPROFILE\.ipatool" -Filter "account.")) {
				Write-Host "========================================" -ForegroundColor Green
				Write-Host "Login with AppleID isn't completed."
				$apple_ID = Read-Host "Enter AppleID"
				.\ipatool auth login --email $apple_ID --keychain-passphrase "1"
			}
		}
	}

}



