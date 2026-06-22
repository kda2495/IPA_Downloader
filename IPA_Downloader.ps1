# Переключение рабочей директории в папку со скриптом:
Set-Location -Path $PSScriptRoot

# Версия скрипта:
$ScriptVersion = "4.0.0"

# Определение запуска на Windows:
$IsWin = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)

# Папка MainApp и единый файл настроек (язык, режим работы, версия ipatool):
$MainAppFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "MainApp"
$SettingsFilePath = Join-Path -Path $MainAppFolderPath -ChildPath "Settings.txt"

# Функция чтения всех настроек из Settings.txt:
function Get-Settings {
	$Settings = @{}
	if (Test-Path $SettingsFilePath) {
		Get-Content $SettingsFilePath -ErrorAction SilentlyContinue | ForEach-Object {
			if ($_ -match '^\s*([^=]+?)\s*=\s*(.*)$') {
				$Settings[$Matches[1]] = $Matches[2].Trim()
			}
		}
	}
	return $Settings
}

# Функция сохранения одной настройки:
function Set-Setting {
	param ([string]$Key, [string]$Value)
	$Settings = Get-Settings
	$Settings[$Key] = $Value
	$Lines = foreach ($K in $Settings.Keys) { "$K=$($Settings[$K])" }
	Set-Content -Path $SettingsFilePath -Value $Lines -Force
}

# Загрузка сохраненных настроек (язык, режим работы, версия ipatool) или значений по умолчанию:
$SavedSettings = Get-Settings
$Global:CurrentLang = if ($SavedSettings['Language'] -match '^(RU|EN)$') { $SavedSettings['Language'] } else { "RU" }
$Global:WorkMode = if ($SavedSettings['Mode'] -in @('Downloader', 'Installer')) { $SavedSettings['Mode'] } else { $null }
$IpatoolVersion = if ($SavedSettings['IpatoolVersion'] -eq 'v3') { 'v3' } else { 'v2' }

# Определение архитектуры macOS:
if (-not $IsWin) {
	$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
}

# Функция вычисления имени папки с ipatool для конкретной версии (v2/v3) под текущую систему/архитектуру:
function Get-ArchSubFolder {
	param ([ValidateSet("v2", "v3")][string]$Version)
	
	if ($IsWin) {
		if ($Version -eq "v3") { return "windows_amd64_v3" } else { return "windows_amd64_v2" }
	} elseif ($Arch -eq "arm64") {
		if ($Version -eq "v3") { return "macOS_arm64_v3" } else { return "macOS_arm64_v2" }
	} else {
		if ($Version -eq "v3") { return "macOS_amd64_v3" } else { return "macOS_amd64_v2" }
	}
}

# Определение системы и архитектуры:
$ArchSubFolder = Get-ArchSubFolder -Version $IpatoolVersion

# Определение основных папок и переменных:
$OSVersion = [System.Environment]::OSVersion
$WindowsVersion = [System.Environment]::OSVersion.Version
$BinaryFolderPath = Join-Path -Path $MainAppFolderPath -ChildPath $ArchSubFolder
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
		"InstallerMenu1" = "1. Проверка минимальной версии iOS для приложений в папке Apps"
		"InstallerMenu2" = "2. Установка приложений из папки Apps"
		"InstallerMenu3" = "3. Страница проекта на GitHub"
		"InstallerMenu4" = "4. Сменить язык (Change Language)"
		"InstallerMenu5" = "5. Перейти в IPA_Downloader"
		"IpatoolVersionMenuTitle" = "Выберите версию ipatool:"
		"LangChanged" = "Язык успешно изменен на Русский."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
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
		"Menu13" = "13. Сброс настроек"
		"Menu14" = "14. Страница проекта на GitHub"
		"Menu15" = "15. Сменить язык (Change Language)"
		"MenuTitle" = "Введите команду:"
		"MinIOS" = "Минимальная версия iOS:"
		"ModeMenu1" = "1. IPA_Downloader"
		"ModeMenu2" = "2. IPA_Installer"
		"ModeMenuTitle" = "Выберите режим работы:"
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
		"InstallerMenu1" = "1. Check minimum iOS version for apps in Apps folder"
		"InstallerMenu2" = "2. Install apps from Apps folder"
		"InstallerMenu3" = "3. GitHub project page"
		"InstallerMenu4" = "4. Change Language (Сменить язык)"
		"InstallerMenu5" = "5. Switch to IPA_Downloader"
		"IpatoolVersionMenuTitle" = "Select ipatool version:"
		"LangChanged" = "Language successfully changed to English."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
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
		"Menu13" = "13. Reset settings"
		"Menu14" = "14. GitHub project page"
		"Menu15" = "15. Change Language (Сменить язык)"
		"MenuTitle" = "Enter a command:"
		"MinIOS" = "Minimum iOS version:"
		"ModeMenu1" = "1. IPA_Downloader"
		"ModeMenu2" = "2. IPA_Installer"
		"ModeMenuTitle" = "Select operating mode:"
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

# Функция запроса пункта меню:
function Read-MenuChoice {
	param (
		[string]$MenuText,
		[int]$OptionsCount,
		[switch]$AllowCancel
	)
	
	while ($true) {
		$Choice = Read-Host $MenuText
		
		if ($AllowCancel -and $Choice -eq '0') {
			return '0'
		}
		
		if (($Choice -match '^\d+$') -and ([int]$Choice -ge 1) -and ([int]$Choice -le $OptionsCount)) {
			return $Choice
		}
		
		Show-Error "ErrorInvalidInput"
		Separator
	}
}

# Функция получения имени приложения по ID:
function Resolve-AppDisplayName {
	param ([string]$AppId)
	$GitHubName = Get-GitHub-AppName -AppId $AppId
	return @{
		Display = if ([string]::IsNullOrWhiteSpace($GitHubName)) { $AppId } else { $GitHubName }
		Final = if ([string]::IsNullOrWhiteSpace($GitHubName)) { "Unknown" } else { $GitHubName }
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

# Функция извлечения метаданных из ipa:
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

# Функция поиска имени приложения по кэшу:
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

# Функция запроса номеров:
function Read-NumberSelection {
	param (
		[string]$PromptKey,
		[int]$MaxCount
	)
	
	while ($true) {
		$Selection = Read-Host "$(Get-Lang $PromptKey) (1-$MaxCount) $(Get-Lang 'CancelStep')`n"
		
		if ($Selection -eq '0') { return $null }
		
		if ([string]::IsNullOrWhiteSpace($Selection)) {
			Show-Error "ErrorInvalidInput"
			Separator
			continue
		}
		
		$SelectedIndices = Parse-NumberSelection -Selection $Selection -MaxCount $MaxCount
		if ($null -eq $SelectedIndices) {
			Show-Error "ErrorInvalidInput"
			Separator
			continue
		}
		
		return $SelectedIndices
	}
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

	$VerQty = 0
	while ($true) {
		$VersionsQuantity = Read-Host "$(Get-Lang 'AskVerCount') $(Get-Lang 'CancelStep')`n"
		
		if ($VersionsQuantity -eq '0') { return }
		
		if ([int]::TryParse($VersionsQuantity, [ref]$VerQty) -and $VerQty -gt 0) {
			break
		}
		
		Show-Error "ErrorInvalidInput"
		Separator
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

# Функция выполнения действия с приложением:
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
	while ($true) {
		Separator
		$AppName = Read-Host "$(Get-Lang 'AskSearch') $(Get-Lang 'CancelStep')`n"
		
		if ($AppName -eq '0') { return $null }
		if (![string]::IsNullOrWhiteSpace($AppName)) { break }
		
		Show-Error "ErrorInvalidInput"
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
	
	while ($true) {
		Separator
		$InputRaw = Read-Host "$(Get-Lang $PromptKey) $(Get-Lang 'CancelStep')`n"
		if ($InputRaw -eq '0') { return $null }
		
		if ([string]::IsNullOrWhiteSpace($InputRaw)) {
			Show-Error "ErrorInvalidInput"
			continue
		}
		
		$RawParts = $InputRaw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
		$AppIds = @()
		$AllValid = $true
		
		foreach ($Part in $RawParts) {
			if ($Part -notmatch '^\d+$') {
				$AllValid = $false
				break
			}
			$AppIds += $Part
		}
		
		if ($AllValid -and $AppIds.Count -gt 0) {
			return $AppIds
		}
		
		Show-Error "ErrorInvalidInput"
	}
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
	$ListChoice = Read-MenuChoice -MenuText $List_Menu -OptionsCount 3 -AllowCancel

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

# Функция добавления папки с ipatool в PATH текущего процесса:
function Update-PathFolder {
	param (
		[string]$NewFolder,
		[string]$OldFolder = $null
	)
	
	$PathSeparator = if ($IsWin) { ';' } else { ':' }
	$PathEntries = $env:Path -split [regex]::Escape($PathSeparator) | Where-Object {
		$_ -and ($_ -ne $NewFolder) -and ($_ -ne $OldFolder)
	}
	$PathEntries += $NewFolder
	$env:Path = ($PathEntries -join $PathSeparator)
}

# Функция установки путей к ipatool/ideviceinstaller для указанной папки версии и применения PATH/прав запуска:
function Set-IpatoolBinaryPaths {
	param (
		[string]$FolderPath,
		[string]$OldFolderPath = $null
	)
	
	if ($IsWin) {
		$script:ipatoolFilePath = Join-Path -Path $FolderPath -ChildPath "ipatool.exe"
		$script:ideviceinstallerFilePath = Join-Path -Path $FolderPath -ChildPath "ideviceinstaller.exe"
		
		# Добавление папки с ipatool в PATH текущего процесса (с заменой старой папки при смене версии):
		Update-PathFolder -NewFolder $FolderPath -OldFolder $OldFolderPath
	} else {
		$script:ipatoolFilePath = Join-Path -Path $FolderPath -ChildPath "ipatool"
		
		# Снятие карантина и выдача прав на запуск:
		xattr -cr "$FolderPath" 2>$null
		chmod +x "$script:ipatoolFilePath" 2>$null
	}
}

# Функция проверки наличия необходимых файлов:
function Get-MissingBinaryFiles {
	param ([string]$FolderPath)
	
	if ($IsWin) {
		$RequiredFiles = @("ideviceinstaller.exe", "ipatool.exe")
		$ExistingFiles = @()
		if (Test-Path -Path $FolderPath) {
			$ExistingFiles = Get-ChildItem -Path $FolderPath -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
		}
		$MissingFiles = foreach ($File in $RequiredFiles) {
			if ($File -notin $ExistingFiles) {
				Join-Path -Path $FolderPath -ChildPath $File
			}
		}
		return $MissingFiles
	} else {
		$IpatoolPath = Join-Path -Path $FolderPath -ChildPath "ipatool"
		if (-not (Test-Path $IpatoolPath)) {
			return @($IpatoolPath)
		}
		return @()
	}
}

# Функция установки конкретной версии ipatool:
function Set-IpatoolVersion {
	param ([ValidateSet("v2", "v3")][string]$Version)
	
	$OldBinaryFolderPath = $script:BinaryFolderPath
	$NewArchSubFolder = Get-ArchSubFolder -Version $Version
	$NewBinaryFolderPath = Join-Path -Path $MainAppFolderPath -ChildPath $NewArchSubFolder
	
	# Проверка наличия необходимых файлов в папке выбранной версии:
	$MissingVersionFiles = Get-MissingBinaryFiles -FolderPath $NewBinaryFolderPath
	if ($MissingVersionFiles) {
		Separator
		Write-Host (Get-Lang "ErrorMissingFiles") -ForegroundColor DarkRed
		$MissingVersionFiles | ForEach-Object { Write-Host "$_" -ForegroundColor DarkRed }
		return $false
	}
	
	# Применение выбранной версии ipatool:
	$script:IpatoolVersion = $Version
	$script:ArchSubFolder = $NewArchSubFolder
	$script:BinaryFolderPath = $NewBinaryFolderPath
	
	Set-IpatoolBinaryPaths -FolderPath $script:BinaryFolderPath -OldFolderPath $OldBinaryFolderPath
	
	return $true
}

# Функция запроса версии ipatool с проверкой наличия файлов:
function Invoke-IpatoolVersionPrompt {
	#$V2Label = "ipatool_$(Get-ArchSubFolder -Version 'v2')"
	#$V3Label = "ipatool_$(Get-ArchSubFolder -Version 'v3')"
	
	#while ($true) {
		#Separator
		#$Version_Menu = @"
#$(Get-Lang 'IpatoolVersionMenuTitle')
#1. $V2Label
#2. $V3Label`n
#"@
		#$VersionChoice = Read-MenuChoice -MenuText $Version_Menu -OptionsCount 2
		#$SelectedVersion = if ($VersionChoice -eq '2') { 'v3' } else { 'v2' }
		
		#if (Set-IpatoolVersion -Version $SelectedVersion) {
			#return
		#}
	#}
}

# Функция установки приложений из папки Apps:
function Invoke-InstallApps {
	if ([string]::IsNullOrWhiteSpace($script:ideviceinstallerFilePath)) {
		Show-Error "ErrorMacIdeviceinstallerNotFound"
		return
	}
	
	$IpaFiles = Get-iOS-MinVersion
	if ($null -ne $IpaFiles) {
		Separator
		$SelectedIndices = Read-NumberSelection -PromptKey 'AskAppNum' -MaxCount $IpaFiles.Count
		if ($null -eq $SelectedIndices) { return }
		
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

# Функция вывода баннера с текущим режимом работы, версией скрипта и системой/архитектурой:
function Show-ModeBanner {
	$ModeLabel = if ($Global:WorkMode -eq "Installer") { "IPA_Installer" } else { "IPA_Downloader" }
	Separator
	Write-Host "$ModeLabel $ScriptVersion ($ArchSubFolder)"
}

# Функция первоначальной настройки (язык, режим работы, версия ipatool):
function Invoke-SetupWizard {
	# Удаление содержимого папки .ipatool
	Get-ChildItem -Path $ipatoolHomePath -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

	# Запрос на выбор языка:
	Separator
	$Language_Menu = @"
$(Get-Lang 'LanguageMenuTitle')
$(Get-Lang 'LanguageMenu1')
$(Get-Lang 'LanguageMenu2')`n
"@
	$LanguageChoice = Read-MenuChoice -MenuText $Language_Menu -OptionsCount 2
	$Global:CurrentLang = if ($LanguageChoice -eq '1') { "RU" } else { "EN" }
	Set-Setting -Key "Language" -Value $Global:CurrentLang
	
	# Запрос на выбор режима работы:
	Separator
	$Mode_Menu = @"
$(Get-Lang 'ModeMenuTitle')
$(Get-Lang 'ModeMenu1')
$(Get-Lang 'ModeMenu2')`n
"@
	$ModeChoice = Read-MenuChoice -MenuText $Mode_Menu -OptionsCount 2
	$Global:WorkMode = if ($ModeChoice -eq '2') { "Installer" } else { "Downloader" }
	
	# Режим IPA_Installer сохраняется сразу:
	if ($Global:WorkMode -eq "Installer") {
		Set-Setting -Key "Mode" -Value $Global:WorkMode
	}
	
	# Версия ipatool запрашивается только для режима IPA_Downloader:
	if ($Global:WorkMode -eq "Downloader") {
		Invoke-IpatoolVersionPrompt
	}
	
	Show-ModeBanner
}

# Операционная система:
Separator
Write-Host "$OSVersion"

# Проверка на наличие базовых папок:
foreach ($Dir in @("$AppsFolderPath", "$ListsFolderPath", "$MainAppFolderPath", "$ipatoolHomePath")) {
	if (!(Test-Path $Dir)) {
		$null = New-Item -Path $Dir -ItemType "Directory"
	}
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

# Функция режима IPA_Downloader:
function Invoke-DownloaderMode {
	# Проверка осуществленного входа с Apple ID:
	if (Test-Path "$AccountFilePath") {
		Separator
		Write-Host (Get-Lang "AuthSuccess")
		& "$ipatoolFilePath" auth info
	}
	
	# Вход с Apple ID:
	Connect-AppleID
	
	# Режим IPA_Downloader сохраняется только после успешной авторизации с Apple ID:
	Set-Setting -Key "Mode" -Value "Downloader"
	Set-Setting -Key "IpatoolVersion" -Value $script:IpatoolVersion
	
	# Основной цикл:
	while (Test-Path "$AccountFilePath") {
		# Удаление завершенных фоновых задач:
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
				Invoke-InstallApps
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
				$ClearChoice = Read-MenuChoice -MenuText $Clear_Menu -OptionsCount 3 -AllowCancel
				
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
				}
			}
			
			# 13. Сброс настроек:
			"13" {
				Separator
				Write-Host (Get-Lang "LoggedOut")
				& "$ipatoolFilePath" auth revoke
				
				Remove-Item -Path $SettingsFilePath -Force -ErrorAction SilentlyContinue
				$Global:WorkMode = $null
				return
			}
			
			# 14. Страница проекта на GitHub:
			"14" {
				Start-Process "https://github.com/kda2495/IPA_Downloader"
			}
			
			# 15. Сменить язык (Change Language):
			"15" {
				$Global:CurrentLang = if ($Global:CurrentLang -eq "RU") { "EN" } else { "RU" }
				Set-Setting -Key "Language" -Value $Global:CurrentLang
				Separator
				Write-Host (Get-Lang "LangChanged")
			}
			
			# Неверный ввод:
			default {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
}

# Функция режима IPA_Installer:
function Invoke-InstallerMode {
	while ($true) {
		Separator
		$Installer_Menu = @"
$(Get-Lang 'MenuTitle')
$(Get-Lang 'InstallerMenu1')
$(Get-Lang 'InstallerMenu2')
$(Get-Lang 'InstallerMenu3')
$(Get-Lang 'InstallerMenu4')
$(Get-Lang 'InstallerMenu5')`n
"@
		$SwitchValue = Read-Host $Installer_Menu
		switch ($SwitchValue) {
			
			# 1. Проверка минимальной версии iOS для приложений в папке Apps:
			"1" {
				$null = Get-iOS-MinVersion
			}
			
			# 2. Установка приложений из папки Apps:
			"2" {
				Invoke-InstallApps
			}
			
			# 3. Страница проекта на GitHub:
			"3" {
				Start-Process "https://github.com/kda2495/IPA_Downloader"
			}
			
			# 4. Сменить язык (Change Language):
			"4" {
				$Global:CurrentLang = if ($Global:CurrentLang -eq "RU") { "EN" } else { "RU" }
				Set-Setting -Key "Language" -Value $Global:CurrentLang
				Separator
				Write-Host (Get-Lang "LangChanged")
			}
			
			# 5. Перейти в IPA_Downloader:
			"5" {
				Invoke-IpatoolVersionPrompt
				$Global:WorkMode = "Downloader"
				return
			}
			
			# Неверный ввод:
			default {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
}

# Смена режима работы:
while ($true) {
	# Если режим работы не выбран, то запускаем мастер настройки, иначе показываем баннер:
	if ($null -eq $Global:WorkMode) {
		Invoke-SetupWizard
	} else {
		Show-ModeBanner
	}
	
	# Проверка наличия необходимых файлов:
	if ($IsWin) {
		# Windows: ищем ideviceinstaller.exe и ipatool.exe в локальной папке:
		$MissingMainAppFiles = Get-MissingBinaryFiles -FolderPath $BinaryFolderPath
		Confirm-RequiredFiles -MissingFiles $MissingMainAppFiles
		
		Set-IpatoolBinaryPaths -FolderPath $BinaryFolderPath
		
	} else {
		# macOS: поиск ideviceinstaller в системном PATH:
		$ideviceinstallerFilePath = (Get-Command ideviceinstaller -ErrorAction SilentlyContinue).Source
		if (-not $ideviceinstallerFilePath) {
			Write-Host (Get-Lang "ErrorMacIdeviceinstallerNotFound") -ForegroundColor DarkRed
		}
		
		# Финальная проверка файлов:
		$MissingMacFiles = Get-MissingBinaryFiles -FolderPath $BinaryFolderPath
		Confirm-RequiredFiles -MissingFiles $MissingMacFiles
		Set-IpatoolBinaryPaths -FolderPath $BinaryFolderPath
	}
	
	if ($Global:WorkMode -eq "Installer") {
		Invoke-InstallerMode
	} else {
		Invoke-DownloaderMode
	}
}