# Переключение рабочей директории в папку со скриптом:
Set-Location -Path $PSScriptRoot

# Определение основных папок и переменных:
$IsWin = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)

if ($IsWin) {
	$ArchSubFolder = "windows_amd64"
} else {
	# Кроссплатформенный способ получения архитектуры:
	$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
	if ($Arch -eq "arm64") {
		$ArchSubFolder = "macos_arm64"
	} else {
		$ArchSubFolder = "macos_amd64"
	}
}

$OSVersion = [System.Environment]::OSVersion
$WindowsVersion = [System.Environment]::OSVersion.Version
$MainAppFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "MainApp"
$BinaryFolderPath = Join-Path -Path $MainAppFolderPath -ChildPath $ArchSubFolder
$LangConfigFilePath = Join-Path -Path $MainAppFolderPath -ChildPath "Lang_Config.txt"
$ListsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Lists"
$DownloadedIDsFilePath = Join-Path -Path $ListsFolderPath -ChildPath "Downloaded_IDs.json"
$PurchasedIDsFilePath = Join-Path -Path $ListsFolderPath -ChildPath "Purchased_IDs.json"
$AppsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Apps"
$ipatoolHomePath = Join-Path -Path $HOME -ChildPath ".ipatool"
$AccountFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "account"
$CookiesFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "cookies"
$TempFolderPath = [System.IO.Path]::GetTempPath()
$TempIpaFilePath = Join-Path -Path $TempFolderPath -ChildPath "Temp.ipa"
$AppsIDListPath = Join-Path -Path $ListsFolderPath -ChildPath "Apps_ID_List.txt"
$AppsIDTempListPath = Join-Path -Path $MainAppFolderPath -ChildPath "Apps_ID_List_tmp.txt"

# Настройка консоли:
if ($IsWin) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ConsoleFont {
	[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
	public struct CONSOLE_FONT_INFO_EX {
		public uint cbSize;
		public uint nFont;
		public short dwFontSizeX;
		public short dwFontSizeY;
		public int FontFamily;
		public int FontWeight;
		[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
		public string FaceName;
	}
	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern bool SetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, ref CONSOLE_FONT_INFO_EX lpConsoleCurrentFontEx);
	[DllImport("kernel32.dll", SetLastError = true)]
	public static extern IntPtr GetStdHandle(int nStdHandle);
	public static void SetFont(string fontName, short fontSize = 12) {
		IntPtr hConsole = GetStdHandle(-11); // STD_OUTPUT_HANDLE
		CONSOLE_FONT_INFO_EX fontInfo = new CONSOLE_FONT_INFO_EX();
		fontInfo.cbSize = (uint)Marshal.SizeOf(fontInfo);
		fontInfo.FaceName = fontName;
		fontInfo.dwFontSizeY = fontSize;
		SetCurrentConsoleFontEx(hConsole, false, ref fontInfo);
	}
}
"@

	[ConsoleFont]::SetFont("Consolas", 16)
	[Console]::InputEncoding = [System.Text.Encoding]::UTF8
	[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
	$OutputEncoding = [System.Text.Encoding]::UTF8
	chcp 65001 > $null
}

# Подключение системных сборок для работы с Zip-архивами:
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Файл языка скрипта:
$Global:CurrentLang = "RU"

# Глобальная переменная для кэширования структурированного списка с GitHub:
$Global:GitHubParsedList = $null

# Перевод текста:
$LangStrings = @{
	"RU" = @{
		"AddedToDownloadedList" = "Добавлено в список: {0} - {1}"
		"AddedToPurchasedList" = "Добавлено в список покупок: {0} - {1}"
		"AlreadyInList" = "Уже есть в списке: {0} - {1}"
		"AppsCleared" = "Готово. Приложения в папке Apps удалены."
		"AskAppNum" = "Введите номера приложений"
		"AskIdDownload" = "Введите ID приложения для загрузки"
		"AskIdSearch" = "Введите ID приложения для поиска"
		"AskIdPurchase" = "Введите ID приложения для покупки"
		"AskSearch" = "Введите название приложения для поиска"
		"AskVerCount" = "Введите количество версий для отображения"
		"AskVerNum" = "Введите номера версий для загрузки"
		"AuthFail" = "Вход в Apple ID не выполнен."
		"AuthSuccess" = "Вход в Apple ID выполнен.`nДанные аккаунта:"
		"CancelStep" = "(0: Отмена/Возврат в главное меню)"
		"ClearMenu1" = "1. Список загруженных приложений"
		"ClearMenu2" = "2. Список приобретенных приложений"
		"ClearMenu3" = "3. Приложения в папке Apps"
		"ClearMenuTitle" = "Выберите данные для очистки:"
		"DownloadedListCleared" = "Готово. Список загруженных приложений очищен."
		"DownloadedListMenu1" = "1. Полный список приложений (GitHub)"
		"DownloadedListMenu2" = "2. Список загруженных приложений"
		"DownloadedListMenu3" = "3. Список не загруженных приложений"
		"ErrorHistoryEmpty" = "Ошибка: История загрузок пуста."
		"ErrorInvalidInput" = "Ошибка: Неверный ввод."
		"ErrorListLoadError" = "Ошибка загрузки списка приложений."
		"ErrorMacIdeviceinstallerNotFound" = "Ошибка: ideviceinstaller не найден. Установка приложений через скрипт невозможна."
		"ErrorMissingFiles" = "Ошибка. Следующие файлы не найдены:"
		"ErrorNoApps" = "Ошибка: В папке Apps отсутствуют приложения."
		"ErrorNoAppsFound" = "Ошибка: Приложения не найдены."
		"ErrorPurchasedEmpty" = "Ошибка: История покупок пуста."
		"FileName" = "Имя файла:"
		"FileSaved" = "Готово. Файл сохранен в папку Apps."
		"HeaderAppName" = "Название приложения"
		"HeaderAppID" = "ID приложения"
		"HeaderFileName" = "Имя файла"
		"HeaderMinIOS" = "Мин. iOS"
		"HeaderVerID" = "ID версии"
		"HeaderVersion" = "Версия"
		"InstallApp" = "Установка:"
		"LangChanged" = "Язык успешно изменен на Русский."
		"ListMenuTitle" = "Выберите список для отображения:"
		"LoggedOut" = "Выполнен выход из Apple ID."
		"Menu1" = "1. Поиск приложения и покупка (без загрузки)"
		"Menu2" = "2. Поиск приложения и загрузка последней версии"
		"Menu3" = "3. Поиск приложения и загрузка (с выбором версии)"
		"Menu4" = "4. Ввод ID приложений и покупка (без загрузки)"
		"Menu5" = "5. Ввод ID приложений и загрузка последней версии"
		"Menu6" = "6. Ввод ID приложений и загрузка (с выбором версии)"
		"Menu7" = "7. Вывод списка приложений и покупка (без загрузки)"
		"Menu8" = "8. Вывод списка приложений и загрузка последней версии"
		"Menu9" = "9. Вывод списка приложений и загрузка (с выбором версии)"
		"Menu10" = "10. Проверка минимальной версии iOS для приложений в папке Apps"
		"Menu11" = "11. Установка приложений из папки Apps"
		"Menu12" = "12. Очистка данных"
		"Menu13" = "13. Выход из Apple ID"
		"Menu14" = "14. Страница проекта на GitHub"
		"Menu15" = "15. Сменить язык (Change Language)"
		"MenuTitle" = "Введите команду:"
		"MinIOS" = "Минимальная версия iOS:"
		"PurchasedListCleared" = "Готово. Список приобретенных приложений очищен."
		"PurchasedListMenu1" = "1. Полный список приложений (GitHub)"
		"PurchasedListMenu2" = "2. Список приобретенных приложений"
		"PurchasedListMenu3" = "3. Список не приобретенных приложений"
		"SelectedApp" = "Выбрано приложение:"
		"SelectedVer" = "Выбрана версия:"
	}
	"EN" = @{
		"AddedToDownloadedList" = "Added to list: {0} - {1}"
		"AddedToPurchasedList" = "Added to purchased list: {0} - {1}"
		"AlreadyInList" = "Already in list: {0} - {1}"
		"AppsCleared" = "Done. Apps folder has been cleared."
		"AskAppNum" = "Enter app index numbers"
		"AskIdDownload" = "Enter app IDs to download"
		"AskIdSearch" = "Enter app IDs to search"
		"AskIdPurchase" = "Enter app IDs to purchase"
		"AskSearch" = "Enter app name to search"
		"AskVerCount" = "Enter number of versions to display"
		"AskVerNum" = "Enter version numbers to download"
		"AuthFail" = "Not authenticated with Apple ID."
		"AuthSuccess" = "Apple ID login successful.`nAccount details:"
		"CancelStep" = "(0: Cancel/Return to main menu)"
		"ClearMenu1" = "1. Downloaded apps list"
		"ClearMenu2" = "2. Purchased apps list"
		"ClearMenu3" = "3. Apps in Apps folder"
		"ClearMenuTitle" = "Select data to clear:"
		"DownloadedListCleared" = "Done. Downloaded apps list cleared."
		"DownloadedListMenu1" = "1. Full apps list (GitHub)"
		"DownloadedListMenu2" = "2. Downloaded apps list"
		"DownloadedListMenu3" = "3. Not downloaded apps list"
		"ErrorHistoryEmpty" = "Error: Download history is empty."
		"ErrorInvalidInput" = "Error: Invalid input."
		"ErrorListLoadError" = "Failed to load apps list."
		"ErrorMissingFiles" = "Error. Following files were not found:"
		"ErrorMacIdeviceinstallerNotFound" = "Error: ideviceinstaller not found. Apps installation via script is impossible."
		"ErrorNoApps" = "Error: No apps found in Apps folder."
		"ErrorNoAppsFound" = "Error: No apps found."
		"ErrorPurchasedEmpty" = "Error: Purchase history is empty."
		"FileName" = "File name:"
		"FileSaved" = "Done. File saved to Apps folder."
		"HeaderAppName" = "App Name"
		"HeaderAppID" = "App ID"
		"HeaderFileName" = "File name"
		"HeaderMinIOS" = "Min. iOS"
		"HeaderVerID" = "Version ID"
		"HeaderVersion" = "Version"
		"InstallApp" = "Installing:"
		"LangChanged" = "Language successfully changed to English."
		"ListMenuTitle" = "Select list to display:"
		"LoggedOut" = "Successfully logged out of Apple ID."
		"Menu1" = "1. Search for app and purchase (without downloading)"
		"Menu2" = "2. Search for app and download latest version"
		"Menu3" = "3. Search for app and download (with version selection)"
		"Menu4" = "4. Enter app IDs and purchase (without downloading)"
		"Menu5" = "5. Enter app IDs and download latest version"
		"Menu6" = "6. Enter app IDs and download (with version selection)"
		"Menu7" = "7. Show list of apps and purchase (without downloading)"
		"Menu8" = "8. Show list of apps and download latest version"
		"Menu9" = "9. Show list of apps and download (with version selection)"
		"Menu10" = "10. Check minimum iOS version for apps in Apps folder"
		"Menu11" = "11. Install apps from Apps folder"
		"Menu12" = "12. Clear data"
		"Menu13" = "13. Log out of Apple ID"
		"Menu14" = "14. GitHub project page"
		"Menu15" = "15. Change Language (Сменить язык)"
		"MenuTitle" = "Enter a command:"
		"MinIOS" = "Minimum iOS version:"
		"PurchasedListCleared" = "Done. Purchased apps list cleared."
		"PurchasedListMenu1" = "1. Full apps list (GitHub)"
		"PurchasedListMenu2" = "2. Purchased apps list"
		"PurchasedListMenu3" = "3. Not purchased apps list"
		"SelectedApp" = "Selected app:"
		"SelectedVer" = "Selected version:"
	}
}

# Функция разделителя:
function Separator {
	Write-Host "================================================" -ForegroundColor Green
}

# Функция перевода текста:
function Get-Lang($Key) {
	return $LangStrings[$Global:CurrentLang][$Key]
}

# Функция вывода ошибки:
function Show-Error {
	param ([string]$Key = "ErrorInvalidInput")
	Separator
	Write-Host (Get-Lang $Key) -ForegroundColor DarkRed
}

# Функция получения имени приложения по ID:
function Resolve-AppDisplayName {
	param ([string]$AppId)
	$GitHubName = Get-GitHub-AppName -AppId $AppId
	return @{
		Display = if ([string]::IsNullOrWhiteSpace($GitHubName)) { $AppId } else { $GitHubName }
		Final   = if ([string]::IsNullOrWhiteSpace($GitHubName)) { "Unknown" } else { $GitHubName }
	}
}

# Функция чтения JSON-файла списка приложений:
function Read-AppList-Json {
	param ([string]$FilePath, [string]$EmptyError)
	if (!(Test-Path $FilePath)) {
		Show-Error $EmptyError
		return $null
	}
	$JsonRaw = Get-Content $FilePath -Raw -Encoding UTF8
	if ([string]::IsNullOrWhiteSpace($JsonRaw)) {
		Show-Error $EmptyError
		return $null
	}
	$Data = $JsonRaw | ConvertFrom-Json
	if ($null -eq $Data) {
		Show-Error $EmptyError
		return $null
	}
	if ($Data -isnot [System.Collections.IEnumerable]) { $Data = @($Data) }
	return $Data
}

# Функция входа в Apple ID:
function Connect-AppleID {
	while (!(Test-Path "$AccountFilePath")) {
		Remove-Item "$CookiesFilePath" -Force -ErrorAction SilentlyContinue
		Separator
		Write-Host (Get-Lang "AuthFail")
		& "$ipatoolFilePath" auth login
	}
}

# Функция извлечения метаданных из IPA:
function Get-IPA-Metadata {
	param ([string]$IpaPath)
	if (!(Test-Path $IpaPath)) { return $null }
	
	$Metadata = [PSCustomObject]@{
		AppName = "App"
		Version = "0"
		MinIOS = "NA"
	}
	
	try {
		$Zip = [System.IO.Compression.ZipFile]::OpenRead($IpaPath)
		$PlistEntry = $Zip.Entries | Where-Object { $_.FullName -match 'Payload/.*\.app/Info\.plist$' } | Select-Object -First 1
		if ($PlistEntry) {
			try {
				$Reader = New-Object System.IO.StreamReader($PlistEntry.Open(), [System.Text.Encoding]::UTF8)
				$Content = $Reader.ReadToEnd()
			} finally {
				if ($null -ne $Reader) { $Reader.Dispose() }
			}
			
			if ($Content -match '<key>CFBundleName</key>\s*<string>([^<]+)</string>') {
				$Metadata.AppName = $Matches[1]
			}
			if (($Metadata.AppName -eq "App") -and ($Content -match '<key>CFBundleDisplayName</key>\s*<string>([^<]+)</string>')) {
				$Metadata.AppName = $Matches[1]
			}
			if ($Content -match '<key>CFBundleShortVersionString</key>\s*<string>([^<]+)</string>') {
				$Metadata.Version = $Matches[1]
			}
			if ($Content -match '<key>MinimumOSVersion</key>\s*<string>([^<]+)</string>') {
				$Metadata.MinIOS = $Matches[1]
			}
		}
	} catch {
		return $null
	} finally {
		if ($null -ne $Zip) { $Zip.Dispose() }
	}
	
	$Metadata.AppName = $Metadata.AppName -replace '[\\/:*?"<>|]', ''
	return $Metadata
}

# Функция сохранения списков:
function Save-App-To-List {
	param (
		[string]$AppId,
		[string]$AppNameOnly,
		[ValidateSet("Downloaded", "Purchased")][string]$Type
	)
	
	if ([string]::IsNullOrWhiteSpace($AppNameOnly) -or $AppNameOnly -eq "Unknown") {
		return
	}
	
	$HistoryFile = if ($Type -eq "Purchased") { "$PurchasedIDsFilePath" } else { "$DownloadedIDsFilePath" }
	
	if (!(Test-Path $HistoryFile)) {
		$null = New-Item -Path $HistoryFile -ItemType "File" -Value ''
	}
	
	$JsonRaw = Get-Content $HistoryFile -Raw -Encoding UTF8
	$Data = if ([string]::IsNullOrWhiteSpace($JsonRaw)) { @() } else { $JsonRaw | ConvertFrom-Json }
	
	if ($Data -isnot [System.Collections.IEnumerable]) { $Data = @($Data) }

	foreach ($Item in $Data) {
		if ($Item.appid -eq $AppId) {
			Write-Host ((Get-Lang "AlreadyInList") -f $Item.name, $AppId)
			return
		}
	}

	$NewItem = [PSCustomObject]@{ name = $AppNameOnly; appid = $AppId }
	$Data = @($Data) + $NewItem
	$Data = $Data | Sort-Object -Property name
	$Data | ConvertTo-Json -Depth 5 | Set-Content $HistoryFile -Encoding UTF8

	$MsgKey = if ($Type -eq "Purchased") { "AddedToPurchasedList" } else { "AddedToDownloadedList" }
	Write-Host ((Get-Lang $MsgKey) -f $AppNameOnly, $AppId)
}

# Функция инициализации и кэширования GitHub списка:
function Initialize-GitHub-List {
	if ($null -ne $Global:GitHubParsedList) { return }
	try {
		# Если файла нет, скачиваем синхронно:
		if (!(Test-Path "$AppsIDListPath")) {
			Invoke-RestMethod -Uri "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt" -OutFile "$AppsIDListPath" -ErrorAction SilentlyContinue
		}
		
		# Защита от сбоя сети при первом запуске:
		if (!(Test-Path "$AppsIDListPath")) {
			$Global:GitHubParsedList = @()
			return
		}
		
		# Чтение данных из локального файла:
		$Raw = Get-Content -Path "$AppsIDListPath" -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
		if ([string]::IsNullOrWhiteSpace($Raw)) { 
			$Global:GitHubParsedList = @()
			return 
		}
		
		$Global:GitHubParsedList = $Raw -split "`n" | Where-Object { $_ -match '^(.+?):\s*(\d+)' } | ForEach-Object {
			[PSCustomObject]@{
				Name = $Matches[1].Trim()
				Id = $Matches[2].Trim()
			}
		}
	} catch {
		$Global:GitHubParsedList = @()
	}
}

# Быстрый поиск имени приложения по кэшу:
function Get-GitHub-AppName {
	param ([string]$AppId)
	Initialize-GitHub-List
	$App = $Global:GitHubParsedList | Where-Object { $_.Id -eq $AppId } | Select-Object -First 1
	if ($App) { return $App.Name } else { return $null }
}

# Функция перемещения и автоматического переименования:
function Move-IPA-Files {
	param (
		[string]$AppId,
		[string]$AppName
	)
	$IpaFiles = Get-ChildItem -Path "$PSScriptRoot" -Filter "*.ipa" -File
	if ($IpaFiles) {
		foreach ($File in $IpaFiles) {
			$DestPath = Join-Path -Path $AppsFolderPath -ChildPath $File.Name
			Move-Item -Path $File.FullName -Destination $DestPath -Force
			Separator
			Write-Host (Get-Lang "FileSaved")
			
			$Meta = Get-IPA-Metadata -IpaPath $DestPath
			if ($Meta) {
				$FinalAppName = $Meta.AppName
				
				# Проверяем GitHub список, если имя неизвестно или не было передано:
				if ([string]::IsNullOrWhiteSpace($AppName) -or $AppName -eq "Unknown") {
					$GitHubName = Get-GitHub-AppName -AppId $AppId
					if (![string]::IsNullOrWhiteSpace($GitHubName)) {
						$AppName = $GitHubName
					}
				}
				
				# Применяем найденное имя, очищая его от недопустимых символов:
				if (![string]::IsNullOrWhiteSpace($AppName) -and $AppName -ne "Unknown") {
					$FinalAppName = $AppName -replace '[\\/:*?"<>|]', ''
				}
				
				# Формируем имя файла и заменяем все пробелы на "_":
				$NewName = "$($FinalAppName)_$($Meta.Version)_iOS_$($Meta.MinIOS)+.ipa" -replace '\s+', '_'
				$TargetFile = Join-Path -Path $AppsFolderPath -ChildPath $NewName
				
				if (Test-Path $TargetFile) {
					Remove-Item $TargetFile -Force -ErrorAction SilentlyContinue
				}
				
				Rename-Item -Path $DestPath -NewName $NewName -Force
				Write-Host "$(Get-Lang 'FileName') $NewName"
				Write-Host "$(Get-Lang 'MinIOS') $($Meta.MinIOS)+"

				if (![string]::IsNullOrEmpty($AppId)) {
					Save-App-To-List -AppId $AppId -AppNameOnly $FinalAppName -Type "Downloaded"
				}
			}
		}
	}
}

# Функция валидации числового ввода:
function Test-NumericInput {
	param ([string]$InputValue)
	if ([string]::IsNullOrWhiteSpace($InputValue) -or $InputValue -notmatch '^\d+$') {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor DarkRed
		return $false
	}
	return $true
}

# Функция для парсинга введенных номеров и диапазонов:
function Parse-NumberSelection {
	param (
		[string]$Selection,
		[int]$MaxCount
	)
	$SelectedIndices = @()
	$Parts = $Selection -split ','

	foreach ($Part in $Parts) {
		$Part = $Part.Trim()
		if ($Part -match '^\d+-\d+$') {
			$Range = $Part -split '-'
			$Start = 0; $End = 0
			if (![int]::TryParse($Range[0], [ref]$Start) -or ![int]::TryParse($Range[1], [ref]$End)) { return $null }
			if ($Start -le $End) { $SelectedIndices += $Start..$End } else { $SelectedIndices += $End..$Start }
		} elseif ($Part -match '^\d+$') {
			$Val = 0
			if (![int]::TryParse($Part, [ref]$Val)) { return $null }
			$SelectedIndices += $Val
		} else {
			return $null
		}
	}

	$SelectedIndices = $SelectedIndices | Select-Object -Unique | Where-Object { $_ -ge 1 -and $_ -le $MaxCount }
	
	if ($SelectedIndices.Count -eq 0) { return $null }
	return $SelectedIndices
}

# Функция запроса номеров позиций у пользователя с проверкой отмены и валидацией (объединяет повторяющийся ранее код):
function Read-NumberSelection {
	param (
		[string]$PromptKey,
		[int]$MaxCount
	)
	$Selection = Read-Host "$(Get-Lang $PromptKey) (1-$MaxCount) $(Get-Lang 'CancelStep')`n"

	if ($Selection -eq '0') { return $null }
	if ([string]::IsNullOrWhiteSpace($Selection)) {
		Show-Error "ErrorInvalidInput"
		return $null
	}

	$SelectedIndices = Parse-NumberSelection -Selection $Selection -MaxCount $MaxCount
	if ($null -eq $SelectedIndices) {
		Show-Error "ErrorInvalidInput"
		return $null
	}

	return $SelectedIndices
}

# Функция загрузки приложений:
function IPA-Download {
	param (
		[string]$AppId,
		[string]$AppName
	)
	if (!(Test-NumericInput -InputValue $AppId)) { return }
	Separator
	& "$ipatoolFilePath" download -i $AppId --purchase
	Move-IPA-Files -AppId $AppId -AppName $AppName
}

# Функция загрузки приложений с выбором версии:
function IPA-Download-With-Version {
	param (
		[string]$AppId,
		[string]$AppName
	)
	if (!(Test-NumericInput -InputValue $AppId)) { return }
	
	Separator
	$RawOutput = & "$ipatoolFilePath" list-versions -i $AppId 2>&1

	if ($RawOutput -match "Error:") {
		Write-Host $RawOutput -ForegroundColor DarkRed
		return
	}

	if ([string]::IsNullOrEmpty($RawOutput)) { return }

	$RawVersions = [regex]::Matches($RawOutput, '(?<=")\d+(?=")') | ForEach-Object { $_.Value }

	$VersionsQuantity = Read-Host "$(Get-Lang 'AskVerCount') $(Get-Lang 'CancelStep')`n"
	
	if ($VersionsQuantity -eq '0') { return }
	
	$VerQty = 0
	if (![int]::TryParse($VersionsQuantity, [ref]$VerQty) -or $VerQty -le 0) {
		Show-Error "ErrorInvalidInput"
		return
	}

	$RecentVersions = $RawVersions | Select-Object -Last $VerQty | Sort-Object -Descending
	
	$VersionMapping = @()
	$Counter = 1
	Separator
	Write-Host ("{0,-3} {1,-12} {2}" -f "№", (Get-Lang "HeaderVerID"), (Get-Lang "HeaderVersion"))
	foreach ($VersionId in $RecentVersions) {
		$Meta = & "$ipatoolFilePath" get-version-metadata -i $AppId --external-version-id $VersionId 2>$null
		$DisplayVersion = if ($Meta -match 'displayVersion=([^\s,]+)') { $Matches[1] } else { "NA" }
		Write-Host ("{0,-3} {1,-12} {2}" -f $Counter, $VersionId, $DisplayVersion)
		$VersionMapping += [PSCustomObject]@{ Index = $Counter; ID = $VersionId; Version = $DisplayVersion }
		$Counter++
	}
	Separator
	
	$SelectedIndices = Read-NumberSelection -PromptKey 'AskVerNum' -MaxCount $VersionMapping.Count
	if ($null -eq $SelectedIndices) { return }
	
	$SelectedVersions = @()
	foreach ($Idx in $SelectedIndices) {
		$SelectedVersions += $VersionMapping[$Idx - 1]
	}

	foreach ($SelectedObject in $SelectedVersions) {
		Separator
		Write-Host "$(Get-Lang 'SelectedVer') $($SelectedObject.Version)"
		Separator
		$FinalId = $SelectedObject.ID
		& "$ipatoolFilePath" download -i $AppId --external-version-id $FinalId
		Move-IPA-Files -AppId $AppId -AppName $AppName
	}
}

# Функция выполнения действия с приложением: вывод "Выбрано приложение" + покупка/загрузка/загрузка с выбором версии:
function Invoke-AppAction {
	param (
		[string]$AppId,
		[string]$AppName,
		[string]$DisplayName,
		[ValidateSet("Purchase", "Download", "DownloadVersion")][string]$Action
	)
	Separator
	Write-Host "$(Get-Lang 'SelectedApp') $DisplayName"
	switch ($Action) {
		"Purchase" {
			Separator
			& "$ipatoolFilePath" purchase -i $AppId
			Save-App-To-List -AppId $AppId -AppNameOnly $AppName -Type "Purchased"
		}
		"Download" {
			IPA-Download -AppId $AppId -AppName $AppName
		}
		"DownloadVersion" {
			IPA-Download-With-Version -AppId $AppId -AppName $AppName
		}
	}
}

# Функция поиска приложений:
function Search-Apps-Menu {
	Separator
	$AppName = Read-Host "$(Get-Lang 'AskSearch') $(Get-Lang 'CancelStep')`n"
	
	if ($AppName -eq '0') { return $null }

	if ([string]::IsNullOrWhiteSpace($AppName)) {
		Show-Error "ErrorInvalidInput"
		return $null
	}

	$SearchOutput = & "$ipatoolFilePath" search $AppName --limit 10 *>&1 | Out-String
	if ($SearchOutput -match 'apps=(\[.*?\])') {
		$JsonString = $Matches[1]
		if ($JsonString -eq '[]') {
			Show-Error "ErrorNoAppsFound"
			return $null
		} else {
			$FoundApps = $JsonString | ConvertFrom-Json
			Separator
			Write-Host ("{0,-3} {1,-30} {2}" -f "№", (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID"))
			
			$Counter = 1
			foreach ($App in $FoundApps) {
				$PrintName = if ($App.name.Length -gt 30) { $App.name.Substring(0, 27) + "..." } else { $App.name }
				Write-Host ("{0,-3} {1,-30} {2}" -f $Counter, $PrintName, $App.id)
				$Counter++
			}
			Separator
			$Indices = Read-NumberSelection -PromptKey 'AskAppNum' -MaxCount $FoundApps.Count
			if ($null -eq $Indices) { return $null }

			$SelectedApps = @()
			foreach ($Idx in $Indices) {
				$SelectedApps += $FoundApps[$Idx - 1]
			}
			return $SelectedApps
		}
	} else {
		Show-Error "ErrorNoAppsFound"
		return $null
	}
}

# Функция получения списка ID:
function Get-Multiple-AppIds {
	param ([string]$PromptKey)
	Separator
	$InputRaw = Read-Host "$(Get-Lang $PromptKey) $(Get-Lang 'CancelStep')`n"
	if ($InputRaw -eq '0') { return $null }

	if ([string]::IsNullOrWhiteSpace($InputRaw)) {
		Show-Error "ErrorInvalidInput"
		return $null
	}

	$RawParts = $InputRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
	$AppIds = @()

	foreach ($Part in $RawParts) {
		if ($Part -notmatch '^\d+$') {
			Show-Error "ErrorInvalidInput"
			return $null
		}
		$AppIds += $Part
	}

	if ($AppIds.Count -eq 0) {
		Show-Error "ErrorInvalidInput"
		return $null
	}
	return $AppIds
}

# Функция получения списка выбранных приложений:
function Get-Apps-From-List {
	param (
		[string]$ListMode = "Download"
	)
	
	$MenuTitle = Get-Lang 'ListMenuTitle'
	$Menu1 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedListMenu1' } else { Get-Lang 'DownloadedListMenu1' }
	$Menu2 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedListMenu2' } else { Get-Lang 'DownloadedListMenu2' }
	$Menu3 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedListMenu3' } else { Get-Lang 'DownloadedListMenu3' }
	$TargetFile = if ($ListMode -eq "Purchase") { "$PurchasedIDsFilePath" } else { "$DownloadedIDsFilePath" }
	$EmptyError = if ($ListMode -eq "Purchase") { "ErrorPurchasedEmpty" } else { "ErrorHistoryEmpty" }

	$List_Menu = @"
$MenuTitle $(Get-Lang 'CancelStep')
$Menu1
$Menu2
$Menu3`n
"@
	$ListChoice = Read-Host $List_Menu

	if ($ListChoice -eq '0') { return $null }

	$Lines = @()

	switch ($ListChoice) {
		"1" {
			Initialize-GitHub-List
			if ($Global:GitHubParsedList.Count -eq 0) {
				Show-Error "ErrorListLoadError"
				return $null
			}
			foreach ($App in $Global:GitHubParsedList) {
				$Lines += "{0}: {1}" -f $App.Name, $App.Id
			}
		}
		
		"2" {
			$HistoryData = Read-AppList-Json -FilePath $TargetFile -EmptyError $EmptyError
			if ($null -eq $HistoryData) { return $null }
			
			foreach ($Item in $HistoryData) {
				$Lines += "{0}: {1}" -f $Item.name, $Item.appid
			}
		}
		
		"3" {
			Initialize-GitHub-List
			if ($Global:GitHubParsedList.Count -eq 0) {
				Show-Error "ErrorListLoadError"
				return $null
			}

			$SavedIds = @()
			if (Test-Path $TargetFile) {
				$HistoryData = Read-AppList-Json -FilePath $TargetFile -EmptyError $EmptyError
				if ($null -ne $HistoryData) {
					$SavedIds = $HistoryData.appid
				}
			}

			foreach ($App in $Global:GitHubParsedList) {
				if ($App.Id -and $SavedIds -notcontains $App.Id) {
					$Lines += "{0}: {1}" -f $App.Name, $App.Id
				}
			}
		}
		
		default {
			Show-Error "ErrorInvalidInput"
			return $null
		}
	}

	if ($Lines.Count -eq 0) {
		Show-Error "ErrorNoAppsFound"
		return $null
	}

	Separator
	for ($I = 0; $I -lt $Lines.Count; $I++) {
		$Index = $I + 1
		Write-Host ("{0}. {1}" -f $Index, $Lines[$I])
	}
	
	Separator
	$SelectedIndices = Read-NumberSelection -PromptKey 'AskAppNum' -MaxCount $Lines.Count
	if ($null -eq $SelectedIndices) { return $null }

	$SelectedApps = @()
	
	foreach ($Idx in $SelectedIndices) {
		$SelectedLine = $Lines[$Idx - 1]
		$AppId = [System.Text.RegularExpressions.Regex]::Match($SelectedLine, '\b\d{6,}\b').Value
		
		$AppName = "Unknown"
		if ($SelectedLine -match '^(.+?):\s*\d') {
			$AppName = $Matches[1].Trim()
		}

		if (![string]::IsNullOrEmpty($AppId)) {
			$SelectedApps += [PSCustomObject]@{
				Id = $AppId.Trim()
				Name = $AppName
			}
		}
	}
	return $SelectedApps
}

# Функция проверки минимальной версии iOS:
function Get-iOS-MinVersion {
	$FilesToProcess = Get-ChildItem -Path "$AppsFolderPath" -Filter "*.ipa" -File -ErrorAction SilentlyContinue
	
	if (-not $FilesToProcess) {
		Show-Error "ErrorNoApps"
		return $null
	}
	
	Separator
	Write-Host ("{0,-3} {1,-30} {2}" -f "№", (Get-Lang "HeaderFileName"), (Get-Lang "HeaderMinIOS"))
	$Counter = 1
	
	foreach ($File in $FilesToProcess) {
		$Meta = Get-IPA-Metadata -IpaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)+" } else { "Error" }
		$PrintName = if ($File.Name.Length -gt 30) { $File.Name.Substring(0,27) + "..." } else { $File.Name }
		Write-Host ("{0,-3} {1,-30} {2}" -f $Counter, $PrintName, $MinOs)
		$Counter++
	}
	return @($FilesToProcess)
}

# Функция вывода ошибки об отсутствующих файлах:
function Confirm-RequiredFiles {
	param ([array]$MissingFiles)
	if ($MissingFiles) {
		Separator
		Write-Host (Get-Lang "ErrorMissingFiles") -ForegroundColor DarkRed
		$MissingFiles | ForEach-Object { Write-Host "$_" -ForegroundColor DarkRed }
		Separator
		exit
	}
}

# Версия скрипта:
Separator
Write-Host "IPA_Downloader 3.9.1 (ipatool_$ArchSubFolder)"

# Операционная система:
Separator
Write-Host "$OSVersion"

# Проверка на наличие базовых папок:
foreach ($Dir in @("$AppsFolderPath", "$ListsFolderPath", "$MainAppFolderPath", "$ipatoolHomePath")) {
	if (!(Test-Path $Dir)) {
		$null = New-Item -Path $Dir -ItemType "Directory"
	}
}

# Загрузка сохраненного языка или установка по умолчанию:
if (Test-Path $LangConfigFilePath) {
	$SavedLang = (Get-Content $LangConfigFilePath -Raw).Trim().ToUpper()
	if ($SavedLang -match '^(RU|EN)$') {
		$Global:CurrentLang = $SavedLang
	}
} else {
	Set-Content -Path $LangConfigFilePath -Value $Global:CurrentLang -Force
}

# Проверка и установка зависимостей:
if ($IsWin) {
	# Windows: ищем ideviceinstaller.exe и ipatool.exe в локальной папке:
	$RequiredFiles = @("ideviceinstaller.exe", "ipatool.exe")
	$ExistingFiles = @()
	
	if (Test-Path -Path $BinaryFolderPath) {
		$ExistingFiles = Get-ChildItem -Path $BinaryFolderPath -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
	}
	
	$MissingMainAppFiles = foreach ($File in $RequiredFiles) {
		if ($File -notin $ExistingFiles) {
			Join-Path -Path $BinaryFolderPath -ChildPath $File
		}
	}

	Confirm-RequiredFiles -MissingFiles $MissingMainAppFiles
	
	$ipatoolFilePath = Join-Path -Path $BinaryFolderPath -ChildPath "ipatool.exe"
	$ideviceinstallerFilePath = Join-Path -Path $BinaryFolderPath -ChildPath "ideviceinstaller.exe"
	
} else {
	# macOS: поиск ipatool в локальной папке:
	$ipatoolFilePath = Join-Path -Path $BinaryFolderPath -ChildPath "ipatool"
	
	# Поиск ideviceinstaller:
	$ideviceinstallerFilePath = (Get-Command ideviceinstaller -ErrorAction SilentlyContinue).Source
	if (-not $ideviceinstallerFilePath) {
		Write-Host (Get-Lang "ErrorMacIdeviceinstallerNotFound") -ForegroundColor DarkRed
	}
	
	$MissingMacFiles = @()
	
	if (-not (Test-Path $ipatoolFilePath)) {
		$MissingMacFiles += $ipatoolFilePath
	}
	
	# Финальная проверка файлов:
	Confirm-RequiredFiles -MissingFiles $MissingMacFiles
	
	# Права доступа на macOS:
	xattr -cr "$MainAppFolderPath" 2>$null
	chmod +x "$ipatoolFilePath" 2>$null
}

# Удаление временных файлов при запуске:
Get-ChildItem -Path $PSScriptRoot -Filter "*.ipa.tmp" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
if (Test-Path $AppsIDTempListPath) { Remove-Item $AppsIDTempListPath -Force -ErrorAction SilentlyContinue }

# Проверка на Windows 7 и включение TLS 1.2:
if ($WindowsVersion.Major -eq 6 -and $WindowsVersion.Minor -eq 1) {
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Асинхронное фоновое обновление списка приложений с GitHub:
$AppsIDListDownload = {
	param($Url, $FinalPath, $TempPath)
	try {
		if ([System.Environment]::OSVersion.Version.Major -eq 6 -and [System.Environment]::OSVersion.Version.Minor -eq 1) {
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		}
		
		# Скачиваем список приложений во временный файл в папку MainApp:
		Invoke-RestMethod -Uri $Url -OutFile $TempPath -ErrorAction SilentlyContinue
		
		if (Test-Path $TempPath) {
			# Проверка на то, что файл загрузился:
			if ((Get-Item $TempPath).Length -gt 10) {
				Move-Item -Path $TempPath -Destination $FinalPath -Force
			} else {
				Remove-Item $TempPath -Force
			}
		}
	} catch {}
}

$BackgroundJob = Start-Job -ScriptBlock $AppsIDListDownload -ArgumentList "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt", $AppsIDListPath, $AppsIDTempListPath

# Проверка наличия файла account:
if (Test-Path "$AccountFilePath") {
	Separator
	Write-Host (Get-Lang "AuthSuccess")
	& "$ipatoolFilePath" auth info
}

# Вход с Apple ID:
Connect-AppleID

# Основной цикл:
while (Test-Path "$AccountFilePath") {
    # Удаление завершенных фоновых задач для предотвращения утечки памяти:
    Get-Job | Where-Object { $_.State -eq 'Completed' } | Remove-Job -Force

	Separator
	$MainMenu = @"
$(Get-Lang 'MenuTitle')
$(Get-Lang 'Menu1')
$(Get-Lang 'Menu2')
$(Get-Lang 'Menu3')
$(Get-Lang 'Menu4')
$(Get-Lang 'Menu5')
$(Get-Lang 'Menu6')
$(Get-Lang 'Menu7')
$(Get-Lang 'Menu8')
$(Get-Lang 'Menu9')
$(Get-Lang 'Menu10')
$(Get-Lang 'Menu11')
$(Get-Lang 'Menu12')
$(Get-Lang 'Menu13')
$(Get-Lang 'Menu14')
$(Get-Lang 'Menu15')`n
"@

	$SwitchValue = Read-Host $MainMenu
	switch ($SwitchValue) {
		
		# 1. Поиск приложения и покупка (без загрузки):
		"1" {
			$AppsToProcess = Search-Apps-Menu
			if ($null -ne $AppsToProcess) {
				foreach ($App in $AppsToProcess) {
					Invoke-AppAction -AppId $App.id -AppName $App.name -DisplayName $App.name -Action "Purchase"
				}
			}
		}
		
		# 2. Поиск приложения и загрузка последней версии:
		"2" {
			$AppsToProcess = Search-Apps-Menu
			if ($null -ne $AppsToProcess) {
				foreach ($App in $AppsToProcess) {
					Invoke-AppAction -AppId $App.id -AppName $App.name -DisplayName $App.name -Action "Download"
				}
			}
		}
		
		# 3. Поиск приложения и загрузка (с выбором версии):
		"3" {
			$AppsToProcess = Search-Apps-Menu
			if ($null -ne $AppsToProcess) {
				foreach ($App in $AppsToProcess) {
					Invoke-AppAction -AppId $App.id -AppName $App.name -DisplayName $App.name -Action "DownloadVersion"
				}
			}
		}

		# 4. Ввод ID приложений и покупка (без загрузки):
		"4" {
			$AppIds = Get-Multiple-AppIds -PromptKey 'AskIdPurchase'
			if ($null -ne $AppIds) {
				foreach ($Id in $AppIds) {
					$AppNames = Resolve-AppDisplayName -AppId $Id
					Invoke-AppAction -AppId $Id -AppName $AppNames.Final -DisplayName $AppNames.Display -Action "Purchase"
				}
			}
		}

		# 5. Ввод ID приложений и загрузка последней версии:
		"5" {
			$AppIds = Get-Multiple-AppIds -PromptKey 'AskIdDownload'
			if ($null -ne $AppIds) {
				foreach ($Id in $AppIds) {
					$AppNames = Resolve-AppDisplayName -AppId $Id
					Invoke-AppAction -AppId $Id -AppName $AppNames.Final -DisplayName $AppNames.Display -Action "Download"
				}
			}
		}
		
		# 6. Ввод ID приложений и загрузка (с выбором версии):
		"6" {
			$AppIds = Get-Multiple-AppIds -PromptKey 'AskIdSearch'
			if ($null -ne $AppIds) {
				foreach ($Id in $AppIds) {
					$AppNames = Resolve-AppDisplayName -AppId $Id
					Invoke-AppAction -AppId $Id -AppName $AppNames.Final -DisplayName $AppNames.Display -Action "DownloadVersion"
				}
			}
		}
		
		# 7. Вывод списка ID приложений и покупка (без загрузки):
		"7" {
			Separator
			$SelectedApps = Get-Apps-From-List -ListMode "Purchase"
			if ($null -ne $SelectedApps) {
				foreach ($App in $SelectedApps) {
					Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Purchase"
				}
			}
		}

		# 8. Вывод списка ID приложений и загрузка последней версии:
		"8" {
			Separator
			$SelectedApps = Get-Apps-From-List -ListMode "Download"
			if ($null -ne $SelectedApps) {
				foreach ($App in $SelectedApps) {
					Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Download"
				}
			}
		}
		
		# 9. Вывод списка ID приложений и загрузка (с выбором версии):
		"9" {
			Separator
			$SelectedApps = Get-Apps-From-List -ListMode "Download"
			if ($null -ne $SelectedApps) {
				foreach ($App in $SelectedApps) {
					Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "DownloadVersion"
				}
			}
		}
		
		# 10. Проверка минимальной версии iOS для приложений в папке Apps:
		"10" {
			$null = Get-iOS-MinVersion
		}
		
		# 11. Установка приложений из папки Apps:
		"11" {
			if ([string]::IsNullOrWhiteSpace($ideviceinstallerFilePath)) {
				Show-Error "ErrorMacIdeviceinstallerNotFound"
				continue
			}

			$IpaFiles = Get-iOS-MinVersion
			if ($null -ne $IpaFiles) {
				Separator
				$SelectedIndices = Read-NumberSelection -PromptKey 'AskAppNum' -MaxCount $IpaFiles.Count
				if ($null -eq $SelectedIndices) { continue }

				foreach ($Idx in $SelectedIndices) {
					$SelectedFile = $IpaFiles[$Idx - 1]
					Separator
					Write-Host "$(Get-Lang 'InstallApp') $($SelectedFile.Name)"
					$TempFile = "$TempIpaFilePath"
					Copy-Item -Path $SelectedFile.FullName -Destination $TempFile -Force
					& "$ideviceinstallerFilePath" install $TempFile
					Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
				}
			}
		}
		
		# 12. Очистка данных скрипта:
		"12" {
			Separator
			$Clear_Menu = @"
$(Get-Lang 'ClearMenuTitle') $(Get-Lang 'CancelStep')
$(Get-Lang 'ClearMenu1')
$(Get-Lang 'ClearMenu2')
$(Get-Lang 'ClearMenu3')`n
"@
			$ClearChoice = Read-Host ($Clear_Menu)
			
			if ($ClearChoice -eq '0') { continue }
			
			switch ($ClearChoice) {
				"1" {
					Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
					Separator
					Write-Host (Get-Lang "DownloadedListCleared")
				}
				
				"2" {
					Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
					Separator
					Write-Host (Get-Lang "PurchasedListCleared")
				}
				
				"3" {
					$ipaFilesToRemove = Get-ChildItem -Path $AppsFolderPath -Filter "*.ipa" -File -ErrorAction SilentlyContinue
					if ($ipaFilesToRemove) {
						$ipaFilesToRemove | Remove-Item -Force -ErrorAction SilentlyContinue
						Separator
						Write-Host (Get-Lang "AppsCleared")
					} else {
						Show-Error "ErrorNoApps"
					}
				}
				
				default {
					Show-Error "ErrorInvalidInput"
				}
			}
		}
		
		# 13. Выход из Apple ID:
		"13" {
			Separator
			Write-Host (Get-Lang "LoggedOut")
			& "$ipatoolFilePath" auth revoke
			Connect-AppleID
		}
		
		# 14. Страница проекта на GitHub:
		"14" {
			Start-Process "https://github.com/kda2495/IPA_Downloader"
		}
		
		# 15. Сменить язык (Change Language):
		"15" {
			$Global:CurrentLang = if ($Global:CurrentLang -eq "RU") { "EN" } else { "RU" }
			Set-Content -Path $LangConfigFilePath -Value $Global:CurrentLang -Force
			Separator
			Write-Host (Get-Lang "LangChanged")
		}
		
		# Неверный ввод:
		default {
			Show-Error "ErrorInvalidInput"
		}
	}
}