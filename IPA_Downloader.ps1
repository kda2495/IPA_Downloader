# Переключение рабочей директории в папку со скриптом:
Set-Location -Path $PSScriptRoot

# Версия скрипта:
$ScriptVersion = "4.1.1"

# Определение операционной системы:
$IsWin = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
$IsMac = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)

# Определение папок MainApp, Files и файла настроек:
$MainAppFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "MainApp"
$FilesFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Files"
$SettingsFilePath = Join-Path -Path $FilesFolderPath -ChildPath "Settings.txt"

# Функция чтения настроек из Files/Settings.txt:
function Get-Settings {
	$Settings = [ordered]@{}
	
	if (Test-Path $SettingsFilePath) {
		Get-Content $SettingsFilePath -ErrorAction SilentlyContinue | ForEach-Object {
			if ($_ -match '^\s*([^=]+?)\s*=\s*(.*)$') {
				$Settings[$Matches[1]] = $Matches[2].Trim()
			}
		}
	}

	return $Settings
}

# Функция сохранения настроек в Files/Settings.txt:
function Set-Setting {
	param (
		[string]$Key,
		[string]$Value
	)
	
	$Settings = Get-Settings
	$Settings[$Key] = $Value
	
	$Lines = foreach ($K in $Settings.Keys) {
		"$K=$($Settings[$K])"
	}
	
	Set-Content -Path $SettingsFilePath -Value $Lines -Force
}

# Загрузка сохраненных настроек (Files/Settings.txt) или значений по умолчанию:
$SavedSettings = Get-Settings
$script:CurrentLang = if ($SavedSettings['Language'] -match '^(RU|EN)$') { $SavedSettings['Language'] } else { "RU" }
$script:WorkMode = if ($SavedSettings['Mode'] -in @('Downloader', 'Installer')) { $SavedSettings['Mode'] } else { $null }
$script:IsDebugEnabled = if ($SavedSettings['DebugEnabled'] -eq 'True') { $true } else { $false }

# Определение архитектуры macOS и Linux:
if (-not $IsWin) {
	$script:Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
}

# Функция вычисления папки с ipatool под текущую операционную систему и архитектуру:
function Get-ArchSubFolder {
	if ($IsWin) {
		return "windows_amd64"
	} elseif ($IsMac) {
		if ($script:Arch -eq "arm64") {
			return "macOS_arm64"
		} else {
			return "macOS_amd64"
		}
	} else {
		return "linux_amd64"
	}
}

# Определение папки с ipatool под текущую систему и архитектуру:
$script:ArchSubFolder = Get-ArchSubFolder

# Определение основных папок и переменных:
$OSVersion = [System.Environment]::OSVersion
$PSVersion = $PSVersionTable.PSVersion.ToString()
$script:BinaryFolderPath = Join-Path -Path $MainAppFolderPath -ChildPath $script:ArchSubFolder
$DownloadedAppsListFilePath = Join-Path -Path $FilesFolderPath -ChildPath "DownloadedAppsList.json"
$PurchasedAppsListFilePath = Join-Path -Path $FilesFolderPath -ChildPath "PurchasedAppsList.json"
$AppsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Apps"
$ipatoolHomePath = Join-Path -Path $HOME -ChildPath ".ipatool"
$LoginFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "login"
$AccountFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "account"
$AuthFileNames = @("account", "cookies", "login")
$TempFolderPath = [System.IO.Path]::GetTempPath()
$TempIpaFilePath = Join-Path -Path $TempFolderPath -ChildPath "Temp.ipa"
$AppsListPath = Join-Path -Path $FilesFolderPath -ChildPath "AppsList.txt"
$AppsListCustomPath = Join-Path -Path $FilesFolderPath -ChildPath "AppsListCustom.txt"
$AppsListTempPath = Join-Path -Path $MainAppFolderPath -ChildPath "AppsList_tmp.txt"
$WarningPath = Join-Path -Path $FilesFolderPath -ChildPath "Warning.txt"
$WarningTempPath = Join-Path -Path $MainAppFolderPath -ChildPath "Warning_tmp.txt"

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

# Подключение системных сборок для работы с zip-архивами:
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Определение переменной для кэширования основного списка приложений (Files/AppsList.txt):
$script:RepoParsedList = $null

# Локализация:
$LangStrings = @{
	"RU" = @{
		"AccountCleared" = "Готово. Данные аккаунта {0} удалены."
		"AccountCurrent" = "(текущий)"
		"AccountLoggedOut" = "Выполнен выход из аккаунта Apple: {0}"
		"AccountLogoutMenuTitle" = "Выберите аккаунты Apple для выхода"
		"AccountMenu1" = "1. Добавить аккаунт"
		"AccountMenu2" = "2. Сменить аккаунт"
		"AccountMenu3" = "3. Выйти из аккаунта Apple"
		"AccountMenuTitle" = "Операции с аккаунтом Apple"
		"AccountSwitchMenuTitle" = "Выберите аккаунт Apple для перехода"
		"AddedToDownloadedAppsList" = "Добавлено в список приложений, загруженных скриптом (Files/DownloadedAppsList.json):`n{0} (ID: {1})"
		"AddedToPurchasedAppsList" = "Добавлено в список приложений, приобретенных скриптом (Files/PurchasedAppsList.json):`n{0} (ID: {1})"
		"AlreadyInList" = "Уже есть в списке: {0} (ID: {1})"
		"AppsCleared" = "Готово. Приложения в папке Apps удалены."
		"AskAppNumDownload" = "Введите порядковые номера (№) приложений для загрузки"
		"AskAppNumPurchase" = "Введите порядковые номера (№) приложений для покупки"
		"AskAppSearch" = "Введите название приложения или ID приложений"
		"AskFileNum" = "Введите порядковые номера (№) файлов для установки"
		"AskVersionsDownloadNum" = "Введите порядковые номера (№) версий для загрузки"
		"AskVersionsListNum" = "Введите порядковые номера (№) ID версий для отображения списка версий"
		"AuthFail" = "Вход в аккаунт Apple не выполнен."
		"AuthSuccess" = "Вход в аккаунт Apple выполнен.`nДанные аккаунта:"
		"CancelStep" = "(0: Возврат в главное меню):"
		"CancelStepVerID" = "(0: Возврат к вводу порядкового номера (№) ID версий):"
		"ClearAccountMenuTitle" = "Выберите аккаунты Apple для очистки"
		"ClearAllAccounts" = "Все аккаунты Apple"
		"ClearMenu1" = "1. Список приложений, приобретенных скриптом (Files/PurchasedAppsList.json)"
		"ClearMenu2" = "2. Список приложений, загруженных скриптом (Files/DownloadedAppsList.json)"
		"ClearMenu3" = "3. Приложения в папке Apps"
		"ClearMenuTitle" = "Выберите данные для очистки"
		"DebugEnabled" = "Режим отладки включен."
		"DebugDisabled" = "Режим отладки отключен."
		"DownloadedAppsListCleared" = "Готово. Список приложений, загруженных скриптом (Files/DownloadedAppsList.json), очищен."
		"DownloadedAppsListMenu3" = "3. Список приложений, загруженных скриптом (Files/DownloadedAppsList.json)"
		"DownloadedAppsListMenu4" = "4. Список приложений, не загруженных скриптом"
		"DownloaderMenu1" = "1. Поиск приложений по названию или ID и покупка (без загрузки)"
		"DownloaderMenu2" = "2. Поиск приложений по названию или ID и загрузка последней версии"
		"DownloaderMenu3" = "3. Поиск приложений по названию или ID и загрузка (с выбором версии)"
		"DownloaderMenu4" = "4. Выбор списка приложений и покупка (без загрузки)"
		"DownloaderMenu5" = "5. Выбор списка приложений и загрузка последней версии"
		"DownloaderMenu6" = "6. Выбор списка приложений и загрузка (с выбором версии)"
		"DownloaderMenu7" = "7. Проверка минимальной версии iOS для приложений в папке Apps"
		"DownloaderMenu8" = "8. Установка приложений из папки Apps"
		"DownloaderMenu9" = "9. Очистка данных"
		"DownloaderMenu10" = "10. Операции с аккаунтом Apple"
		"DownloaderMenu11" = "11. Банка для чаевых"
		"DownloaderMenu12" = "12. Сменить язык (Change Language)"
		"ErrorAppsListCustomEmpty" = "Ошибка: Пользовательский список приложений пуст.`nДобавьте приложения в Files/AppsListCustom.txt"
		"ErrorAppsListLoad" = "Ошибка загрузки списка приложений."
		"ErrorDownloadFiles" = "Ошибка: Не удалось загрузить файл:"
		"ErrorDownloadedAppsListEmpty" = "Ошибка: История загрузок пуста."
		"ErrorIdeviceinstallerNotFound" = "Ошибка: ideviceinstaller не найден.`nУстановка приложений по USB невозможна (только по AirDrop на macOS)"
		"ErrorInstallIpa" = "Ошибка: Не удалось установить/обновить приложение"
		"ErrorInvalidInput" = "Ошибка: Неверный ввод."
		"ErrorMissingFiles" = "Ошибка. Следующие файлы не найдены:"
		"ErrorNoApps" = "Ошибка: В папке Apps отсутствуют приложения."
		"ErrorNoAppsFound" = "Ошибка: Приложения не найдены."
		"ErrorNoOtherAccounts" = "Ошибка: Других аккаунтов Apple не найдено."
		"ErrorNoVersionsFound" = "Ошибка: Версии приложения не найдены."
		"ErrorOpenUrl" = "Ошибка: Не удалось открыть страницу."
		"ErrorPurchasedAppsListEmpty" = "Ошибка: История покупок пуста."
		"ErrorUpdateCheck" = "Ошибка: Не удалось проверить наличие обновлений."
		"FileName" = "Имя файла:"
		"FileSaved" = "Готово. Файл сохранен в папку Apps."
		"KbSyncGeneration" = "Формирование kbsync. Это может занять некоторое время."
		"HeaderAppID" = "ID приложения:"
		"HeaderAppName" = "Название приложения:"
		"HeaderMinIOS" = "Мин. версия iOS:"
		"HeaderNum" = "№"
		"HeaderVersionID" = "ID версии:"
		"HeaderVersion" = "Версия:"
		"InstallApp" = "Установка:"
		"InstallerMenu1" = "1. Проверка минимальной версии iOS для приложений в папке Apps"
		"InstallerMenu2" = "2. Установка приложений из папки Apps"
		"InstallerMenu3" = "3. Банка для чаевых"
		"InstallerMenu4" = "4. Сменить язык (Change Language)"
		"InstallerMenu5" = "5. Перейти в IPA_Downloader"
		"LanguageChanged" = "Язык успешно изменен на русский."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"Link" = "Ссылка:"
		"ListMenu1" = "1. Основной список приложений (Files/AppsList.txt)"
		"ListMenu2" = "2. Пользовательский список приложений (Files/AppsListCustom.txt)"
		"ListMenuTitle" = "Выберите список для отображения"
		"LoadingVersionsIDList" = "Загрузка списка ID версий приложения..."
		"LoggedOut" = "Выполнен выход из аккаунта Apple."
		"LoginMenu1" = "1. Войти в аккаунт Apple"
		"LoginMenu2" = "2. Перейти в режим IPA_Installer"
		"LoginMenu3" = "3. Сменить язык (Change Language)"
		"LogoutAllAccounts" = "Выйти из всех аккаунтов Apple и сбросить настройки скрипта"
		"MenuTitle" = "Введите команду:"
		"MinIOS" = "Минимальная версия iOS для установки:"
		"PurchasedAppsListCleared" = "Готово. Список приложений, приобретенных скриптом (Files/PurchasedAppsList.json), очищен."
		"PurchasedAppsListMenu3" = "3. Список приложений, приобретенных скриптом (Files/PurchasedAppsList.json)"
		"PurchasedAppsListMenu4" = "4. Список приложений, не приобретенных скриптом"
		"SelectedApp" = "Выбрано приложение:"
		"SelectedVersion" = "Выбрана версия:"
		"SelectedVersionsList" = "Выбраны следующие версии:"
		"TipJar" = "Спасибо за поддержку!"
		"UpdateAvailableTitle" = "Доступно обновление (версия {0}). Перейти на страницу репозитория для загрузки обновления?"
		"UpdateMenu1" = "1. Да"
		"UpdateMenu2" = "2. Нет"
	}
	"EN" = @{
		"AccountCleared" = "Done. Account {0} data cleared."
		"AccountCurrent" = "(current)"
		"AccountLoggedOut" = "Successfully logged out of Apple account: {0}"
		"AccountLogoutMenuTitle" = "Select Apple accounts to log out of"
		"AccountMenu1" = "1. Add account"
		"AccountMenu2" = "2. Switch account"
		"AccountMenu3" = "3. Log out of Apple account"
		"AccountMenuTitle" = "Apple account operations"
		"AccountSwitchMenuTitle" = "Select Apple account to switch to"
		"AddedToDownloadedAppsList" = "Added to list of apps downloaded by the script (Files/DownloadedAppsList.json):`n{0} (ID: {1})"
		"AddedToPurchasedAppsList" = "Added to list of apps purchased by the script (Files/PurchasedAppsList.json):`n{0} (ID: {1})"
		"AlreadyInList" = "Already in list: {0} (ID: {1})"
		"AppsCleared" = "Done. Apps folder has been cleared."
		"AskAppNumDownload" = "Enter index numbers (#) of apps to download"
		"AskAppNumPurchase" = "Enter index numbers (#) of apps to purchase"
		"AskAppSearch" = "Enter app name or app IDs"
		"AskFileNum" = "Enter index numbers (#) of files to install"
		"AskVersionsDownloadNum" = "index numbers (#) of app versions to download"
		"AskVersionsListNum" = "Enter index numbers (#) of version IDs to display app versions"
		"AuthFail" = "Not authenticated with Apple account."
		"AuthSuccess" = "Apple account login successful.`nAccount details:"
		"CancelStep" = "(0: Return to main menu):"
		"CancelStepVerID" = "(0: Return to entering index numbers (#) of version IDs):"
		"ClearAccountMenuTitle" = "Select Apple accounts to clear"
		"ClearAllAccounts" = "All Apple accounts"
		"ClearMenu1" = "1. List of apps purchased by the script (Files/PurchasedAppsList.json)"
		"ClearMenu2" = "2. List of apps downloaded by the script (Files/DownloadedAppsList.json)"
		"ClearMenu3" = "3. Apps in Apps folder"
		"ClearMenuTitle" = "Select data to clear"
		"DebugEnabled" = "Debug mode enabled."
		"DebugDisabled" = "Debug mode disabled"
		"DownloadedAppsListCleared" = "Done. List of apps downloaded by the script (Files/DownloadedAppsList.json) cleared."
		"DownloadedAppsListMenu3" = "3. List of apps downloaded by the script (Files/DownloadedAppsList.json)"
		"DownloadedAppsListMenu4" = "4. List of apps not downloaded by the script"
		"DownloaderMenu1" = "1. Search for apps by name or ID and purchase (without downloading)"
		"DownloaderMenu2" = "2. Search for apps by name or ID and download latest version"
		"DownloaderMenu3" = "3. Search for apps by name or ID and download (with version selection)"
		"DownloaderMenu4" = "4. Select an app list and purchase (without downloading)"
		"DownloaderMenu5" = "5. Select an app list and download latest version"
		"DownloaderMenu6" = "6. Select an app list and download (with version selection)"
		"DownloaderMenu7" = "7. Check the minimum iOS version for apps in the Apps folder"
		"DownloaderMenu8" = "8. Install apps from Apps folder"
		"DownloaderMenu9" = "9. Clear data"
		"DownloaderMenu10" = "10. Apple account operations"
		"DownloaderMenu11" = "11. Tip Jar"
		"DownloaderMenu12" = "12. Change Language (Сменить язык)"
		"ErrorAppsListCustomEmpty" = "Error: Custom apps list is empty.`nAdd apps to the Files/AppsListCustom.txt file"
		"ErrorAppsListLoad" = "Error: Failed to load apps list."
		"ErrorDownloadFiles" = "Error: Failed to download file:"
		"ErrorDownloadedAppsListEmpty" = "Error: Download history is empty."
		"ErrorIdeviceinstallerNotFound" = "Error: ideviceinstaller not found.`nInstalling apps via USB is impossible (only via AirDrop on macOS)"
		"ErrorInstallIpa" = "Error: Failed to install/upgrade the app"
		"ErrorInvalidInput" = "Error: Invalid input."
		"ErrorMissingFiles" = "Error. Following files were not found:"
		"ErrorNoApps" = "Error: No apps found in Apps folder."
		"ErrorNoAppsFound" = "Error: No apps found."
		"ErrorNoOtherAccounts" = "Error: No other Apple accounts found."
		"ErrorNoVersionsFound" = "Error: No app versions found."
		"ErrorOpenUrl" = "Error: Failed to open the page."
		"ErrorPurchasedAppsListEmpty" = "Error: Purchase history is empty."
		"ErrorUpdateCheck" = "Error: Failed to check for updates."
		"FileName" = "File name:"
		"FileSaved" = "Done. File saved to Apps folder."
		"HeaderAppID" = "App ID:"
		"HeaderAppName" = "App Name:"
		"HeaderMinIOS" = "Min. iOS version:"
		"HeaderNum" = "#"
		"HeaderVersionID" = "Version ID:"
		"HeaderVersion" = "Version:"
		"InstallApp" = "Installing:"
		"InstallerMenu1" = "1. Check the minimum iOS version for apps in the Apps folder"
		"InstallerMenu2" = "2. Install apps from Apps folder"
		"InstallerMenu3" = "3. Tip Jar"
		"InstallerMenu4" = "4. Change Language (Сменить язык)"
		"InstallerMenu5" = "5. Switch to IPA_Downloader"
		"KbSyncGeneration" = "Generation of kbsync. This may take some time."
		"LanguageChanged" = "Language successfully changed to English."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"Link" = "Link:"
		"ListMenu1" = "1. Main apps list (Files/AppsList.txt)"
		"ListMenu2" = "2. Custom apps list (Files/AppsListCustom.txt)"
		"ListMenuTitle" = "Select list to display"
		"LoadingVersionsIDList" = "Loading list of app version IDs..."
		"LoggedOut" = "Successfully logged out of Apple account."
		"LoginMenu1" = "1. Log in to Apple account"
		"LoginMenu2" = "2. Switch to IPA_Installer mode"
		"LoginMenu3" = "3. Change Language (Сменить язык)"
		"LogoutAllAccounts" = "Log out of all Apple accounts and reset script settings"
		"MenuTitle" = "Enter a command:"
		"MinIOS" = "Minimum iOS version required to install:"
		"PurchasedAppsListCleared" = "Done. List of apps purchased by the script (Files/PurchasedAppsList.json) cleared."
		"PurchasedAppsListMenu3" = "3. List of apps purchased by the script (Files/PurchasedAppsList.json)"
		"PurchasedAppsListMenu4" = "4. List of not purchased apps by the script"
		"SelectedApp" = "Selected app:"
		"SelectedVersion" = "Selected version:"
		"SelectedVersionsList" = "Selected versions:"
		"TipJar" = "Thanks for your support!"
		"UpdateAvailableTitle" = "Update available (version {0}). Open the repository page to download the update?"
		"UpdateMenu1" = "1. Yes"
		"UpdateMenu2" = "2. No"
	}
}

# Функция разделителя:
function Separator {
	Write-Host "==============================================================================" -ForegroundColor Green
}

# Определение регулярных выражений для ускорения рендеринга таблиц:
$script:reANSI = New-Object System.Text.RegularExpressions.Regex('\x1b\[[0-9;]*[a-zA-Z]', 'Compiled')
$script:reSpaces = New-Object System.Text.RegularExpressions.Regex('[\u00A0\u2000-\u200A\u202F\u205F\u3000]', 'Compiled')
$script:reDashes = New-Object System.Text.RegularExpressions.Regex('[\u2010-\u2015]', 'Compiled')
$script:reHidden = New-Object System.Text.RegularExpressions.Regex('[\u200B-\u200F\u202A-\u202E\u2060\uFEFF\u00AD\p{Cc}\p{Cf}]', 'Compiled')
$script:reWide = New-Object System.Text.RegularExpressions.Regex('[\u1100-\u115F\u2E80-\uA4CF\uAC00-\uD7A3\uF900-\uFAFF\uFF01-\uFF60]', 'Compiled')

# Функция вывода данных в виде таблицы:
function Out-Table {
	param (
		[array]$Data,
		[Parameter(Mandatory = $true)][string[]]$Headers,
		[Parameter(Mandatory = $true)][string[]]$Properties
	)
	
	if (-not $Data -or $Data.Count -eq 0) { return }
	
	# Очистка и измерение ячеек:
	function Get-CellInfo([string]$text) {
		if ([string]::IsNullOrEmpty($text)) { return @{ Text = ""; Width = 0 } }
		
		# Замена текста для корректного отображения:
		$s = $script:reANSI.Replace($text, '')
		$s = $script:reSpaces.Replace($s, ' ')
		$s = $script:reDashes.Replace($s, '-')
		$s = $script:reHidden.Replace($s, '')
		$s = $s.Normalize([System.Text.NormalizationForm]::FormC)
		
		# Расчет ширины:
		$visualWidth = $s.Length + $script:reWide.Matches($s).Count
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
		# Добавление массива ячеек:
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
	return $LangStrings[$script:CurrentLang][$Key]
}

# Функция вывода ошибки:
function Show-Error {
	param ([string]$Key)
	Separator
	Write-Host (Get-Lang $Key) -ForegroundColor DarkRed
}

# Определение переменной для хранения текущего аккаунта Apple:
$script:CurrentAppleAccount = "UnknownAccount"

# Функция получения текущего аккаунта Apple:
function Get-Current-AppleAccount {
	$AuthInfo = Invoke-Ipatool auth info | Out-String
	if ($AuthInfo -match 'email=([^\s]+)') {
		$script:CurrentAppleAccount = $script:reANSI.Replace($Matches[1].Trim(), '')
	} else {
		$script:CurrentAppleAccount = "UnknownAccount"
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
	$RepoName = Get-Repo-AppName -AppId $AppId
	return @{
		Display = if ([string]::IsNullOrWhiteSpace($RepoName)) { $AppId } else { $RepoName }
		Final = if ([string]::IsNullOrWhiteSpace($RepoName)) { "Unknown" } else { $RepoName }
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
	if ($Data.psobject.properties.Name -contains $script:CurrentAppleAccount) {
		$AccountApps = $Data."$script:CurrentAppleAccount"
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

# Функция входа в аккаунт Apple:
function Connect-AppleAccount {
	# Скрытие баннера с текущим режимом работы и версией скрипта при первой попытке авторизации:
	$FirstAttempt = $true
	
	while (!(Test-Path "$LoginFilePath")) {
		# Вывод баннера с текущим режимом работы и версией скрипта при повторных попытках авторизации:
		if (-not $FirstAttempt) {
			Show-ModeBanner
		} else {
			$FirstAttempt = $false
		}
		
		Separator
		Write-Host (Get-Lang "AuthFail")
		
		# Запрос аккаунта Apple и пароля:
		Invoke-Ipatool auth login
		
		# Формирование kbsync:
		Separator
		Write-Host (Get-Lang "KbSyncGeneration")
		$null = Invoke-Ipatool kbsync --refresh
		
		# Создание пустого файла login для фиксации успешной авторизации:
		if ($LASTEXITCODE -eq 0) {
			New-Item -Path $LoginFilePath -ItemType File -Force | Out-Null
			
			# Сохранение keychain-passphrase с шифрованием после успешного входа:
			if ($IsWin -and !([string]::IsNullOrEmpty($script:Kp))) {
				$KeychainFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "keychain-passphrase"
				$SecureKp = ConvertTo-SecureString -String $script:Kp -AsPlainText -Force
				$SecureKp | ConvertFrom-SecureString | Set-Content -Path $KeychainFilePath -Force
			}
		} else {
			# Удаление файлов авторизации:
			Clear-ActiveAccountFiles
		}
	}
	Get-Current-AppleAccount
	
	# Удаление ранее сохраненной папки аккаунта:
	$OldAccountFolderPath = Join-Path -Path $ipatoolHomePath -ChildPath $script:CurrentAppleAccount
	if ($OldAccountFolderPath -ne $ipatoolHomePath -and (Test-Path $OldAccountFolderPath)) {
		Remove-Item -Path $OldAccountFolderPath -Recurse -Force -ErrorAction SilentlyContinue
	}
}

# Функция получения списка сохраненных аккаунтов Apple:
function Get-SavedAppleAccounts {
	if (!(Test-Path $ipatoolHomePath)) {
		return @()
	}
	
	return @(Get-ChildItem -Path $ipatoolHomePath -Directory -ErrorAction SilentlyContinue | Sort-Object Name | ForEach-Object { $_.Name })
}

# Функция сохранения файлов авторизации текущего аккаунта в папку с названием аккаунта:
function Save-ActiveAccountFiles {
	param ([string]$Account)
	
	$AccountFolderPath = Join-Path -Path $ipatoolHomePath -ChildPath $Account
	$null = New-Item -Path $AccountFolderPath -ItemType Directory -Force
	
	foreach ($FileName in $AuthFileNames) {
		$SourcePath = Join-Path -Path $ipatoolHomePath -ChildPath $FileName
		if (Test-Path $SourcePath) {
			Move-Item -Path $SourcePath -Destination $AccountFolderPath -Force
		}
	}
}

# Функция возврата файлов авторизации сохраненного аккаунта из папки с названием аккаунта в .ipatool:
function Restore-SavedAccountFiles {
	param ([string]$Account)
	
	$AccountFolderPath = Join-Path -Path $ipatoolHomePath -ChildPath $Account
	
	foreach ($FileName in $AuthFileNames) {
		$SourcePath = Join-Path -Path $AccountFolderPath -ChildPath $FileName
		if (Test-Path $SourcePath) {
			Move-Item -Path $SourcePath -Destination $ipatoolHomePath -Force
		}
	}
	
	# Удаление пустой папки аккаунта:
	Remove-Item -Path $AccountFolderPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Функция удаления файлов авторизации текущего аккаунта:
function Clear-ActiveAccountFiles {
	foreach ($FileName in $AuthFileNames) {
		Remove-Item -Path (Join-Path -Path $ipatoolHomePath -ChildPath $FileName) -Force -ErrorAction SilentlyContinue
	}
	
	# Удаление папки .ipatool, если сохраненных аккаунтов нет:
	if (@(Get-SavedAppleAccounts).Count -eq 0) {
		Remove-Item -Path $ipatoolHomePath -Recurse -Force -ErrorAction SilentlyContinue
	}
}

# Функция перехода на сохраненный аккаунт Apple:
function Switch-AppleAccount {
	param ([string]$Account)
	
	# Сохранение файлов текущего аккаунта в папку с названием аккаунта:
	if (Test-Path "$LoginFilePath") {
		Save-ActiveAccountFiles -Account $script:CurrentAppleAccount
	}
	
	# Возврат файлов выбранного аккаунта:
	Restore-SavedAccountFiles -Account $Account
	Get-Current-AppleAccount
}

# Функция выбора сохраненного аккаунта Apple для перехода:
function Select-AppleAccount {
	param ([switch]$AllowCancel)
	
	$Accounts = @(Get-SavedAppleAccounts)
	if ($Accounts.Count -eq 0) {
		Show-Error "ErrorNoOtherAccounts"
		return
	}
	
	$AccountMenuText = "$(Get-Lang 'AccountSwitchMenuTitle')"
	if ($AllowCancel) {
		$AccountMenuText += " $(Get-Lang 'CancelStep')"
	}
	$AccountMenuText += "`n"
	$Counter = 1
	foreach ($Account in $Accounts) {
		$AccountMenuText += "$Counter. $Account`n"
		$Counter++
	}
	
	Separator
	$AccountChoice = Read-MenuChoice -MenuText $AccountMenuText -OptionsCount $Accounts.Count -AllowCancel:$AllowCancel
	if ($AccountChoice -eq '0') { return }
	
	Switch-AppleAccount -Account $Accounts[[int]$AccountChoice - 1]
}

# Функция добавления аккаунта Apple:
function Add-AppleAccount {
	$PreviousAccount = $script:CurrentAppleAccount
	
	# Сохранение файлов текущего аккаунта в папку с названием аккаунта:
	Save-ActiveAccountFiles -Account $PreviousAccount
	
	try {
		# Вход в новый аккаунт Apple:
		Connect-AppleAccount
	}
	finally {
		# Возврат предыдущего аккаунта, если вход не завершен:
		if (!(Test-Path "$LoginFilePath")) {
			Clear-ActiveAccountFiles
			Restore-SavedAccountFiles -Account $PreviousAccount
		}
	}
}

# Функция выхода из всех аккаунтов Apple и сброса настроек:
function Reset-AllAppleAccounts {
	Separator
	Write-Host (Get-Lang "LoggedOut")
	Invoke-Ipatool auth revoke
	
	# Удаление файлов настроек и папки .ipatool:
	Remove-Item -Path $SettingsFilePath -Force -ErrorAction SilentlyContinue
	Remove-Item -Path $ipatoolHomePath -Recurse -Force -ErrorAction SilentlyContinue
	
	# Сброс режима работы:
	$script:WorkMode = $null
}

# Функция выхода из выбранного аккаунта Apple:
function Invoke-AppleAccountLogout {
	# Формирование списка аккаунтов:
	$SavedAccounts = @(Get-SavedAppleAccounts)
	$Accounts = @($script:CurrentAppleAccount) + $SavedAccounts
	
	$AccountMenuText = "$(Get-Lang 'AccountLogoutMenuTitle') $(Get-Lang 'CancelStep')`n"
	$Counter = 1
	foreach ($Account in $Accounts) {
		$CurrentMark = if ($Counter -eq 1) { " $(Get-Lang 'AccountCurrent')" } else { "" }
		$AccountMenuText += "$Counter. $Account$CurrentMark`n"
		$Counter++
	}
	$AccountMenuText += "$Counter. $(Get-Lang 'LogoutAllAccounts')`n"
	
	Separator
	$AccountChoice = Read-MenuChoice -MenuText $AccountMenuText -OptionsCount $Counter -AllowCancel
	if ($AccountChoice -eq '0') { return }
	
	# Выход из аккаунтов Apple и сброс настроек скрипта:
	if ([int]$AccountChoice -eq $Counter -or $Accounts.Count -eq 1) {
		Reset-AllAppleAccounts
		return
	}
	
	$SelectedAccount = $Accounts[[int]$AccountChoice - 1]
	
	if ($AccountChoice -eq '1') {
		# Выход из текущего аккаунта:
		Separator
		Write-Host ((Get-Lang "AccountLoggedOut") -f $SelectedAccount)
		Invoke-Ipatool auth revoke
		Clear-ActiveAccountFiles
		
		# Выбор аккаунта для перехода:
		Select-AppleAccount
	} else {
		# Удаление сохраненного аккаунта:
		Remove-Item -Path (Join-Path -Path $ipatoolHomePath -ChildPath $SelectedAccount) -Recurse -Force -ErrorAction SilentlyContinue
		Separator
		Write-Host ((Get-Lang "AccountLoggedOut") -f $SelectedAccount)
	}
}

# Функция меню операций с аккаунтом Apple:
function Invoke-AccountMenu {
	Separator
	$AccountMenu = @"
$(Get-Lang 'AccountMenuTitle') $(Get-Lang 'CancelStep')
$(Get-Lang 'AccountMenu1')
$(Get-Lang 'AccountMenu2')
$(Get-Lang 'AccountMenu3')`n
"@
	$AccountChoice = Read-MenuChoice -MenuText $AccountMenu -OptionsCount 3 -AllowCancel
	
	switch ($AccountChoice) {
		"1" { Add-AppleAccount }
		"2" { Select-AppleAccount -AllowCancel }
		"3" { Invoke-AppleAccountLogout }
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

# Функция инициализации и кэширования основного списка приложений (Files/AppsList.txt):
function Initialize-Repo-List {
	if ($null -ne $script:RepoParsedList) {
		return
	}
	
	try {
		# Возвращение пустого списка, если файл отсутствует:
		if (!(Test-Path $AppsListPath)) {
			$script:RepoParsedList = @()
			return
		}
		
		# Чтение уже загруженного локального файла:
		$Raw = Get-Content -Path $AppsListPath -Raw -Encoding UTF8 -ErrorAction Stop
		
		if ([string]::IsNullOrWhiteSpace($Raw)) {
			$script:RepoParsedList = @()
			return
		}
		
		# Парсинг списка:
		$script:RepoParsedList = @(
			$Raw -split "`r?`n" |
			Where-Object {
				$_ -match '^(.+?):\s*(\d+)'
			} |
			ForEach-Object {
				[PSCustomObject]@{
					Name = $Matches[1].Trim()
					Id = $Matches[2].Trim()
				}
			}
		)
	}
	catch {
		$script:RepoParsedList = @()
	}
}

# Функция переименования файлов старых версий скрипта в папке Files:
function Rename-Legacy-Files {
	$LegacyFiles = @(
		[PSCustomObject]@{ OldName = "Apps_ID_List.txt"; NewPath = $AppsListPath }
		[PSCustomObject]@{ OldName = "Purchased_IDs.json"; NewPath = $PurchasedAppsListFilePath }
		[PSCustomObject]@{ OldName = "Downloaded_IDs.json"; NewPath = $DownloadedAppsListFilePath }
	)
	
	foreach ($LegacyFile in $LegacyFiles) {
		$OldPath = Join-Path -Path $FilesFolderPath -ChildPath $LegacyFile.OldName
		
		# Переименование старого файла с заменой нового файла:
		if (Test-Path -LiteralPath $OldPath -PathType Leaf) {
			try {
				Move-Item -LiteralPath $OldPath -Destination $LegacyFile.NewPath -Force -ErrorAction Stop
			}
			catch {
			}
		}
	}
}

# Функция создания пустого файла с пользовательским списком приложений (Files/AppsListCustom.txt):
function Initialize-Custom-List-File {
	if (!(Test-Path $AppsListCustomPath)) {
		try {
			$null = New-Item -Path $AppsListCustomPath -ItemType "File" -Force -ErrorAction Stop
		}
		catch {
		}
	}
}

# Функция чтения и парсинга файла с основным списком приложений (Files/AppsList.txt):
function Read-AppsListFile {
	param ([string]$FilePath)
	
	$Result = @()
	
	try {
		if (!(Test-Path $FilePath)) {
			return $Result
		}
		
		$Raw = Get-Content -Path $FilePath -Raw -Encoding UTF8 -ErrorAction Stop
		
		if ([string]::IsNullOrWhiteSpace($Raw)) {
			return $Result
		}
		
		foreach ($Line in ($Raw -split "`r?`n")) {
			if ($Line -match '^(.+?):\s*(\d+)') {
				$Result += [PSCustomObject]@{
					Name = $Matches[1].Trim()
					Id = $Matches[2].Trim()
				}
			}
		}
	}
	catch {
	}
	
	return $Result
}

# Функция удаления дублей по ID с сохранением исходного порядка:
function Remove-Duplicate-Ids {
	param ([array]$Items)
	
	$SeenIds = @{}
	$Result = @()
	
	foreach ($Item in $Items) {
		$Key = "$($Item.Id)"
		if (-not $SeenIds.ContainsKey($Key)) {
			$SeenIds[$Key] = $true
			$Result += $Item
		}
	}
	
	return $Result
}

# Функция получения пользовательского списка приложений (Files/AppsListCustom.txt):
function Get-Custom-List {
	Initialize-Custom-List-File
	
	$List = @(Read-AppsListFile -FilePath $AppsListCustomPath)
	
	# Удаление дублей по ID внутри пользовательского списка приложений (Files/AppsListCustom.txt):
	return @(Remove-Duplicate-Ids -Items $List)
}

# Функция предварительной загрузки основного списка приложений (Files/AppsList.txt) и предупреждения (Files/Warning.txt):
function Initialize-RemoteFiles {
	$RemoteFiles = @(
		[PSCustomObject]@{
			Url = "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Files/AppsList.txt"
			Temp = $AppsListTempPath
			Final = $AppsListPath
		}
		[PSCustomObject]@{
			Url = "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Files/Warning.txt"
			Temp = $WarningTempPath
			Final = $WarningPath
		}
	)
	
	foreach ($RemoteFile in $RemoteFiles) {
		try {
			# Загрузка во временный файл:
			Invoke-RestMethod -Uri $RemoteFile.Url -OutFile $RemoteFile.Temp -TimeoutSec 3 -ErrorAction Stop
			
			# Проверка наличия временного файла:
			if (Test-Path $RemoteFile.Temp) {
				# Замена файла только после успешной загрузки:
				Move-Item -Path $RemoteFile.Temp -Destination $RemoteFile.Final -Force -ErrorAction Stop
			}
		}
		catch {
			# Получение имени файла и вывод ошибки загрузки в консоль:
			$FileName = Split-Path -Leaf $RemoteFile.Final
			Separator
			Write-Host "$(Get-Lang "ErrorDownloadFiles") $FileName" -ForegroundColor DarkRed
			
			# Удаление временного файла:
			if (Test-Path $RemoteFile.Temp) {
				Remove-Item -Path $RemoteFile.Temp -Force -ErrorAction SilentlyContinue
			}
		}
	}
	
	# Сброс кэша перед повторной инициализацией:
	$script:RepoParsedList = $null
	
	# Чтение основного списка приложений (Files/AppsList.txt) и сохранение в памяти:
	Initialize-Repo-List
	
	# Чтение предупреждения (Files/Warning.txt) и сохранение в памяти:
	$script:WarningText = $null
	
	if (Test-Path $WarningPath) {
		$script:WarningText = Get-Content -Path $WarningPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
	}
}

# Функция сохранения списков приобретенных (Files/PurchasedAppsList.json)/загруженных приложений (Files/DownloadedAppsList.json)
# с привязкой к аккаунту и сортировкой:
function Save-App-To-List {
	param (
		[string]$AppId,
		[string]$AppNameOnly,
		[ValidateSet("Downloaded", "Purchased")][string]$Type
	)
	
	if ([string]::IsNullOrWhiteSpace($AppNameOnly) -or $AppNameOnly -eq "Unknown") {
		return
	}
	
	$HistoryFile = if ($Type -eq "Purchased") { "$PurchasedAppsListFilePath" } else { "$DownloadedAppsListFilePath" }
	
	# Создание файла, если его нет:
	if (!(Test-Path $HistoryFile)) {
		$null = New-Item -Path $HistoryFile -ItemType "File" -Value '{}'
	}
	
	$JsonRaw = Get-Content $HistoryFile -Raw -Encoding UTF8
	if ([string]::IsNullOrWhiteSpace($JsonRaw)) { $JsonRaw = '{}' }
	
	$Data = $JsonRaw | ConvertFrom-Json
	if ($null -eq $Data -or ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [System.Management.Automation.PSCustomObject])) {
		$Data = New-Object PSCustomObject
	}
	
	# Получение списка приложений для текущего аккаунта:
	$AccountApps = @()
	if ($Data.psobject.properties.Name -contains $script:CurrentAppleAccount) {
		$AccountApps = $Data."$script:CurrentAppleAccount"
	} else {
		$Data | Add-Member -MemberType NoteProperty -Name $script:CurrentAppleAccount -Value @()
	}
	
	if ($AccountApps -isnot [System.Collections.IEnumerable]) { $AccountApps = @($AccountApps) }
	
	# Загрузка основного списка приложений (Files/AppsList.txt):
	Initialize-Repo-List
	
	# Создание хэш-таблицы для поиска актуальных имен и индексов:
	$ReferenceMap = @{}
	for ($i = 0; $i -lt $script:RepoParsedList.Count; $i++) {
		$RefApp = $script:RepoParsedList[$i]
		$ReferenceMap[$RefApp.Id] = @{ Index = $i; Name = $RefApp.Name }
	}
	
	# Добавление приложений из пользовательского списка приложений (Files/AppsListCustom.txt):
	$CustomList = @(Get-Custom-List)
	for ($i = 0; $i -lt $CustomList.Count; $i++) {
		$RefApp = $CustomList[$i]
		if ($ReferenceMap.ContainsKey($RefApp.Id)) {
			$ReferenceMap[$RefApp.Id].Name = $RefApp.Name
		} else {
			$ReferenceMap[$RefApp.Id] = @{ Index = $script:RepoParsedList.Count + $i; Name = $RefApp.Name }
		}
	}
	
	$IsDuplicate = $false
	
	# Синхронизация имен сохраненных приложений со списком приложений и поиск дубликатов:
	foreach ($Item in $AccountApps) {
		if ($ReferenceMap.ContainsKey($Item.appid)) {
			$Item.name = $ReferenceMap[$Item.appid].Name
		}
		if ($Item.appid -eq $AppId) {
			$IsDuplicate = $true
		}
	}
	
	# Добавление нового приложения:
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
	$Data."$script:CurrentAppleAccount" = $AccountApps
	$Data | ConvertTo-Json -Depth 5 | Set-Content $HistoryFile -Encoding UTF8
	
	# Вывод сообщений:
	if ($IsDuplicate) {
		$CurrentName = if ($ReferenceMap.ContainsKey($AppId)) { $ReferenceMap[$AppId].Name } else { $AppNameOnly }
		Write-Host ((Get-Lang "AlreadyInList") -f $CurrentName, $AppId)
	} else {
		$MsgKey = if ($Type -eq "Purchased") { "AddedToPurchasedAppsList" } else { "AddedToDownloadedAppsList" }
		Write-Host ((Get-Lang $MsgKey) -f $AppNameOnly, $AppId)
	}
}

# Функция вывода предупреждения (Files/Warning.txt):
function Show-WarningMsg {
	if (![string]::IsNullOrWhiteSpace($script:WarningText)) {
		Separator
		Write-Host $script:WarningText -BackgroundColor Yellow -ForegroundColor Black
	}
}

# Функция поиска имени приложения по кэшу:
function Get-Repo-AppName {
	param ([string]$AppId)
	Initialize-Repo-List
	# Поиск в пользовательском списке приложений (Files/AppsListCustom.txt):
	$App = @(Get-Custom-List) | Where-Object { $_.Id -eq $AppId } | Select-Object -First 1
	if ($App) { return $App.Name }
	
	# Поиск в основном списке приложений (Files/AppsList.txt):
	$App = $script:RepoParsedList | Where-Object { $_.Id -eq $AppId } | Select-Object -First 1
	if ($App) { return $App.Name } else { return $null }
}

# Функция перемещения и автоматического переименования:
function Move-IPA-Files {
	param (
		[string]$AppId,
		[string]$AppName
	)
	# Создание папки Apps:
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
				
				# Проверка основного списка приложений (Files/AppsList.txt):
				if ([string]::IsNullOrWhiteSpace($AppName) -or $AppName -eq "Unknown") {
					$RepoName = Get-Repo-AppName -AppId $AppId
					if (![string]::IsNullOrWhiteSpace($RepoName)) {
						$AppName = $RepoName
					}
				}
				
				# Применение найденного имени:
				if (![string]::IsNullOrWhiteSpace($AppName) -and $AppName -ne "Unknown") {
					$FinalAppName = $AppName -replace '[\\/:*?"<>|]', ''
				}
				
				# Формирование имени файла и замена всех пробелов на "_":
				$NewName = "$($FinalAppName)_$($Meta.Version)_iOS_$($Meta.MinIOS)+_$($script:CurrentAppleAccount).ipa" -replace '\s+', '_'
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
		Show-Error "ErrorInvalidInput"
		return $false
	}
	return $true
}

# Функция парсинга введенных номеров и диапазонов:
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
	Invoke-Ipatool download -i $AppId --purchase
	Move-IPA-Files -AppId $AppId -AppName $AppName
}

# Функция загрузки приложений с выбором версии:
function IPA-Download-With-Version {
	param (
		[string]$AppId,
		[string]$AppName
	)
	if (!(Test-NumericInput -InputValue $AppId)) { return }
	
	$RawOutput = Invoke-Ipatool list-versions -i $AppId --purchase
	
	if ($RawOutput -match "Error:") {
		Write-Host $RawOutput -ForegroundColor DarkRed
		return
	}
	
	# Проверка на пустой ответ:
	if ([string]::IsNullOrEmpty($RawOutput)) {
		Show-Error "ErrorNoVersionsFound"
		return
	}
	
	# Извлечение всех версий:
	$RawVersions = [regex]::Matches($RawOutput, '(?<=")\d+(?=")') | ForEach-Object { $_.Value }
	$RecentVersions = $RawVersions | Sort-Object
	
	# Вывод ошибки, если версии приложения не найдены:
	if ($RecentVersions.Count -eq 0) {
		Show-Error "ErrorNoVersionsFound"
		return
	}
	
	Separator
	Write-Host (Get-Lang "LoadingVersionsIDList")
	
	$VersionMapping = @()
	$Counter = 1
	foreach ($VersionId in $RecentVersions) {
		$VersionMapping += [PSCustomObject]@{
			Num = $Counter
			ID = $VersionId
		}
		$Counter++
	}
	
	# Внешний цикл:
	while ($true) {
		Separator
		Out-Table -Data @($VersionMapping) -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderVersionID") -Properties "Num", "ID"
		Separator
		
		# Запрос порядкового номера (№) для вычисления и отображения версий:
		$PreSelectedIndices = Read-NumberSelection -PromptKey 'AskVersionsListNum' -MaxCount $VersionMapping.Count
		
		# Если пользователь ввел 0 (возврат в главное меню):
		if ($null -eq $PreSelectedIndices) { return } 
		
		$PreSelectedVersions = @()
		foreach ($Idx in $PreSelectedIndices) {
			$PreSelectedVersions += $VersionMapping[$Idx - 1]
		}
		
		# Подготовка таблицы Print-StreamRow для отображения версий:
		$HeaderNum = Get-Lang "HeaderNum"
		$HeaderVersionID = Get-Lang "HeaderVersionID"
		$HeaderVersion = Get-Lang "HeaderVersion"
		
		$W1 = [Math]::Max($HeaderNum.Length, "$($PreSelectedVersions.Count)".Length)
		$MaxIdLen = $HeaderVersionID.Length
		foreach ($v in $PreSelectedVersions) {
			if ($v.ID.Length -gt $MaxIdLen) { $MaxIdLen = $v.ID.Length }
		}
		$W2 = [Math]::Max($HeaderVersion.Length, 15)
		$W3 = $MaxIdLen
		
		$ColWidths = @($W1, $W2, $W3)
		
		$TopParts = foreach ($w in $ColWidths) { "─" * ($w + 2) }
		$SepParts = foreach ($w in $ColWidths) { "─" * ($w + 2) }
		$BottomParts = foreach ($w in $ColWidths) { "─" * ($w + 2) }
		$LineTop = "┌" + ($TopParts -join "┬") + "┐"
		$LineSep = "├" + ($SepParts -join "┼") + "┤"
		$LineBottom = "└" + ($BottomParts -join "┴") + "┘"
		
		function Print-StreamRow ([string[]]$cells) {
			$formatted = for ($i = 0; $i -lt $cells.Count; $i++) {
				$text = "$($cells[$i])"
				$pad = [Math]::Max(0, $ColWidths[$i] - $text.Length)
				" " + $text + (" " * $pad) + " "
			}
			Write-Host ("│" + ($formatted -join "│") + "│")
		}
		
		$DetailedMapping = @()
		$DetailCounter = 1
		
		# Запрос метаданных для выбранных ID:
		foreach ($SelectedObject in $PreSelectedVersions) {
			$VersionId = $SelectedObject.ID
			$Meta = Invoke-Ipatool get-version-metadata -i $AppId --external-version-id $VersionId
			$DisplayVersion = if ($Meta -match 'displayVersion=([^\s,]+)') { $Matches[1] } else { "NA" }
			$DisplayVersion = $script:reANSI.Replace($DisplayVersion, '')
			
			$DetailedMapping += [PSCustomObject]@{
				Index = $DetailCounter
				ID = $VersionId
				Version = $DisplayVersion
			}
			$DetailCounter++
		}
		
		Separator
		Write-Host (Get-Lang "SelectedVersionsList")
		Separator
		
		# Отрисовка таблицы:
		Write-Host $LineTop
		Print-StreamRow @($HeaderNum, $HeaderVersion, $HeaderVersionID)
		Write-Host $LineSep
		
		foreach ($Item in $DetailedMapping) {
			Print-StreamRow @("$($Item.Index)", "$($Item.Version)", "$($Item.ID)")
		}
		
		Write-Host $LineBottom
		Separator
		
		# Запрос порядковых номеров (№) версий для загрузки:
		$GoBack = $false
		$FinalIndices = $null
		
		while ($true) {
			$Selection = Read-Host "$(Get-Lang 'AskVersionsDownloadNum') (1-$($DetailedMapping.Count)) $(Get-Lang 'CancelStepVerID')`n"
			
			# Возврат к предыдущему списку:
			if ($Selection -eq '0') {
				$GoBack = $true
				break
			}
			
			if ([string]::IsNullOrWhiteSpace($Selection)) {
				Show-Error "ErrorInvalidInput"
				Separator
				continue
			}
			
			$FinalIndices = Parse-NumberSelection -Selection $Selection -MaxCount $DetailedMapping.Count
			
			if ($null -eq $FinalIndices) {
				Show-Error "ErrorInvalidInput"
				Separator
				continue
			}
			
			break
		}
		
		# Возврат цикла к основной таблице, если пользователь ввел 0:
		if ($GoBack) {
			continue 
		}
		
		# Загрузка выбранных финальных версий:
		foreach ($Idx in $FinalIndices) {
			$SelectedToDownload = $DetailedMapping[$Idx - 1]
			Separator
			
			# Вывод выбранной версии приложения:
			Write-Host "$(Get-Lang 'SelectedVersion') $($SelectedToDownload.Version)"
			Separator
			$FinalId = $SelectedToDownload.ID
			Invoke-Ipatool download -i $AppId --external-version-id $FinalId
			Move-IPA-Files -AppId $AppId -AppName $AppName
		}
		
		# Выход из цикла после успешной загрузки:
		break 
	}
}

# Функция выполнения действия с приложением:
function Invoke-AppAction {
	param (
		[string]$AppId,
		[string]$AppName,
		[string]$DisplayName,
		[ValidateSet("Purchase", "Download", "DownloadVersion")][string]$Action,
		[int]$Current,
		[int]$Total
	)
	Separator
	
	# Счетчик выбранных приложений:
	$CounterText = if ($Total -gt 0) { "$Current/$Total " } else { "" }
	Write-Host "$CounterText$(Get-Lang 'SelectedApp') $DisplayName (ID: $AppId)"
	switch ($Action) {
		"Purchase" {
			Separator
			Invoke-Ipatool purchase -i $AppId
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

# Функция поиска приложений по названию или ID приложений:
function Search-Apps {
	param (
		[string]$PromptKey = 'AskAppNumDownload'
	)
	while ($true) {
		Separator
		$AppName = Read-Host "$(Get-Lang 'AskAppSearch') $(Get-Lang 'CancelStep')`n"
		
		if ($AppName -eq '0') { return $null }
		
		# Ввод ID через запятую:
		$IdParts = @($AppName.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
		if ([string]::IsNullOrWhiteSpace($AppName) -or $IdParts.Count -eq 0) {
			Show-Error "ErrorInvalidInput"
			continue
		}
		
		# Определение ввода ID приложения (число от 6 знаков):
		if (@($IdParts | Where-Object { $_ -notmatch '^\d{6,}$' }).Count -eq 0) {
			$IdApps = @()
			foreach ($Id in $IdParts) {
				$AppNames = Resolve-AppDisplayName -AppId $Id
				$IdApps += [PSCustomObject]@{
					Id = $Id
					Name = $AppNames.Final
					Display = $AppNames.Display
				}
			}
			return $IdApps
		}
		
		break
	}
	
	# Инициализация списка основного списка приложений (Files/AppsList.txt):
	Initialize-Repo-List
	
	# Поиск в пользовательском списке приложений (Files/AppsListCustom.txt):
	$CustomList = @(Get-Custom-List)
	$FoundApps = @($CustomList | Where-Object { $_.Name -match [regex]::Escape($AppName) } | ForEach-Object {
		[PSCustomObject]@{
			name = $_.Name
			id = $_.Id
		}
	})
	
	# Поиск в основном списке приложений (Files/AppsList.txt):
	$CustomIds = @($CustomList | ForEach-Object { $_.Id })
	if ($null -ne $script:RepoParsedList) {
		$FoundApps += @($script:RepoParsedList | Where-Object { $CustomIds -notcontains $_.Id -and $_.Name -match [regex]::Escape($AppName) } | ForEach-Object {
			[PSCustomObject]@{
				name = $_.Name
				id = $_.Id
			}
		})
	}
	
	# Поиск в App Store:
	$SearchOutput = Invoke-Ipatool search $AppName --limit 10 --format json --non-interactive | Out-String
	
	if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrWhiteSpace($SearchOutput)) {
		try {
			$SearchResult = $SearchOutput | ConvertFrom-Json
			
			if ($SearchResult.apps) {
				foreach ($Item in @($SearchResult.apps)) {
					$FoundApps += [PSCustomObject]@{
						Name = $Item.name
						Id = $Item.id
					}
				}
			}
		}
		catch {
		}
	}
	
	# Удаление дублей приложений по ID:
	$FoundApps = @(Remove-Duplicate-Ids -Items $FoundApps)
	
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
	
	Out-Table -Data $TableData -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID") -Properties "Num", "Name", "ID"
	Separator
	
	# Выбор приложений:
	$Indices = Read-NumberSelection -PromptKey $PromptKey -MaxCount $FoundApps.Count
	if ($null -eq $Indices) { return $null }
	
	$SelectedApps = @()
	foreach ($Idx in $Indices) {
		$SelectedApp = $FoundApps[$Idx - 1]
		$SelectedApps += [PSCustomObject]@{
			Id = $SelectedApp.Id
			Name = $SelectedApp.Name
			Display = $SelectedApp.Name
		}
	}
	return $SelectedApps
}

# Функция получения списка выбранных приложений:
function Get-Apps-From-List {
	param (
		[string]$ListMode = "Download"
	)
	
	$MenuTitle = Get-Lang 'ListMenuTitle'
	$Menu1 = Get-Lang 'ListMenu1'
	$Menu2 = Get-Lang 'ListMenu2'
	$Menu3 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedAppsListMenu3' } else { Get-Lang 'DownloadedAppsListMenu3' }
	$Menu4 = if ($ListMode -eq "Purchase") { Get-Lang 'PurchasedAppsListMenu4' } else { Get-Lang 'DownloadedAppsListMenu4' }
	$TargetFile = if ($ListMode -eq "Purchase") { "$PurchasedAppsListFilePath" } else { "$DownloadedAppsListFilePath" }
	$EmptyError = if ($ListMode -eq "Purchase") { "ErrorPurchasedAppsListEmpty" } else { "ErrorDownloadedAppsListEmpty" }
	$List_Menu = @"
$MenuTitle $(Get-Lang 'CancelStep')
$Menu1
$Menu2
$Menu3
$Menu4`n
"@
	$ListChoice = Read-MenuChoice -MenuText $List_Menu -OptionsCount 4 -AllowCancel
	
	if ($ListChoice -eq '0') { return $null }
	
	$Lines = @()
	
	switch ($ListChoice) {
		"1" {
			Initialize-Repo-List
			if ($script:RepoParsedList.Count -eq 0) {
				Show-Error "ErrorAppsListLoad"
				return $null
			}
			foreach ($App in $script:RepoParsedList) {
				$Lines += "{0}: {1}" -f $App.Name, $App.Id
			}
		}
		
		"2" {
			$CustomList = @(Get-Custom-List)
			if ($CustomList.Count -eq 0) {
				Show-Error "ErrorAppsListCustomEmpty"
				return $null
			}
			foreach ($App in $CustomList) {
				$Lines += "{0}: {1}" -f $App.Name, $App.Id
			}
		}
		
		"3" {
			$HistoryData = Read-AppList-Json -FilePath $TargetFile -EmptyError $EmptyError
			if ($null -eq $HistoryData) { return $null }
			
			foreach ($Item in $HistoryData) {
				$Lines += "{0}: {1}" -f $Item.Name, $Item.Appid
			}
		}
		
		"4" {
			Initialize-Repo-List
			if ($script:RepoParsedList.Count -eq 0) {
				Show-Error "ErrorAppsListLoad"
				return $null
			}
			
			$SavedIds = @()
			if (Test-Path $TargetFile) {
				$HistoryData = Read-AppList-Json -FilePath $TargetFile -EmptyError $EmptyError
				if ($null -ne $HistoryData) {
					$SavedIds = $HistoryData.Appid
				}
			}
			
			foreach ($App in $script:RepoParsedList) {
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
	$TableData = foreach ($I in 0..($Lines.Count - 1)) {
		$SelectedLine = $Lines[$I]
		$AppId = [System.Text.RegularExpressions.Regex]::Match($SelectedLine, '\b\d{6,}\b').Value
		$AppName = "Unknown"
		if ($SelectedLine -match '^(.+?):\s*\d') {
			$AppName = $Matches[1].Trim()
		}
		
		[PSCustomObject]@{
			Num = $I + 1
			Name = $AppName
			ID = $AppId
		}
	}
	
	Separator
	Out-Table -Data $TableData -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID") -Properties "Num", "Name", "ID"
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
	
	# Присваивание вывода цикла переменной:
	$TableData = foreach ($File in @($FilesToProcess)) { 
		$Meta = Get-IPA-Metadata -IpaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)" } else { "Error" }
		
		[PSCustomObject]@{
			Num = $Counter++
			Name = $File.Name
			MinOs = $MinOs
		}
	}
	
	Out-Table -Data @($TableData) -Headers (Get-Lang "HeaderNum"), (Get-Lang "FileName"), (Get-Lang "HeaderMinIOS") -Properties "Num", "Name", "MinOs"
		
	return @($FilesToProcess)
}

# Функция вывода ошибки об отсутствии необходимых файлов:
function Check-RequiredFiles {
	param ([array]$MissingFiles)
	if ($MissingFiles) {
		Show-Error "ErrorMissingFiles"
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
	
	# Добавление папки с ipatool в PATH:
	if ($NewFolder -notin $PathEntries) {
		$env:Path = $env:Path + $PathSeparator + $NewFolder
	}
}

# Функция установки путей к ipatool/ideviceinstaller и применения PATH/прав запуска:
function Set-IpatoolBinaryPaths {
	param ([string]$FolderPath)
	
	if ($IsWin) {
		$ipatoolFile = Get-ChildItem -Path $FolderPath -Filter "ipatool*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
		$ideviceFile = Get-ChildItem -Path $FolderPath -Filter "ideviceinstaller*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
		
		if ($ipatoolFile) { $script:ipatoolFilePath = $ipatoolFile.FullName }
		if ($ideviceFile) { $script:ideviceinstallerFilePath = $ideviceFile.FullName }
		
		# Добавление папки с ipatool в PATH текущего процесса:
		Update-PathFolder -NewFolder $FolderPath
	} else {
		$ipatoolFile = Get-ChildItem -Path $FolderPath -Filter "ipatool*" -File -ErrorAction SilentlyContinue | Select-Object -First 1
		
		if ($ipatoolFile) {
			$script:ipatoolFilePath = $ipatoolFile.FullName
			
			# Снятие карантина (macOS) и выдача прав на запуск:
			if ($IsMac) {
				xattr -cr "$FolderPath" 2>$null
			}
			chmod +x "$script:ipatoolFilePath" 2>$null
		}
	}
}

# Функция проверки наличия необходимых файлов:
function Get-MissingBinaryFiles {
	param ([string]$FolderPath)
	
	$MissingFiles = @()
	
	if ($IsWin) {
		$RequiredPatterns = @("ideviceinstaller*.exe", "ipatool*.exe")
		foreach ($Pattern in $RequiredPatterns) {
			$Found = Get-ChildItem -Path $FolderPath -Filter $Pattern -File -ErrorAction SilentlyContinue
			if (-not $Found) {
				$MissingFiles += $Pattern
			}
		}
	} else {
		$FoundIpatool = Get-ChildItem -Path $FolderPath -Filter "ipatool*" -File -ErrorAction SilentlyContinue
		if (-not $FoundIpatool) {
			$MissingFiles += "ipatool*"
		}
	}
	
	return $MissingFiles
}

# Функция установки приложений из папки Apps:
function Install-Apps {
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
				& "$script:ideviceinstallerFilePath" install $TempFile
				
				if ($LASTEXITCODE -ne 0) {
					& "$script:ideviceinstallerFilePath" upgrade $TempFile
					
					if ($LASTEXITCODE -ne 0) {
						Show-Error "ErrorInstallIpa"
					}
				}
			} finally {
				Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
			}
		}
	}
}

# Функция открытия ссылки в браузере:
function Open-Url {
	param (
		[string]$Url
	)
	
	try {
		if ($IsWin) {
			Start-Process -FilePath $Url -ErrorAction Stop
		} elseif ($IsMac) {
			Start-Process -FilePath "open" -ArgumentList $Url -ErrorAction Stop
		} else {
			Start-Process -FilePath "xdg-open" -ArgumentList $Url -ErrorAction Stop
		}
		return $true
	} catch {
		return $false
	}
}

# Функция проверки обновлений:
function Check-Update {
	try {
		$RepoUrl = "https://api.github.com/repos/kda2495/IPA_Downloader/releases/latest"
		$LatestRelease = Invoke-RestMethod -Uri $RepoUrl -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
		
		if ($LatestRelease -and $LatestRelease.tag_name) {
			
			# Извлечение числа из версии:
			$LatestVersion = [regex]::Match($LatestRelease.tag_name, '\d+(\.\d+)+').Value
			$CurrentVersion = [regex]::Match($ScriptVersion, '\d+(\.\d+)+').Value
			$UpdateFound = $false
			
			# Проверка, что обе переменные не пустые, чтобы избежать ошибок конвертации:
			if (![string]::IsNullOrEmpty($LatestVersion) -and ![string]::IsNullOrEmpty($CurrentVersion)) {
				
				# Вывод информации об обновлении, если числовая версия больше:
				if ([version]$LatestVersion -gt [version]$CurrentVersion) {
					$UpdateFound = $true
				}
			}
			
			if ($UpdateFound) {
				Separator
				$UpdateMenuText = @"
$((Get-Lang 'UpdateAvailableTitle') -f $LatestRelease.tag_name)
$(Get-Lang 'UpdateMenu1')
$(Get-Lang 'UpdateMenu2')`n
"@
				$Choice = Read-MenuChoice -MenuText $UpdateMenuText -OptionsCount 2
				if ($Choice -eq '1') {
					
					# Ссылка на страницу релизов:
					$ReleasesUrl = "https://github.com/kda2495/IPA_Downloader/releases"
					
					# Вывод ссылки, в случае ошибки открытия в браузере:
					if (-not (Open-Url $ReleasesUrl)) {
						Show-Error "ErrorOpenUrl"
						Separator
						Write-Host (Get-Lang "Link") $ReleasesUrl
						Separator
					}
					exit
				}
			}
		}
	} catch {
		Show-Error "ErrorUpdateCheck"
	}
}

# Функция вывода баннера с текущим режимом работы и версией скрипта:
function Show-ModeBanner {
	Separator
	
	if ($script:WorkMode -eq "Installer") {
		Write-Host "IPA_Installer $ScriptVersion"
		Show-SystemInfo
	} else {
		$IpatoolFileName = if ($script:ipatoolFilePath) {
			Split-Path -Leaf $script:ipatoolFilePath
		} else {
			$Filter = if ($IsWin) { "ipatool*.exe" } else { "ipatool*" }
			$FoundFile = Get-ChildItem -Path $script:BinaryFolderPath -Filter $Filter -File -ErrorAction SilentlyContinue | Select-Object -First 1
			if ($FoundFile) { $FoundFile.Name } else { "ipatool" }
		}
		
		Write-Host "IPA_Downloader $ScriptVersion ($IpatoolFileName)"
		Show-SystemInfo
	}
}

# Функция открытия банки для чаевых:
function Open-TipJar {
	# Ссылка на банку с чаевыми:
	$TipJarUrl = "https://pay.cloudtips.ru/p/93c0b094"
	
	# Вывод ссылки, в случае ошибки открытия в браузере:
	if (-not (Open-Url $TipJarUrl)) {
		Show-Error "ErrorOpenUrl"
		Separator
		Write-Host (Get-Lang "Link") $TipJarUrl
	}
	
	Separator
	Write-Host (Get-Lang "TipJar")
}

# Функция первоначальной настройки:
function Invoke-SetupWizard {
	# Удаление файлов авторизации:
	if (!(Test-Path "$LoginFilePath")) {
		Clear-ActiveAccountFiles
	}
	
	# Запрос выбора языка:
	Separator
	$Language_Menu = @"
$(Get-Lang 'LanguageMenuTitle')
$(Get-Lang 'LanguageMenu1')
$(Get-Lang 'LanguageMenu2')`n
"@
	$LanguageChoice = Read-MenuChoice -MenuText $Language_Menu -OptionsCount 2
	$script:CurrentLang = if ($LanguageChoice -eq '1') { "RU" } else { "EN" }
	
	# Сохранение выбранного языка:
	Set-Setting -Key "Language" -Value $script:CurrentLang
	
	# Установка режима IPA_Downloader по умолчанию:
	$script:WorkMode = "Downloader"
	
	# Сохранение режима работы и вывод баннера:
	Set-Setting -Key "Mode" -Value $script:WorkMode
	Show-ModeBanner
	
	# Проверка обновлений:
	if (-not $script:UpdateChecked) {
		Check-Update
		$script:UpdateChecked = $true
	}
}

# Функция отображения текущей операционной системы и версии PowerShell:
function Show-SystemInfo {
	# Операционная система:
	Separator
	Write-Host "$OSVersion"
	
	# Версия PowerShell:
	Write-Host "PowerShell $PSVersion"
}

# Проверка наличия базовых папок:
foreach ($Dir in @("$AppsFolderPath", "$FilesFolderPath", "$MainAppFolderPath")) {
	if (!(Test-Path $Dir)) {
		$null = New-Item -Path $Dir -ItemType "Directory"
	}
}

# Переименование файлов старых версий скрипта:
Rename-Legacy-Files

# Создание пустого файла с пользовательским списком приложений (Files/AppsListCustom.txt):
Initialize-Custom-List-File

# Включение TLS 1.2 для совместимости со старыми версиями операционных систем:
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Удаление временных файлов при запуске:
Get-ChildItem -Path $PSScriptRoot -Filter "*.ipa.tmp" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $PSScriptRoot -Filter "*.ipa" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
if (Test-Path $AppsListTempPath) { Remove-Item $AppsListTempPath -Force -ErrorAction SilentlyContinue }
if (Test-Path $WarningTempPath) { Remove-Item $WarningTempPath -Force -ErrorAction SilentlyContinue }

# Функция режима IPA_Installer:
function Invoke-InstallerMode {
	# Удаление файлов авторизации:
	Clear-ActiveAccountFiles
	
	while ($true) {
		# Вывод меню IPA_Installer:
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
				Install-Apps
			}
			
			# 3. Банка для чаевых:
			"3" {
				Open-TipJar
			}
			
			# 4. Сменить язык (Change Language):
			"4" {
				$script:CurrentLang = if ($script:CurrentLang -eq "RU") { "EN" } else { "RU" }
				Set-Setting -Key "Language" -Value $script:CurrentLang
				Separator
				Write-Host (Get-Lang "LanguageChanged")
			}
			
			# 5. Перейти в IPA_Downloader:
			"5" {
				$script:WorkMode = "Downloader"
				return
			}
			
			# Режим отладки:
			"debug" {
				$script:IsDebugEnabled = -not $script:IsDebugEnabled
				Set-Setting -Key "DebugEnabled" -Value $script:IsDebugEnabled
				Separator
				if ($script:IsDebugEnabled) {
					Write-Host (Get-Lang "DebugEnabled")
				} else {
					Write-Host (Get-Lang "DebugDisabled")
				}
				continue
			}
			
			# Неверный ввод:
			default {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
}

# Функция запуска ipatool c флагами:
function Invoke-Ipatool {
	$IpatoolArgs = @($args)
	
	# Добавление флага --keychain-passphrase:
	$IpatoolArgs += "--keychain-passphrase", $script:Kp
	
	# Добавление флага --debug при включении режима отладки:
	if ($script:IsDebugEnabled) {
		$IpatoolArgs += "--debug"
	}
	
	# Запуск ipatool:
	& "$script:ipatoolFilePath" @IpatoolArgs
}

# Функция режима IPA_Downloader:
function Invoke-DownloaderMode {
	# Инициализация keychain-passphrase (только на Windows):
	if ($IsWin) {
		$KeychainFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "keychain-passphrase"
		
		if (Test-Path $KeychainFilePath) {
			$EncryptedContent = (Get-Content -Path $KeychainFilePath -Raw).Trim()
			$SecureKp = $EncryptedContent | ConvertTo-SecureString
			$script:Kp = [System.Net.NetworkCredential]::new("", $SecureKp).Password
		} else {
			# Формирование нового случайного ключа:
			$script:Kp = [guid]::NewGuid().ToString("N")
		}
	} else {
		# Формирование пустой keychain-passphrase для macOS, Linux:
		$script:Kp = ""
	}
	
	# Удаление файла login, если файл account отсутствует:
	if (!(Test-Path $AccountFilePath)) {
		Remove-Item -Path $LoginFilePath -Force -ErrorAction SilentlyContinue
	}
	
	# Проверка осуществленного входа с аккаунтом Apple:
	if (Test-Path "$LoginFilePath") {
		Get-Current-AppleAccount
	} else {
		while (!(Test-Path "$LoginFilePath")) {
			# Удаление файлов авторизации:
			Clear-ActiveAccountFiles
			
			# Вывод меню:
			Separator
			$LoginMenu = @"
$(Get-Lang 'MenuTitle')
$(Get-Lang 'LoginMenu1')
$(Get-Lang 'LoginMenu2')
$(Get-Lang 'LoginMenu3')`n
"@
			$LoginChoice = Read-Host $LoginMenu
			
			if ($LoginChoice -eq '1') {
				Connect-AppleAccount
			} elseif ($LoginChoice -eq '2') {
				$script:WorkMode = "Installer"
				Set-Setting -Key "Mode" -Value "Installer"
				return
			} elseif ($LoginChoice -eq '3') {
				$script:CurrentLang = if ($script:CurrentLang -eq "RU") { "EN" } else { "RU" }
				Set-Setting -Key "Language" -Value $script:CurrentLang
				Separator
				Write-Host (Get-Lang "LanguageChanged")
			} else {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
	
	# Сохранение настроек режима IPA_Downloader только после успешной авторизации с аккаунтом Apple:
	Set-Setting -Key "Language" -Value $script:CurrentLang
	Set-Setting -Key "Mode" -Value "Downloader"
	
	# Основной цикл:
	while (Test-Path "$LoginFilePath") {
		# Вывод данных текущего аккаунта Apple:
		Separator
		Write-Host (Get-Lang "AuthSuccess")
		Invoke-Ipatool auth info
		
		# Вывод меню IPA_Downloader:
		Separator
		$MainMenu = @"
$(Get-Lang 'MenuTitle')
$(Get-Lang 'DownloaderMenu1')
$(Get-Lang 'DownloaderMenu2')
$(Get-Lang 'DownloaderMenu3')
$(Get-Lang 'DownloaderMenu4')
$(Get-Lang 'DownloaderMenu5')
$(Get-Lang 'DownloaderMenu6')
$(Get-Lang 'DownloaderMenu7')
$(Get-Lang 'DownloaderMenu8')
$(Get-Lang 'DownloaderMenu9')
$(Get-Lang 'DownloaderMenu10')
$(Get-Lang 'DownloaderMenu11')
$(Get-Lang 'DownloaderMenu12')`n
"@
	
		$SwitchValue = Read-Host $MainMenu
		switch ($SwitchValue) {
			
			# 1. Поиск приложений по названию или ID и покупка (без загрузки):
			"1" {
				$AppsToProcess = Search-Apps -PromptKey 'AskAppNumPurchase'
				if ($null -ne $AppsToProcess) {
					$AppsTotal = @($AppsToProcess).Count
					$AppsCurrent = 0
					foreach ($App in $AppsToProcess) {
						$AppsCurrent++
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Display -Action "Purchase" -Current $AppsCurrent -Total $AppsTotal
					}
				}
			}
			
			# 2. Поиск приложений по названию или ID и загрузка последней версии:
			"2" {
				$AppsToProcess = Search-Apps -PromptKey 'AskAppNumDownload'
				if ($null -ne $AppsToProcess) {
					$AppsTotal = @($AppsToProcess).Count
					$AppsCurrent = 0
					foreach ($App in $AppsToProcess) {
						$AppsCurrent++
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Display -Action "Download" -Current $AppsCurrent -Total $AppsTotal
					}
				}
			}
			
			# 3. Поиск приложений по названию или ID и загрузка (с выбором версии):
			"3" {
				$AppsToProcess = Search-Apps -PromptKey 'AskAppNumDownload'
				if ($null -ne $AppsToProcess) {
					$AppsTotal = @($AppsToProcess).Count
					$AppsCurrent = 0
					foreach ($App in $AppsToProcess) {
						$AppsCurrent++
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Display -Action "DownloadVersion" -Current $AppsCurrent -Total $AppsTotal
					}
				}
			}
			
			# 4. Выбор списка приложений и покупка (без загрузки):
			"4" {
				Separator
				$SelectedApps = Get-Apps-From-List -ListMode "Purchase"
				if ($null -ne $SelectedApps) {
					$AppsTotal = @($SelectedApps).Count
					$AppsCurrent = 0
					foreach ($App in $SelectedApps) {
						$AppsCurrent++
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Purchase" -Current $AppsCurrent -Total $AppsTotal
					}
				}
			}
			
			# 5. Выбор списка приложений и загрузка последней версии:
			"5" {
				Separator
				$SelectedApps = Get-Apps-From-List -ListMode "Download"
				if ($null -ne $SelectedApps) {
					$AppsTotal = @($SelectedApps).Count
					$AppsCurrent = 0
					foreach ($App in $SelectedApps) {
						$AppsCurrent++
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "Download" -Current $AppsCurrent -Total $AppsTotal
					}
				}
			}
			
			# 6. Выбор списка приложений и загрузка (с выбором версии):
			"6" {
				Separator
				$SelectedApps = Get-Apps-From-List -ListMode "Download"
				if ($null -ne $SelectedApps) {
					$AppsTotal = @($SelectedApps).Count
					$AppsCurrent = 0
					foreach ($App in $SelectedApps) {
						$AppsCurrent++
						Invoke-AppAction -AppId $App.Id -AppName $App.Name -DisplayName $App.Name -Action "DownloadVersion" -Current $AppsCurrent -Total $AppsTotal
					}
				}
			}
			
			# 7. Проверка минимальной версии iOS для приложений в папке Apps:
			"7" {
				$null = Get-iOS-MinVersion
			}
			
			# 8. Установка приложений из папки Apps:
			"8" {
				Install-Apps
			}
			
			# 9. Очистка данных скрипта:
			"9" {
				Separator
				$ClearMenu = @"
$(Get-Lang 'ClearMenuTitle') $(Get-Lang 'CancelStep')
$(Get-Lang 'ClearMenu1')
$(Get-Lang 'ClearMenu2')
$(Get-Lang 'ClearMenu3')`n
"@
				$ClearChoice = Read-MenuChoice -MenuText $ClearMenu -OptionsCount 3 -AllowCancel
				
				if ($ClearChoice -eq '0') { continue }
				
				switch ($ClearChoice) {
					"1" {
						if (!(Test-Path "$PurchasedAppsListFilePath")) {
							Show-Error "ErrorPurchasedAppsListEmpty"
						} else {
							$RawData = Get-Content "$PurchasedAppsListFilePath" -Raw -Encoding UTF8
							
							# Очистка, если файл пуст или содержит только пустые скобки {}:
							if ([string]::IsNullOrWhiteSpace($RawData) -or $RawData.Trim() -eq '{}') {
								Remove-Item "$PurchasedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								Show-Error "ErrorPurchasedAppsListEmpty"
								continue
							}
							
							$Data = $RawData | ConvertFrom-Json
							
							# Очистка, если файл старого формата или без свойств:
							if ($Data -isnot [System.Management.Automation.PSCustomObject] -or $Data.psobject.properties.Count -eq 0) {
								Remove-Item "$PurchasedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "PurchasedAppsListCleared")
								continue
							}
							
							# Формирование динамического меню аккаунтов:
							$Accounts = @($Data.psobject.properties.Name)
							$AccountMenuText = "$(Get-Lang 'ClearAccountMenuTitle') $(Get-Lang 'CancelStep')`n"
							$Counter = 1
							foreach ($Account in $Accounts) {
								$AccountMenuText += "$Counter. $Account`n"
								$Counter++
							}
							$AccountMenuText += "$Counter. $(Get-Lang 'ClearAllAccounts')`n"
							
							Separator
							$AccountChoice = Read-MenuChoice -MenuText $AccountMenuText -OptionsCount $Counter -AllowCancel
							if ($AccountChoice -eq '0') { continue }
							
							if ([int]$AccountChoice -eq $Counter) {
								# Очистка, если выбрано "Все аккаунты":
								Remove-Item "$PurchasedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "PurchasedAppsListCleared")
							} else {
								# Удаление данных выбранного аккаунта:
								$SelectedAccount = $Accounts[[int]$AccountChoice - 1]
								
								# Удаление файла, если в файле отсутствуют аккаунты:
								if ($Accounts.Count -le 1) {
									Remove-Item "$PurchasedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								} else {
									$Data.psobject.properties.Remove($SelectedAccount)
									$Data | ConvertTo-Json -Depth 5 | Set-Content "$PurchasedAppsListFilePath" -Encoding UTF8
								}
								Separator
								Write-Host ((Get-Lang "AccountCleared") -f $SelectedAccount)
							}
						}
					}
					
					"2" {
						if (!(Test-Path "$DownloadedAppsListFilePath")) {
							Show-Error "ErrorDownloadedAppsListEmpty"
						} else {
							$RawData = Get-Content "$DownloadedAppsListFilePath" -Raw -Encoding UTF8
							
							if ([string]::IsNullOrWhiteSpace($RawData) -or $RawData.Trim() -eq '{}') {
								Remove-Item "$DownloadedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								Show-Error "ErrorDownloadedAppsListEmpty"
								continue
							}
							
							$Data = $RawData | ConvertFrom-Json
							
							if ($Data -isnot [System.Management.Automation.PSCustomObject] -or $Data.psobject.properties.Count -eq 0) {
								Remove-Item "$DownloadedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "DownloadedAppsListCleared")
								continue
							}
							
							$Accounts = @($Data.psobject.properties.Name)
							$AccountMenuText = "$(Get-Lang 'ClearAccountMenuTitle') $(Get-Lang 'CancelStep')`n"
							$Counter = 1
							foreach ($Account in $Accounts) {
								$AccountMenuText += "$Counter. $Account`n"
								$Counter++
							}
							$AccountMenuText += "$Counter. $(Get-Lang 'ClearAllAccounts')`n"
							
							Separator
							$AccountChoice = Read-MenuChoice -MenuText $AccountMenuText -OptionsCount $Counter -AllowCancel
							if ($AccountChoice -eq '0') { continue }
							
							if ([int]$AccountChoice -eq $Counter) {
								# Очистка, если выбрано "Все аккаунты":
								Remove-Item "$DownloadedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								Separator
								Write-Host (Get-Lang "DownloadedAppsListCleared")
							} else {
								# Удаление данных выбранного аккаунта:
								$SelectedAccount = $Accounts[[int]$AccountChoice - 1]
								
								# Удаление файла, если в файле отсутствуют аккаунты:
								if ($Accounts.Count -le 1) {
									Remove-Item "$DownloadedAppsListFilePath" -Force -ErrorAction SilentlyContinue
								} else {
									$Data.psobject.properties.Remove($SelectedAccount)
									$Data | ConvertTo-Json -Depth 5 | Set-Content "$DownloadedAppsListFilePath" -Encoding UTF8
								}
								Separator
								Write-Host ((Get-Lang "AccountCleared") -f $SelectedAccount)
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
			
			# 10. Операции с аккаунтом Apple:
			"10" {
				Invoke-AccountMenu
				# Выход из всех аккаунтов:
				if ($null -eq $script:WorkMode) {
					return
				}
			}
			
			# 11. Банка для чаевых:
			"11" {
				Open-TipJar
			}
			
			# 12. Сменить язык (Change Language):
			"12" {
				$script:CurrentLang = if ($script:CurrentLang -eq "RU") { "EN" } else { "RU" }
				Set-Setting -Key "Language" -Value $script:CurrentLang
				Separator
				Write-Host (Get-Lang "LanguageChanged")
			}
			
			# Режим отладки:
			"debug" {
				$script:IsDebugEnabled = -not $script:IsDebugEnabled
				Set-Setting -Key "DebugEnabled" -Value $script:IsDebugEnabled
				Separator
				if ($script:IsDebugEnabled) {
					Write-Host (Get-Lang "DebugEnabled")
				} else {
					Write-Host (Get-Lang "DebugDisabled")
				}
				continue
			}
			
			# Неверный ввод:
			default {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
}

# Главный рабочий цикл:
$script:UpdateChecked = $false
$script:RemoteFilesInitialized = $false
$script:DependenciesChecked = $false

while ($true) {
	
	# Вызов первоначальной настройки или баннера с проверкой обновлений:
	if ($null -eq $script:WorkMode) {
		Invoke-SetupWizard
	} else {
		Show-ModeBanner
		if (-not $script:UpdateChecked) {
			Check-Update
			$script:UpdateChecked = $true
		}
	}
	
	# Загрузка файлов из репозитория и вывод предупреждения:
	if (-not $script:RemoteFilesInitialized) {
		Initialize-RemoteFiles
		Show-WarningMsg
		$script:RemoteFilesInitialized = $true
	}
	
	# Проверка наличия необходимых файлов под текущую операционную систему и архитектуру:
	if (-not $script:DependenciesChecked) {
		$MissingFiles = Get-MissingBinaryFiles -FolderPath $script:BinaryFolderPath
		Check-RequiredFiles -MissingFiles $MissingFiles
		Set-IpatoolBinaryPaths -FolderPath $script:BinaryFolderPath
		
		# Поиск ideviceinstaller в системе (macOS и Linux):
		if (-not $IsWin) {
			$IdeviceCmd = Get-Command ideviceinstaller* -ErrorAction SilentlyContinue | Select-Object -First 1
			$script:ideviceinstallerFilePath = if ($IdeviceCmd) { $IdeviceCmd.Source } else { $null }
			
			if (-not $script:ideviceinstallerFilePath) {
				Show-Error "ErrorIdeviceinstallerNotFound"
			}
		}
		$script:DependenciesChecked = $true
	}
	
	# Запуск выбранного режима работы:
	if ($script:WorkMode -eq "Installer") {
		Invoke-InstallerMode
	} elseif ($script:WorkMode -eq "Downloader") {
		Invoke-DownloaderMode
	}
	
	# Обработка сброса режима работы:
	if ($null -eq $script:WorkMode) {
		continue
	}
}