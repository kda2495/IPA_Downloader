# Переключение рабочей директории в папку со скриптом:
Set-Location -Path $PSScriptRoot

# Версия скрипта:
$ScriptVersion = "4.0.0"

# Определение операционной системы:
$IsWin = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
$IsMac = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)
$IsLin = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)

# Папка MainApp и файл настроек (язык, режим работы, версия ipatool):
$MainAppFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "MainApp"
$FilesFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Files"
$SettingsFilePath = Join-Path -Path $FilesFolderPath -ChildPath "Settings.txt"

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

# Функция сохранения настройки:
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
$IpatoolVersion = if ($SavedSettings['IpatoolVersion'] -eq 'ipatool-cpp') { 'ipatool-cpp' } else { 'ipatool-go' }

# Определение архитектуры macOS и Linux:
if (-not $IsWin) {
	$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
}

# Функция вычисления имени папки с ipatool под текущую систему/архитектуру:
function Get-ArchSubFolder {
	param ([ValidateSet("ipatool-cpp", "ipatool-go")][string]$Version)
	if ($IsWin) {
		if ($Version -eq "ipatool-cpp") { return "windows_amd64_ipatool-cpp" } else { return "windows_amd64_ipatool-go" }
	} elseif ($IsLin) {
		if ($Arch -eq "arm64") {
			if ($Version -eq "ipatool-cpp") { return "linux_arm64_ipatool-cpp" } else { return "linux_arm64_ipatool-go" }
		} else {
			if ($Version -eq "ipatool-cpp") { return "linux_amd64_ipatool-cpp" } else { return "linux_amd64_ipatool-go" }
		}
	} else {
		if ($Arch -eq "arm64") {
			if ($Version -eq "ipatool-cpp") { return "macOS_arm64_ipatool-cpp" } else { return "macOS_arm64_ipatool-go" }
		} else {
			if ($Version -eq "ipatool-cpp") { return "macOS_amd64_ipatool-cpp" } else { return "macOS_amd64_ipatool-go" }
		}
	}
}

# Определение системы и архитектуры:
$ArchSubFolder = Get-ArchSubFolder -Version $IpatoolVersion

# Определение основных папок и переменных:
$OSVersion = [System.Environment]::OSVersion
$PSVersion = $PSVersionTable.PSVersion.ToString()
$BinaryFolderPath = Join-Path -Path $MainAppFolderPath -ChildPath $ArchSubFolder
$DownloadedIDsFilePath = Join-Path -Path $FilesFolderPath -ChildPath "Downloaded_IDs.json"
$PurchasedIDsFilePath = Join-Path -Path $FilesFolderPath -ChildPath "Purchased_IDs.json"
$AppsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Apps"
$ipatoolHomePath = Join-Path -Path $HOME -ChildPath ".ipatool"
$AccountFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "account"
$CookiesFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "cookies"
$TempFolderPath = [System.IO.Path]::GetTempPath()
$TempIpaFilePath = Join-Path -Path $TempFolderPath -ChildPath "Temp.ipa"
$AppsIDListPath = Join-Path -Path $FilesFolderPath -ChildPath "Apps_ID_List.txt"
$AppsIDTempListPath = Join-Path -Path $MainAppFolderPath -ChildPath "Apps_ID_List_tmp.txt"
$WarningRUPath = Join-Path -Path $FilesFolderPath -ChildPath "Warning_RU.txt"
$WarningENPath = Join-Path -Path $FilesFolderPath -ChildPath "Warning_EN.txt"
$WarningRUTempPath = Join-Path -Path $MainAppFolderPath -ChildPath "Warning_RU_tmp.txt"
$WarningENTempPath = Join-Path -Path $MainAppFolderPath -ChildPath "Warning_EN_tmp.txt"

# Настройка консоли (для Windows):
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
	chcp 65001 > $null
}

# Подключение системных сборок для работы с Zip-архивами:
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Глобальная переменная для кэширования списка с GitHub:
$Global:GitHubParsedList = $null

# Перевод:
$LangStrings = @{
	"RU" = @{
		"AccountCleared" = "Готово. Данные аккаунта {0} удалены."
		"AddedToDownloadedList" = "Добавлено в список: {0} - {1}"
		"AddedToPurchasedList" = "Добавлено в список покупок: {0} - {1}"
		"AlreadyInList" = "Уже есть в списке: {0} - {1}"
		"AppsCleared" = "Готово. Приложения в папке Apps удалены."
		"AskAppNumDownload" = "Введите № приложений для загрузки"
		"AskAppNumPurchase" = "Введите № приложений для покупки"
		"AskAppIdDownload" = "Введите ID приложений для загрузки"
		"AskAppIdPurchase" = "Введите ID приложений для покупки"
		"AskAppSearch" = "Введите название приложения для поиска"
		"AskFileNum" = "Введите № файлов для установки"
		"AskVerCount" = "Введите количество версий для отображения"
		"AskVerNum" = "Введите № версий для загрузки"
		"AuthFail" = "Вход в Аккаунт Apple не выполнен."
		"AuthSuccess" = "Вход в Аккаунт Apple выполнен.`nДанные аккаунта:"
		"CancelStep" = "(0: Отмена/Возврат в главное меню):"
		"ClearAccountMenuTitle" = "Выберите аккаунты Apple для очистки"
		"ClearAllAccounts" = "Все аккаунты Apple"
		"ClearMenu1" = "1. Список приобретенных приложений"
		"ClearMenu2" = "2. Список загруженных приложений"
		"ClearMenu3" = "3. Приложения в папке Apps"
		"ClearMenuTitle" = "Выберите данные для очистки"
		"DownloadedListCleared" = "Готово. Список загруженных приложений очищен."
		"DownloadedListMenu1" = "1. Полный список приложений (GitHub)"
		"DownloadedListMenu2" = "2. Список загруженных приложений"
		"DownloadedListMenu3" = "3. Список незагруженных приложений"
		"ErrorDownloadedEmpty" = "Ошибка: История загрузок пуста."
		"ErrorIdeviceinstallerNotFound" = "Ошибка: ideviceinstaller не найден. Установка приложений по USB невозможна (только по AirDrop на macOS)"
		"ErrorInvalidInput" = "Ошибка: Неверный ввод."
		"ErrorListLoadError" = "Ошибка загрузки списка приложений."
		"ErrorMissingFiles" = "Ошибка. Следующие файлы не найдены:"
		"ErrorNoApps" = "Ошибка: В папке Apps отсутствуют приложения."
		"ErrorNoAppsFound" = "Ошибка: Приложения не найдены."
		"ErrorPurchasedEmpty" = "Ошибка: История покупок пуста."
		"ErrorUpdateCheck" = "Ошибка: Не удалось проверить наличие обновлений."
		"FileName" = "Имя файла:"
		"FileSaved" = "Готово. Файл сохранен в папку Apps."
		"HeaderAppID" = "ID приложения:"
		"HeaderAppName" = "Название приложения:"
		"HeaderMinIOS" = "Мин. версия iOS:"
		"HeaderNum" = "№"
		"HeaderVerID" = "ID версии:"
		"HeaderVersion" = "Версия:"
		"InstallApp" = "Установка:"
		"InstallerMenu1" = "1. Проверка минимальной версии iOS для приложений в папке Apps"
		"InstallerMenu2" = "2. Установка приложений из папки Apps"
		"InstallerMenu3" = "3. Поддержка проекта"
		"InstallerMenu4" = "4. Сменить язык (Change Language)"
		"InstallerMenu5" = "5. Перейти в IPA_Downloader"
		"IpatoolVersionMenuTitle" = "Выберите версию ipatool:"
		"LangChanged" = "Язык успешно изменен на русский."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"ListMenuTitle" = "Выберите список для отображения"
		"LoggedOut" = "Выполнен выход из Аккаунта Apple."
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
		"Menu13" = "13. Выход из Аккаунта Apple и сброс настроек"
		"Menu14" = "14. Поддержка проекта"
		"Menu15" = "15. Сменить язык (Change Language)"
		"MenuTitle" = "Введите команду:"
		"MinIOS" = "Минимальная версия iOS:"
		"ModeMenu1" = "1. IPA_Downloader"
		"ModeMenu2" = "2. IPA_Installer"
		"ModeMenuTitle" = "Выберите режим работы:"
		"PurchasedListCleared" = "Готово. Список приобретенных приложений очищен."
		"PurchasedListMenu1" = "1. Полный список приложений (GitHub)"
		"PurchasedListMenu2" = "2. Список приобретенных приложений"
		"PurchasedListMenu3" = "3. Список неприобретенных приложений"
		"SelectedApp" = "Выбрано приложение:"
		"SelectedVer" = "Выбрана версия:"
		"UpdateAvailableTitle" = "Доступно обновление (версия {0}). Перейти на страницу GitHub для загрузки обновления?"
		"UpdateMenu1" = "1. Да"
		"UpdateMenu2" = "2. Нет"
	}
	"EN" = @{
		"AccountCleared" = "Done. Account {0} data cleared."
		"AddedToDownloadedList" = "Added to list: {0} - {1}"
		"AddedToPurchasedList" = "Added to purchased list: {0} - {1}"
		"AlreadyInList" = "Already in list: {0} - {1}"
		"AppsCleared" = "Done. Apps folder has been cleared."
		"AskAppNumDownload" = "Enter # of apps to download"
		"AskAppNumPurchase" = "Enter # of apps to purchase"
		"AskAppIdDownload" = "Enter app IDs to download"
		"AskAppIdPurchase" = "Enter app IDs to purchase"
		"AskAppSearch" = "Enter app name to search"
		"AskFileNum" = "Enter # of files to install"
		"AskVerCount" = "Enter quantity of versions to display"
		"AskVerNum" = "Enter # of versions to download"
		"AuthFail" = "Not authenticated with Apple Account."
		"AuthSuccess" = "Apple Account login successful.`nAccount details:"
		"CancelStep" = "(0: Cancel/Return to main menu):"
		"ClearAccountMenuTitle" = "Select Apple accounts to clear"
		"ClearAllAccounts" = "All Apple accounts"
		"ClearMenu1" = "1. Purchased apps list"
		"ClearMenu2" = "2. Downloaded apps list"
		"ClearMenu3" = "3. Apps in Apps folder"
		"ClearMenuTitle" = "Select data to clear"
		"DownloadedListCleared" = "Done. Downloaded apps list cleared."
		"DownloadedListMenu1" = "1. Full apps list (GitHub)"
		"DownloadedListMenu2" = "2. List of downloaded apps"
		"DownloadedListMenu3" = "3. List of non-downloaded apps"
		"ErrorDownloadedEmpty" = "Error: Download history is empty."
		"ErrorIdeviceinstallerNotFound" = "Error: ideviceinstaller not found. Apps installation via USB is impossible (only via AirDrop on macOS)"
		"ErrorInvalidInput" = "Error: Invalid input."
		"ErrorListLoadError" = "Failed to load apps list."
		"ErrorMissingFiles" = "Error. Following files were not found:"
		"ErrorNoApps" = "Error: No apps found in Apps folder."
		"ErrorNoAppsFound" = "Error: No apps found."
		"ErrorPurchasedEmpty" = "Error: Purchase history is empty."
		"ErrorUpdateCheck" = "Error: Failed to check for updates."
		"FileName" = "File name:"
		"FileSaved" = "Done. File saved to Apps folder."
		"HeaderAppID" = "App ID:"
		"HeaderAppName" = "App Name:"
		"HeaderMinIOS" = "Min. iOS version:"
		"HeaderNum" = "#"
		"HeaderVerID" = "Version ID:"
		"HeaderVersion" = "Version:"
		"InstallApp" = "Installing:"
		"InstallerMenu1" = "1. Check minimum iOS version for apps in Apps folder"
		"InstallerMenu2" = "2. Install apps from Apps folder"
		"InstallerMenu3" = "3. Project support"
		"InstallerMenu4" = "4. Change Language (Сменить язык)"
		"InstallerMenu5" = "5. Switch to IPA_Downloader"
		"IpatoolVersionMenuTitle" = "Select ipatool version:"
		"LangChanged" = "Language successfully changed to English."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"ListMenuTitle" = "Select list to display"
		"LoggedOut" = "Successfully logged out of Apple Account."
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
		"Menu13" = "13. Log out of Apple Account and reset settings"
		"Menu14" = "14. Project support"
		"Menu15" = "15. Change Language (Сменить язык)"
		"MenuTitle" = "Enter a command:"
		"MinIOS" = "Minimum iOS version:"
		"ModeMenu1" = "1. IPA_Downloader"
		"ModeMenu2" = "2. IPA_Installer"
		"ModeMenuTitle" = "Select operating mode:"
		"PurchasedListCleared" = "Done. Purchased apps list cleared."
		"PurchasedListMenu1" = "1. Full apps list (GitHub)"
		"PurchasedListMenu2" = "2. List of purchased apps"
		"PurchasedListMenu3" = "3. List of non-purchased apps"
		"SelectedApp" = "Selected app:"
		"SelectedVer" = "Selected version:"
		"UpdateAvailableTitle" = "Update available (version {0}). Open GitHub page to download the update?"
		"UpdateMenu1" = "1. Yes"
		"UpdateMenu2" = "2. No"
	}
}

# Функция разделителя:
function Separator {
	Write-Host "====================================================================" -ForegroundColor Green
}

# Функция вывода данных в виде таблицы:
function Out-Table {
	param (
		[Parameter(Mandatory = $true)][array]$Data,
		[Parameter(Mandatory = $true)][string[]]$Headers,
		[Parameter(Mandatory = $true)][string[]]$Properties
	)
	
	if (-not $Data -or $Data.Count -eq 0) { return }
	
	$reANSI = [regex]'\x1b\[[0-9;]*[a-zA-Z]'
	$reSpaces = [regex]'[\u00A0\u2000-\u200A\u202F\u205F\u3000]'
	$reDashes = [regex]'[\u2010-\u2015]'
	$reHidden = [regex]'[\u200B-\u200F\u202A-\u202E\u2060\uFEFF\u00AD\p{Cc}\p{Cf}]'
	$reWide = [regex]'[\u1100-\u115F\u2E80-\uA4CF\uAC00-\uD7A3\uF900-\uFAFF\uFF01-\uFF60]'
	
	# Очистка и измерение ячеек:
	function Get-CellInfo([string]$text) {
		if ([string]::IsNullOrEmpty($text)) { return @{ Text = ""; Width = 0 } }
		
		# Замена текста для корректного отображения:
		$s = $reANSI.Replace($text, '')
		$s = $reSpaces.Replace($s, ' ')
		$s = $reDashes.Replace($s, '-')
		$s = $reHidden.Replace($s, '')
		$s = $s.Normalize([System.Text.NormalizationForm]::FormC)
		
		# Расчет ширины:
		$visualWidth = $s.Length + $reWide.Matches($s).Count
		return @{ Text = $s; Width = $visualWidth }
	}
	
	# Обработка заголовков таблицы:
	$CleanHeaders = foreach ($h in $Headers) { Get-CellInfo $h }
	$ColWidths = $CleanHeaders | ForEach-Object { $_.Width }
	
	# Обработка данных:
	$CleanRows = @()
	foreach ($Row in $Data) {
		$cells = @()
		for ($i = 0; $i -lt $Properties.Count; $i++) {
			$cellInfo = Get-CellInfo "$($Row.($Properties[$i]))"
			
			# Обновление ширины колонки:
			if ($cellInfo.Width -gt $ColWidths[$i]) {
				$ColWidths[$i] = $cellInfo.Width
			}
			$cells += $cellInfo
		}
		# Добавляем массив ячеек как единый элемент:
		$CleanRows += , $cells 
	}
	
	# Формирование элементов рамок:
	$TopParts = @(); $SepParts = @(); $BottomParts = @()
	foreach ($w in $ColWidths) {
		$line = "─" * ($w + 2)
		$TopParts += $line; $SepParts += $line; $BottomParts += $line
	}
	
	$LineTop = "┌" + ($TopParts -join "┬") + "┐"
	$LineSep = "├" + ($SepParts -join "┼") + "┤"
	$LineBottom = "└" + ($BottomParts -join "┴") + "┘"
	
	# Сборка готовой строки:
	function Build-Row($cellsInfo) {
		$formatted = for ($i = 0; $i -lt $cellsInfo.Count; $i++) {
			$cell = $cellsInfo[$i]
			$padCount = [Math]::Max(0, $ColWidths[$i] - $cell.Width)
			" " + $cell.Text + (" " * $padCount) + " "
		}
		return "│" + ($formatted -join "│") + "│"
	}
	
	# Итоговый вывод:
	Write-Host $LineTop
	Write-Host (Build-Row $CleanHeaders)
	Write-Host $LineSep
	
	for ($r = 0; $r -lt $CleanRows.Count; $r++) {
		Write-Host (Build-Row $CleanRows[$r])
	}
	
	Write-Host $LineBottom
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

# Глобальная переменная для хранения текущего Аккаунта Apple:
$Global:CurrentAppleAccount = "UnknownAccount"

# Функция получения текущего Аккаунта Apple:
function Get-Current-AppleAccount {
	$AuthInfo = & "$ipatoolFilePath" auth info 2>&1 | Out-String
	if ($AuthInfo -match 'email=([^\s]+)') {
		# Извлекаем почту и очищаем её от консольных ANSI-кодов цвета:
		$Global:CurrentAppleAccount = $Matches[1].Trim() -replace '\x1b\[[0-9;]*[a-zA-Z]', ''
	} else {
		$Global:CurrentAppleAccount = "UnknownAccount"
	}
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

# Функция чтения JSON-файла списка приложений с учетом аккаунта:
function Read-AppList-Json {
	param ([string]$FilePath, [string]$EmptyError)
	if (!(Test-Path $FilePath)) {
		Show-Error $EmptyError
		return $null
	}
	$JsonRaw = Get-Content $FilePath -Raw -Encoding UTF8
	if ([string]::IsNullOrWhiteSpace($JsonRaw) -or $JsonRaw -eq '{}') {
		Show-Error $EmptyError
		return $null
	}
	$Data = $JsonRaw | ConvertFrom-Json
	if ($null -eq $Data) {
		Show-Error $EmptyError
		return $null
	}
	
	# Поддержка старого формата:
	if ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [System.Management.Automation.PSCustomObject]) {
		return $Data
	}
	
	# Получение данных конкретного аккаунта:
	if ($Data.psobject.properties.match($Global:CurrentAppleAccount).Count -gt 0) {
		$AccountApps = $Data."$Global:CurrentAppleAccount"
		if ($AccountApps -isnot [System.Collections.IEnumerable]) { $AccountApps = @($AccountApps) }
		if ($AccountApps.Count -eq 0) {
			Show-Error $EmptyError
			return $null
		}
		return $AccountApps
	} else {
		Show-Error $EmptyError
		return $null
	}
}

# Функция входа в Аккаунт Apple:
function Connect-AppleAccount {
	
	while (!(Test-Path "$AccountFilePath")) {
		Remove-Item "$CookiesFilePath" -Force -ErrorAction SilentlyContinue
		Separator
		Write-Host (Get-Lang "AuthFail")

		if ($IpatoolVersion -eq "ipatool-cpp") {
			& "$ipatoolFilePath" auth login
		} elseif ($IpatoolVersion -eq "ipatool-go") {
			$AppleAccount = Read-Host "Enter email"
			& "$ipatoolFilePath" auth login --email $AppleAccount
			
			# Создаем пустой файл account только если авторизация прошла успешно (код 0)
			if ($LASTEXITCODE -eq 0) {
				New-Item -Path "$ipatoolHomePath/account" -ItemType File -Force | Out-Null
			}
		}
	}
	Get-Current-AppleAccount
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
			$Stream = $null
			try {
				$Stream = $PlistEntry.Open()
				$Reader = New-Object System.IO.StreamReader($Stream, [System.Text.Encoding]::UTF8)
				$Content = $Reader.ReadToEnd()
			} finally {
				if ($null -ne $Reader) { $Reader.Dispose() }
				if ($null -ne $Stream) { $Stream.Dispose() }
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

# Функция сохранения списков с привязкой к аккаунту и сортировкой:
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
	
	# Создание файла, если его нет:
	if (!(Test-Path $HistoryFile)) {
		$null = New-Item -Path $HistoryFile -ItemType "File" -Value '{}'
	}
	
	$JsonRaw = Get-Content $HistoryFile -Raw -Encoding UTF8
	if ([string]::IsNullOrWhiteSpace($JsonRaw)) { $JsonRaw = '{}' }
	
	$Data = $JsonRaw | ConvertFrom-Json
	if ($null -eq $Data) {
		$Data = New-Object PSCustomObject
	}
	
	# Конвертация старого формата в новый:
	if ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [System.Management.Automation.PSCustomObject]) {
		$OldArray = $Data
		$Data = New-Object PSCustomObject
		$Data | Add-Member -MemberType NoteProperty -Name "UnknownAccount" -Value $OldArray
	}
	
	# Получение списка приложений для текущего аккаунта:
	$AccountApps = @()
	if ($Data.psobject.properties.match($Global:CurrentAppleAccount).Count -gt 0) {
		$AccountApps = $Data."$Global:CurrentAppleAccount"
	} else {
		$Data | Add-Member -MemberType NoteProperty -Name $Global:CurrentAppleAccount -Value @()
	}
	
	if ($AccountApps -isnot [System.Collections.IEnumerable]) { $AccountApps = @($AccountApps) }
	
	# Загрузка списка:
	Initialize-GitHub-List
	
	# Создание хэш-таблицы для поиска актуальных имен и индексов:
	$ReferenceMap = @{}
	for ($i = 0; $i -lt $Global:GitHubParsedList.Count; $i++) {
		$RefApp = $Global:GitHubParsedList[$i]
		$ReferenceMap[$RefApp.Id] = @{ Index = $i; Name = $RefApp.Name }
	}
	
	$IsDuplicate = $false
	
	# Синхронизация имен сохраненных приложений с Apps_ID_List.txt и поиск дубликатов:
	foreach ($Item in $AccountApps) {
		if ($ReferenceMap.ContainsKey($Item.appid)) {
			$Item.name = $ReferenceMap[$Item.appid].Name
		}
		if ($Item.appid -eq $AppId) {
			$IsDuplicate = $true
		}
	}
	
	# Добавление нового приложения, если это не дубликат:
	if (-not $IsDuplicate) {
		$NewItem = [PSCustomObject]@{ name = $AppNameOnly; appid = $AppId }
		$AccountApps = @($AccountApps) + $NewItem
	}
	
	# Сортировка: 
	$AccountApps = $AccountApps | Sort-Object `
		@{ Expression = { if ($ReferenceMap.ContainsKey($_.appid)) { $ReferenceMap[$_.appid].Index } else { [int]::MaxValue } } }, `
		@{ Expression = { 
			$name = [regex]::Replace("$($_.name)".ToUpper().Replace('Ё','Е'), '\d+', { $args[0].Value.PadLeft(10, '0') })
			[BitConverter]::ToString([Text.Encoding]::BigEndianUnicode.GetBytes($name))
		} }
	
	# Сохранение обновленных данных:
	$Data."$Global:CurrentAppleAccount" = $AccountApps
	$Data | ConvertTo-Json -Depth 5 | Set-Content $HistoryFile -Encoding UTF8
	
	# Вывод сообщений:
	if ($IsDuplicate) {
		$CurrentName = if ($ReferenceMap.ContainsKey($AppId)) { $ReferenceMap[$AppId].Name } else { $AppNameOnly }
		Write-Host ((Get-Lang "AlreadyInList") -f $CurrentName, $AppId)
	} else {
		$MsgKey = if ($Type -eq "Purchased") { "AddedToPurchasedList" } else { "AddedToDownloadedList" }
		Write-Host ((Get-Lang $MsgKey) -f $AppNameOnly, $AppId)
	}
}

# Функция вывода предупреждения:
function Show-WarningMsg {
	$WarnFile = if ($Global:CurrentLang -eq "RU") { $WarningRUPath } else { $WarningENPath }
	if (Test-Path $WarnFile) {
		$WarnText = Get-Content -Path $WarnFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
		if (![string]::IsNullOrWhiteSpace($WarnText)) {
			Separator
			Write-Warning $WarnText
		}
	}
}

# Функция инициализации и кэширования списка с GitHub:
function Initialize-GitHub-List {
	if ($null -ne $Global:GitHubParsedList) { return }
	try {
		# Загрузка файла, если его нет:
		if (!(Test-Path "$AppsIDListPath")) {
			Invoke-RestMethod -Uri "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Files/Apps_ID_List.txt" -OutFile "$AppsIDListPath" -ErrorAction SilentlyContinue
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
	# Создание папки Apps на случай, если она удалена в процессе работы скрипта:
	if (!(Test-Path $AppsFolderPath)) {
		New-Item -Path $AppsFolderPath -ItemType Directory -Force | Out-Null
	}
	
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
				
				# Проверка списка с GitHub, если имя неизвестно или не было передано:
				if ([string]::IsNullOrWhiteSpace($AppName) -or $AppName -eq "Unknown") {
					$GitHubName = Get-GitHub-AppName -AppId $AppId
					if (![string]::IsNullOrWhiteSpace($GitHubName)) {
						$AppName = $GitHubName
					}
				}
				
				# Применение найденного имени, очищенного от недопустимых символов:
				if (![string]::IsNullOrWhiteSpace($AppName) -and $AppName -ne "Unknown") {
					$FinalAppName = $AppName -replace '[\\/:*?"<>|]', ''
				}
				
				# Формирование имени файла и замена всех пробелов на "_":
				$NewName = "$($FinalAppName)_$($Meta.Version)_iOS_$($Meta.MinIOS)+_$($Global:CurrentAppleAccount).ipa" -replace '\s+', '_'
				$TargetFile = Join-Path -Path $AppsFolderPath -ChildPath $NewName
				
				if (Test-Path $TargetFile) {
					Remove-Item $TargetFile -Force -ErrorAction SilentlyContinue
				}
				
				Rename-Item -Path $DestPath -NewName $NewName -Force
				Write-Host "$(Get-Lang 'FileName') $NewName"
				Write-Host "$(Get-Lang 'MinIOS') $($Meta.MinIOS)"
				
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
		
		if ([string]::IsNullOrWhiteSpace($Part)) { 
			continue 
		}
		
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
	
	# Заголовки таблицы:
	$HeaderNum = Get-Lang "HeaderNum"
	$HeaderVerID = Get-Lang "HeaderVerID"
	$HeaderVersion = Get-Lang "HeaderVersion"
	
	# Расчет ширины колонок:
	$W1 = [Math]::Max($HeaderNum.Length, "$($RecentVersions.Count)".Length)
	
	$MaxIdLen = $HeaderVerID.Length
	foreach ($id in $RecentVersions) {
		if ($id.Length -gt $MaxIdLen) { $MaxIdLen = $id.Length }
	}
	
	$W2 = [Math]::Max($HeaderVersion.Length, 15)
	$W3 = $MaxIdLen
	
	$ColWidths = @($W1, $W2, $W3)
	
	# Формирование рамок:
	$TopParts = foreach ($w in $ColWidths) { "─" * ($w + 2) }
	$SepParts = foreach ($w in $ColWidths) { "─" * ($w + 2) }
	$BottomParts = foreach ($w in $ColWidths) { "─" * ($w + 2) }
	$LineTop = "┌" + ($TopParts -join "┬") + "┐"
	$LineSep = "├" + ($SepParts -join "┼") + "┤"
	$LineBottom = "└" + ($BottomParts -join "┴") + "┘"
	
	# Функция быстрой печати строки:
	function Print-StreamRow ([string[]]$cells) {
		$formatted = for ($i = 0; $i -lt $cells.Count; $i++) {
			$text = "$($cells[$i])"
			$pad = [Math]::Max(0, $ColWidths[$i] - $text.Length)
			" " + $text + (" " * $pad) + " "
		}
		Write-Host ("│" + ($formatted -join "│") + "│")
	}
	
	Separator
	# Вывод шапки таблицы:
	Write-Host $LineTop
	Print-StreamRow @($HeaderNum, $HeaderVersion, $HeaderVerID)
	Write-Host $LineSep
	
	# Получение данных с выводом строк:
	$VersionMapping = @()
	$Counter = 1
	
	for ($idx = 0; $idx -lt $RecentVersions.Count; $idx++) {
		$VersionId = $RecentVersions[$idx]
		
		# Запрос к ipatool:
		$Meta = & "$ipatoolFilePath" get-version-metadata -i $AppId --external-version-id $VersionId 2>$null
		$DisplayVersion = if ($Meta -match 'displayVersion=([^\s,]+)') { $Matches[1] } else { "NA" }
		
		$VersionMapping += [PSCustomObject]@{
			Index = $Counter
			ID = $VersionId
			Version = $DisplayVersion
		}
		
		# Печать строки после получения версии:
		Print-StreamRow @("$Counter", "$DisplayVersion", "$VersionId")
		
		$Counter++
	}
	
	# Нижняя граница:
	Write-Host $LineBottom
	Separator
	
	# Выбор версий:
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
	param (
		[string]$PromptKey = 'AskAppNumDownload'
	)
	while ($true) {
		Separator
		$AppName = Read-Host "$(Get-Lang 'AskAppSearch') $(Get-Lang 'CancelStep')`n"
		
		if ($AppName -eq '0') { return $null }
		if (![string]::IsNullOrWhiteSpace($AppName)) { break }
		
		Show-Error "ErrorInvalidInput"
	}
	
	# Инициализация списка из Apps_ID_List.txt:
	Initialize-GitHub-List
	
	# Поиск в списке приложений:
	$FoundApps = @()
	if ($null -ne $Global:GitHubParsedList) {
		$FoundApps += @($Global:GitHubParsedList | Where-Object { $_.Name -match [regex]::Escape($AppName) } | ForEach-Object {
			[PSCustomObject]@{
				name = $_.Name
				id = $_.Id
			}
		})
	}
	
	# Поиск в App Store:
	$SearchOutput = & "$ipatoolFilePath" search $AppName --limit 10 *>&1 | Out-String
	if ($SearchOutput -match 'apps=(\[.*?\])') {
		$JsonString = $Matches[1]
		if ($JsonString -ne '[]') {
			$ParsedApps = $JsonString | ConvertFrom-Json
			foreach ($Item in $ParsedApps) {
				$FoundApps += $Item
			}
		}
	}
	
	# Проверка на пустой результат:
	if ($FoundApps.Count -eq 0) {
		Show-Error "ErrorNoAppsFound"
		return $null
	}
	
	# Вывод результатов:
	Separator
	$Counter = 1
	$TableData = foreach ($App in $FoundApps) {
		[PSCustomObject]@{
			Num = $Counter++
			Name = $App.Name
			ID = $App.Id
		}
	}
	
	Out-Table -Data $TableData `
		-Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID") `
		-Properties "Num", "Name", "ID"
	Separator
	
	# Выбор приложений:
	$Indices = Read-NumberSelection -PromptKey $PromptKey -MaxCount $FoundApps.Count
	if ($null -eq $Indices) { return $null }
	
	$SelectedApps = @()
	foreach ($Idx in $Indices) {
		$SelectedApps += $FoundApps[$Idx - 1]
	}
	return $SelectedApps
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
	$EmptyError = if ($ListMode -eq "Purchase") { "ErrorPurchasedEmpty" } else { "ErrorDownloadedEmpty" }
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
				$Lines += "{0}: {1}" -f $Item.Name, $Item.Appid
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
					$SavedIds = $HistoryData.Appid
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
	
	# Парсинг данных для таблицы:
	$TableData = @()
	for ($I = 0; $I -lt $Lines.Count; $I++) {
		$SelectedLine = $Lines[$I]
		$AppId = [System.Text.RegularExpressions.Regex]::Match($SelectedLine, '\b\d{6,}\b').Value
		$AppName = "Unknown"
		if ($SelectedLine -match '^(.+?):\s*\d') {
			$AppName = $Matches[1].Trim()
		}
		
		$TableData += [PSCustomObject]@{
			Num = $I + 1
			Name = $AppName
			ID = $AppId
		}
	}
	
	Separator
	Out-Table -Data $TableData `
		-Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID") `
		-Properties "Num", "Name", "ID"
	Separator
	
	$PromptKey = if ($ListMode -eq "Purchase") { 'AskAppNumPurchase' } else { 'AskAppNumDownload' }
	$SelectedIndices = Read-NumberSelection -PromptKey $PromptKey -MaxCount $Lines.Count
	if ($null -eq $SelectedIndices) { return $null }
	
	$SelectedApps = @()
	foreach ($Idx in $SelectedIndices) {
		$SelectedObject = $TableData[$Idx - 1]
		if (![string]::IsNullOrEmpty($SelectedObject.ID)) {
			$SelectedApps += [PSCustomObject]@{
				Id = $SelectedObject.ID
				Name = $SelectedObject.Name
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
	$Counter = 1
	$TableData = @()
	
	foreach ($File in @($FilesToProcess)) { 
		$Meta = Get-IPA-Metadata -IpaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)" } else { "Error" }
		
		$TableData += [PSCustomObject]@{
			Num = $Counter
			Name = $File.Name
			MinOs = $MinOs
		}
		$Counter++
	}
	
	Out-Table -Data @($TableData) `
		-Headers (Get-Lang "HeaderNum"), (Get-Lang "FileName"), (Get-Lang "HeaderMinIOS") `
		-Properties "Num", "Name", "MinOs"
		
	return @($FilesToProcess)
}

# Функция вывода ошибки об отсутствии необходимых файлов:
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
	param ([string]$NewFolder)
	
	$PathSeparator = if ($IsWin) { ';' } else { ':' }
	$PathEntries = $env:Path -split [regex]::Escape($PathSeparator)
	
	# Добавляем папку, только если её ещё нет в PATH:
	if ($NewFolder -notin $PathEntries) {
		$env:Path = $env:Path + $PathSeparator + $NewFolder
	}
}

# Функция установки путей к ipatool/ideviceinstaller и применения PATH/прав запуска:
function Set-IpatoolBinaryPaths {
	param ([string]$FolderPath)
	
	if ($IsWin) {
		$script:ipatoolFilePath = Join-Path -Path $FolderPath -ChildPath "ipatool.exe"
		$script:ideviceinstallerFilePath = Join-Path -Path $FolderPath -ChildPath "ideviceinstaller.exe"
		
		# Добавление папки с ipatool в PATH текущего процесса:
		Update-PathFolder -NewFolder $FolderPath
	} else {
		$script:ipatoolFilePath = Join-Path -Path $FolderPath -ChildPath "ipatool"
		
		# Снятие карантина (macOS) и выдача прав на запуск:
		if ($IsMac) {
			xattr -cr "$FolderPath" 2>$null
		}
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
	param ([ValidateSet("ipatool-cpp", "ipatool-go")][string]$Version)
	
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
	
	Set-IpatoolBinaryPaths -FolderPath $script:BinaryFolderPath
	
	return $true
}

# Функция запроса версии ipatool с проверкой наличия файлов:
function Invoke-IpatoolVersionPrompt {
	$IpatoolCppLabel = "$(Get-ArchSubFolder -Version 'ipatool-cpp')"
	$IpatoolGoLabel = "$(Get-ArchSubFolder -Version 'ipatool-go')"
	
	while ($true) {
		Separator
		$Version_Menu = @"
$(Get-Lang 'IpatoolVersionMenuTitle')
1. $IpatoolCppLabel
2. $IpatoolGoLabel`n
"@
		$VersionChoice = Read-MenuChoice -MenuText $Version_Menu -OptionsCount 2
		$SelectedVersion = if ($VersionChoice -eq '2') { 'ipatool-go' } else { 'ipatool-cpp' }
		
		if (Set-IpatoolVersion -Version $SelectedVersion) {
			return
		}
	}
}

# Функция установки приложений из папки Apps:
function Invoke-InstallApps {
	if ([string]::IsNullOrWhiteSpace($script:ideviceinstallerFilePath)) {
		Show-Error "ErrorIdeviceinstallerNotFound"
		return
	}
	
	$IpaFiles = Get-iOS-MinVersion
	if ($null -ne $IpaFiles) {
		Separator
		$SelectedIndices = Read-NumberSelection -PromptKey 'AskFileNum' -MaxCount $IpaFiles.Count
		if ($null -eq $SelectedIndices) { return }
		
		foreach ($Idx in $SelectedIndices) {
			$SelectedFile = $IpaFiles[$Idx - 1]
			Separator
			Write-Host "$(Get-Lang 'InstallApp') $($SelectedFile.Name)"
			$TempFile = "$TempIpaFilePath"
			Copy-Item -Path $SelectedFile.FullName -Destination $TempFile -Force
			try {
				& "$ideviceinstallerFilePath" install $TempFile
			} finally {
				Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
			}
		}
	}
}

# Функция проверки обновлений:
function Check-Update {
	try {
		$repoUrl = "https://api.github.com/repos/kda2495/IPA_Downloader/releases/latest"
		$latestRelease = Invoke-RestMethod -Uri $repoUrl -UseBasicParsing -ErrorAction SilentlyContinue
		
		if ($latestRelease -and $latestRelease.tag_name) {
			
			# Извлечение числа из версии:
			$latestVerStr = [regex]::Match($latestRelease.tag_name, '\d+(\.\d+)+').Value
			$currentVerStr = [regex]::Match($ScriptVersion, '\d+(\.\d+)+').Value
			
			# Проверяем, есть ли текстовые приписки после версии:
			$latestHasSuffix = ($latestRelease.tag_name -replace '\d+(\.\d+)+', '').Trim().Length -gt 0
			$currentHasSuffix = ($ScriptVersion -replace '\d+(\.\d+)+', '').Trim().Length -gt 0
			
			$UpdateFound = $false

			# Проверка, что обе переменные не пустые, чтобы избежать ошибок конвертации:
			if (![string]::IsNullOrEmpty($latestVerStr) -and ![string]::IsNullOrEmpty($currentVerStr)) {
				
				# 1. Если числовая версия на GitHub больше:
				if ([version]$latestVerStr -gt [version]$currentVerStr) {
					$UpdateFound = $true
				} 
				# 2. Если числовые версии равны, но у текущей версии есть приписка, а на GitHub чистая версия:
				elseif (([version]$latestVerStr -eq [version]$currentVerStr) -and $currentHasSuffix -and -not $latestHasSuffix) {
					$UpdateFound = $true
				}
			}

			if ($UpdateFound) {
				Separator
				$UpdateMenuText = @"
$((Get-Lang 'UpdateAvailableTitle') -f $latestRelease.tag_name)
$(Get-Lang 'UpdateMenu1')
$(Get-Lang 'UpdateMenu2')`n
"@
				$Choice = Read-MenuChoice -MenuText $UpdateMenuText -OptionsCount 2
				if ($Choice -eq '1') {
					Start-Process "https://github.com/kda2495/IPA_Downloader/releases"
					exit
				}
			}
		}
	} catch {
		Separator
		Write-Host (Get-Lang 'ErrorUpdateCheck') -ForegroundColor DarkRed
	}
}

# Функция вывода баннера с текущим режимом работы, версией скрипта и системой/архитектурой:
function Show-ModeBanner {
	$ModeLabel = if ($Global:WorkMode -eq "Installer") { "IPA_Installer" } else { "IPA_Downloader" }
	Separator
	Write-Host "$ModeLabel $ScriptVersion ($ArchSubFolder)"
}

# Функция первоначальной настройки (язык):
function Invoke-SetupWizard {
	# Удаление содержимого папки .ipatool:
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
	
	# Проверка обновлений:
	if (-not $Global:UpdateChecked) {
		Check-Update
		$Global:UpdateChecked = $true
	}
	
	# Установка режима IPA_Installer по умолчанию:
	$Global:WorkMode = "Installer"
	Set-Setting -Key "Mode" -Value $Global:WorkMode
	Set-Setting -Key "Language" -Value $Global:CurrentLang
	
	Show-ModeBanner
	Show-WarningMsg
}

# Операционная система:
Separator
Write-Host "$OSVersion"

# Версия PowerShell:
Write-Host "PowerShell $PSVersion"

# Проверка на наличие базовых папок:
foreach ($Dir in @("$AppsFolderPath", "$FilesFolderPath", "$MainAppFolderPath", "$ipatoolHomePath")) {
	if (!(Test-Path $Dir)) {
		$null = New-Item -Path $Dir -ItemType "Directory"
	}
}

# Удаление временных файлов при запуске:
Get-ChildItem -Path $PSScriptRoot -Filter "*.ipa.tmp" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
if (Test-Path $AppsIDTempListPath) { Remove-Item $AppsIDTempListPath -Force -ErrorAction SilentlyContinue }

# Включение TLS 1.2 для совместимости со старыми версиями Windows:
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Асинхронное фоновое обновление списка приложений и предупреждений с GitHub:
$BackgroundDownload = {
	param($ListUrl, $ListFinal, $ListTemp, $WarnRuUrl, $WarnRuFinal, $WarnRuTemp, $WarnEnUrl, $WarnEnFinal, $WarnEnTemp)
	try {
		[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
		
		# Функция скачивания и перемещения:
		function Download-And-Move($Url, $Temp, $Final, $MinSize) {
			Invoke-RestMethod -Uri $Url -OutFile $Temp -ErrorAction SilentlyContinue
			if (Test-Path $Temp) {
				if ((Get-Item $Temp).Length -gt $MinSize) {
					Move-Item -Path $Temp -Destination $Final -Force
				} else {
					Remove-Item $Temp -Force
				}
			}
		}

		# Скачиваем файлы:
		Download-And-Move -Url $ListUrl -Temp $ListTemp -Final $ListFinal -MinSize 10
		Download-And-Move -Url $WarnRuUrl -Temp $WarnRuTemp -Final $WarnRuFinal -MinSize 5
		Download-And-Move -Url $WarnEnUrl -Temp $WarnEnTemp -Final $WarnEnFinal -MinSize 5
	} catch {
	}
}

$Runspace = [runspacefactory]::CreateRunspace()
$Runspace.Open()
$PSInstance = [powershell]::Create().AddScript($BackgroundDownload).AddArgument("https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Files/Apps_ID_List.txt").AddArgument($AppsIDListPath).AddArgument($AppsIDTempListPath).AddArgument("https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Files/Warning_RU.txt").AddArgument($WarningRUPath).AddArgument($WarningRUTempPath).AddArgument("https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Files/Warning_EN.txt").AddArgument($WarningENPath).AddArgument($WarningENTempPath)
$PSInstance.Runspace = $Runspace
$null = $PSInstance.BeginInvoke()

# Очистка ресурсов после завершения фонового потока:
Register-ObjectEvent -InputObject $PSInstance -EventName InvocationStateChanged -Action {
	if ($Event.Sender.InvocationStateInfo.State -in 'Completed', 'Failed', 'Stopped') {
		$Event.Sender.Dispose()
		$Event.Sender.Runspace.Dispose()
	}
} | Out-Null

# Функция режима IPA_Downloader:
function Invoke-DownloaderMode {
	# Проверка осуществленного входа с Аккаунтом Apple:
	if (Test-Path "$AccountFilePath") {
		Separator
		Write-Host (Get-Lang "AuthSuccess")
		& "$ipatoolFilePath" auth info
		Get-Current-AppleAccount
	}
	
	# Вход с Аккаунтом Apple:
	Connect-AppleAccount
	
	# Сохранение настроек режима IPA_Downloader только после успешной авторизации с Аккаунтом Apple:
	Set-Setting -Key "Mode" -Value "Downloader"
	Set-Setting -Key "IpatoolVersion" -Value $script:IpatoolVersion
	Set-Setting -Key "Language" -Value $Global:CurrentLang
	
	# Основной цикл:
	while (Test-Path "$AccountFilePath") {
	
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
				$AppsToProcess = Search-Apps-Menu -PromptKey 'AskAppNumPurchase'
				if ($null -ne $AppsToProcess) {
					foreach ($App in $AppsToProcess) {
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Purchase"
					}
				}
			}
			
			# 2. Поиск приложения и загрузка последней версии:
			"2" {
				$AppsToProcess = Search-Apps-Menu -PromptKey 'AskAppNumDownload'
				if ($null -ne $AppsToProcess) {
					foreach ($App in $AppsToProcess) {
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Download"
					}
				}
			}
			
			# 3. Поиск приложения и загрузка (с выбором версии):
			"3" {
				$AppsToProcess = Search-Apps-Menu -PromptKey 'AskAppNumDownload'
				if ($null -ne $AppsToProcess) {
					foreach ($App in $AppsToProcess) {
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "DownloadVersion"
					}
				}
			}
			
			# 4. Ввод ID приложений и покупка (без загрузки):
			"4" {
				$AppIds = Get-Multiple-AppIds -PromptKey 'AskAppIdPurchase'
				if ($null -ne $AppIds) {
					foreach ($Id in $AppIds) {
						$AppNames = Resolve-AppDisplayName -AppId $Id
						Invoke-AppAction -AppId $Id -AppName $AppNames.Final -DisplayName $AppNames.Display -Action "Purchase"
					}
				}
			}
			
			# 5. Ввод ID приложений и загрузка последней версии:
			"5" {
				$AppIds = Get-Multiple-AppIds -PromptKey 'AskAppIdDownload'
				if ($null -ne $AppIds) {
					foreach ($Id in $AppIds) {
						$AppNames = Resolve-AppDisplayName -AppId $Id
						Invoke-AppAction -AppId $Id -AppName $AppNames.Final -DisplayName $AppNames.Display -Action "Download"
					}
				}
			}
			
			# 6. Ввод ID приложений и загрузка (с выбором версии):
			"6" {
				$AppIds = Get-Multiple-AppIds -PromptKey 'AskAppIdDownload'
				if ($null -ne $AppIds) {
					foreach ($Id in $AppIds) {
						$AppNames = Resolve-AppDisplayName -AppId $Id
						Invoke-AppAction -AppId $Id -AppName $AppNames.Final -DisplayName $AppNames.Display -Action "DownloadVersion"
					}
				}
			}
			
			# 7. Вывод списка приложений и покупка (без загрузки):
			"7" {
				Separator
				$SelectedApps = Get-Apps-From-List -ListMode "Purchase"
				if ($null -ne $SelectedApps) {
					foreach ($App in $SelectedApps) {
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Purchase"
					}
				}
			}
			
			# 8. Вывод списка приложений и загрузка последней версии:
			"8" {
				Separator
				$SelectedApps = Get-Apps-From-List -ListMode "Download"
				if ($null -ne $SelectedApps) {
					foreach ($App in $SelectedApps) {
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Download"
					}
				}
			}
			
			# 9. Вывод списка приложений и загрузка (с выбором версии):
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
						if (!(Test-Path "$PurchasedIDsFilePath")) {
							Separator
							Write-Host (Get-Lang "ErrorPurchasedEmpty") -ForegroundColor DarkRed
						} else {
							$RawData = Get-Content "$PurchasedIDsFilePath" -Raw -Encoding UTF8
							
							# Если файл пуст или содержит только пустые скобки {}:
							if ([string]::IsNullOrWhiteSpace($RawData) -or $RawData.Trim() -eq '{}') {
								Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "ErrorPurchasedEmpty") -ForegroundColor DarkRed
								continue
							}
							
							$Data = $RawData | ConvertFrom-Json
							
							# Если старый формат или нет свойств:
							if ($Data -isnot [System.Management.Automation.PSCustomObject] -or $Data.psobject.properties.Count -eq 0) {
								Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "PurchasedListCleared")
								continue
							}
							
							# Формируем динамическое меню аккаунтов:
							$Accounts = @($Data.psobject.properties.Name)
							$AccMenuText = "$(Get-Lang 'ClearAccountMenuTitle') $(Get-Lang 'CancelStep')`n"
							$Counter = 1
							foreach ($Acc in $Accounts) {
								$AccMenuText += "$Counter. $Acc`n"
								$Counter++
							}
							$AccMenuText += "$Counter. $(Get-Lang 'ClearAllAccounts')`n"
							
							Separator
							$AccChoice = Read-MenuChoice -MenuText $AccMenuText -OptionsCount $Counter -AllowCancel
							if ($AccChoice -eq '0') { continue }
							
							if ([int]$AccChoice -eq $Counter) {
								# Если выбрано "Все аккаунты":
								Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "PurchasedListCleared")
							} else {
								# Удаляем данные выбранного аккаунта:
								$SelectedAcc = $Accounts[[int]$AccChoice - 1]
								
								# Если в файле отсутствуют аккаунты, то удаляем файл:
								if ($Accounts.Count -le 1) {
									Remove-Item "$PurchasedIDsFilePath" -Force -ErrorAction SilentlyContinue
								} else {
									$Data.psobject.properties.Remove($SelectedAcc)
									$Data | ConvertTo-Json -Depth 5 | Set-Content "$PurchasedIDsFilePath" -Encoding UTF8
								}
								Separator
								Write-Host ((Get-Lang "AccountCleared") -f $SelectedAcc)
							}
						}
					}
					
					"2" {
						if (!(Test-Path "$DownloadedIDsFilePath")) {
							Separator
							Write-Host (Get-Lang "ErrorDownloadedEmpty") -ForegroundColor DarkRed
						} else {
							$RawData = Get-Content "$DownloadedIDsFilePath" -Raw -Encoding UTF8
							
							if ([string]::IsNullOrWhiteSpace($RawData) -or $RawData.Trim() -eq '{}') {
								Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "ErrorDownloadedEmpty") -ForegroundColor DarkRed
								continue
							}
							
							$Data = $RawData | ConvertFrom-Json
							
							if ($Data -isnot [System.Management.Automation.PSCustomObject] -or $Data.psobject.properties.Count -eq 0) {
								Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "DownloadedListCleared")
								continue
							}
							
							$Accounts = @($Data.psobject.properties.Name)
							$AccMenuText = "$(Get-Lang 'ClearAccountMenuTitle') $(Get-Lang 'CancelStep')`n"
							$Counter = 1
							foreach ($Acc in $Accounts) {
								$AccMenuText += "$Counter. $Acc`n"
								$Counter++
							}
							$AccMenuText += "$Counter. $(Get-Lang 'ClearAllAccounts')`n"
							
							Separator
							$AccChoice = Read-MenuChoice -MenuText $AccMenuText -OptionsCount $Counter -AllowCancel
							if ($AccChoice -eq '0') { continue }
							
							if ([int]$AccChoice -eq $Counter) {
								# Если выбрано "Все аккаунты":
								Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "DownloadedListCleared")
							} else {
								# Удаляем данные выбранного аккаунта:
								$SelectedAcc = $Accounts[[int]$AccChoice - 1]
								
								# Если в файле отсутствуют аккаунты, то удаляем файл:
								if ($Accounts.Count -le 1) {
									Remove-Item "$DownloadedIDsFilePath" -Force -ErrorAction SilentlyContinue
								} else {
									$Data.psobject.properties.Remove($SelectedAcc)
									$Data | ConvertTo-Json -Depth 5 | Set-Content "$DownloadedIDsFilePath" -Encoding UTF8
								}
								Separator
								Write-Host ((Get-Lang "AccountCleared") -f $SelectedAcc)
							}
						}
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
			
			# 13. Выход из Аккаунта Apple и сброс настроек:
			"13" {
				Separator
				Write-Host (Get-Lang "LoggedOut")
				& "$ipatoolFilePath" auth revoke
				
				Remove-Item -Path $SettingsFilePath -Force -ErrorAction SilentlyContinue
				$Global:WorkMode = $null
				return
			}
			
			# 14. Поддержка проекта:
			"14" {
				Start-Process "https://github.com/kda2495/IPA_Downloader#поддержка-проекта"
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
			
			# 3. Поддержка проекта:
			"3" {
				Start-Process "https://github.com/kda2495/IPA_Downloader#поддержка-проекта"
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
$Global:UpdateChecked = $false

while ($true) {
	
	# Если режим работы не выбран, то запускаем мастер первоначальной настройки, иначе показываем баннер:
	if ($null -eq $Global:WorkMode) {
		Invoke-SetupWizard
	} else {
		if (-not $Global:UpdateChecked) {
			Check-Update
			$Global:UpdateChecked = $true
		}
		
		Show-ModeBanner
		Show-WarningMsg
	}
	
	# Проверка наличия необходимых файлов:
	if ($IsWin) {
		# Windows: поиск ideviceinstaller.exe и ipatool.exe в локальной папке:
		$MissingMainAppFiles = Get-MissingBinaryFiles -FolderPath $BinaryFolderPath
		Confirm-RequiredFiles -MissingFiles $MissingMainAppFiles
		
		Set-IpatoolBinaryPaths -FolderPath $BinaryFolderPath
		
	} else {
		# macOS и Linux: поиск ideviceinstaller в системном PATH:
		$ideviceinstallerFilePath = (Get-Command ideviceinstaller -ErrorAction SilentlyContinue).Source
		if (-not $ideviceinstallerFilePath) {
			Write-Host (Get-Lang "ErrorIdeviceinstallerNotFound") -ForegroundColor DarkRed
		}
		
		# Финальная проверка файлов:
		$MissingUnixFiles = Get-MissingBinaryFiles -FolderPath $BinaryFolderPath
		Confirm-RequiredFiles -MissingFiles $MissingUnixFiles
		Set-IpatoolBinaryPaths -FolderPath $BinaryFolderPath
	}
	
	if ($Global:WorkMode -eq "Installer") {
		Invoke-InstallerMode
	} else {
		Invoke-DownloaderMode
	}
}