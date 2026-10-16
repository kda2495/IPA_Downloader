# Переключение рабочей директории в папку со скриптом:
Set-Location -Path $PSScriptRoot

# Версия скрипта:
$ScriptVersion = "4.2.3"

# Переменная состояния keychain-passphrase:
$script:KeychainEnabled = $false

# Переменная состояния установки приложений по Wi-Fi:
$script:AirInstallEnabled = $false

# Виды покупок, отображаемые в списке приложений из истории покупок аккаунта Apple:
$script:AccountAppKinds = @("iOS App", "Mac App")

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
$script:KeychainEnabled = if ($SavedSettings['KeychainEnabled'] -in @('True', 'False')) { $SavedSettings['KeychainEnabled'] -eq 'True' } else { $script:KeychainEnabled }
$script:AirInstallEnabled = if ($SavedSettings['AirInstallEnabled'] -in @('True', 'False')) { $SavedSettings['AirInstallEnabled'] -eq 'True' } else { $script:AirInstallEnabled }

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
$PurchasedAppsListFilePath = Join-Path -Path $FilesFolderPath -ChildPath "PurchasedAppsList.json"
$AppsFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "Apps"
$ipatoolHomePath = Join-Path -Path $HOME -ChildPath ".ipatool"
$LoginFilePath = Join-Path -Path $ipatoolHomePath -ChildPath "login"
$AuthFileNames = @("account", "cookies", "login")
$TempFolderPath = [System.IO.Path]::GetTempPath()
$TempipaFilePath = Join-Path -Path $TempFolderPath -ChildPath "Temp.ipa"
$AppsListPath = Join-Path -Path $FilesFolderPath -ChildPath "AppsList.txt"
$AppsListCustomPath = Join-Path -Path $FilesFolderPath -ChildPath "AppsListCustom.txt"
$AppsListTempPath = Join-Path -Path $MainAppFolderPath -ChildPath "AppsList_tmp.txt"
$WarningPath = Join-Path -Path $FilesFolderPath -ChildPath "Warning.txt"
$WarningTempPath = Join-Path -Path $MainAppFolderPath -ChildPath "Warning_tmp.txt"

# Настройка консоли на Windows:
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
	chcp 65001 > $null
}

# Включение UTF-8 по умолчанию:
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Подключение системных сборок для работы с zip-архивами:
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Определение переменной для кэширования списка популярных приложений (Files/AppsList.txt):
$script:RepoParsedList = $null

# Локализация:
$LangStrings = @{
	"RU" = @{
		"AccountAppsListLoad" = "Загрузка списка приложений из истории покупок аккаунта Apple.`nЭто может занять некоторое время..."
		"AccountAppsListMenu" = "2. Список приложений из истории покупок аккаунта Apple (Files/AppsListAccount_.txt)"
		"AccountAppsListUpdate" = "Обновление списка приложений из истории покупок аккаунта Apple (с {0} года).`nЭто может занять некоторое время..."
		"AccountCleared" = "Готово. Данные аккаунта {0} удалены."
		"AccountCurrent" = "(текущий)"
		"AccountLoggedOut" = "Выполнен выход из аккаунта Apple: {0}"
		"AccountLogoutMenuTitle" = "Выберите аккаунт Apple для выхода"
		"AccountMenu1" = "1. Добавить аккаунт"
		"AccountMenu2" = "2. Сменить аккаунт"
		"AccountMenu3" = "3. Выйти из аккаунта Apple"
		"AccountMenuTitle" = "Операции с аккаунтом Apple"
		"AccountSwitchMenuTitle" = "Выберите аккаунт Apple для перехода"
		"AirInstallEnabled" = "Установка приложений по Wi-Fi включена."
		"AirInstallDisabled" = "Установка приложений по Wi-Fi отключена."
		"AppsCleared" = "Готово. Приложения в папке Apps удалены."
		"AskAppNumDownload" = "Введите порядковые номера (№) приложений для загрузки"
		"AskAppNumPurchase" = "Введите порядковые номера (№) приложений для покупки"
		"AskAppSearch" = "Введите название приложения или ID приложений"
		"AskDeviceNum" = "Введите порядковые номера (№) устройств для установки"
		"AskFileNum" = "Введите порядковые номера (№) файлов для установки"
		"AskVersionsDownloadNum" = "Введите порядковые номера (№) версий для загрузки"
		"AskVersionsListNum" = "Введите порядковые номера (№) ID версий или ID версий для отображения версий"
		"AuthFail" = "Вход в аккаунт Apple не выполнен."
		"AuthSuccess" = "Вход в аккаунт Apple выполнен.`nДанные аккаунта:"
		"BatchHintDownload" = "Доступна загрузка нескольких приложений, например, при вводе: 1, 2 и/или 3-5."
		"BatchHintInstallApps" = "Доступна установка нескольких приложений, например, при вводе: 1, 2 и/или 3-5."
		"BatchHintInstallDevices" = "Доступна установка на несколько устройств, например, при вводе: 1, 2 и/или 3-5."
		"BatchHintPurchase" = "Доступна покупка нескольких приложений, например, при вводе: 1, 2 и/или 3-5."
		"BatchHintVersionIDs" = "Доступен выбор нескольких ID версий приложения, например, при вводе: 1, 2 и/или 3-5."
		"BatchHintVersions" = "Доступна загрузка нескольких версий приложения, например, при вводе: 1, 2 и/или 3-5."
		"CancelStep" = "(0: Возврат в главное меню):"
		"CancelStepVerID" = "(0: Возврат к вводу порядковых номеров (№) или ID версий):"
		"ClearAccountMenuTitle" = "Выберите аккаунт Apple для очистки"
		"ClearAllAccounts" = "Все аккаунты Apple"
		"ClearMenu1" = "1. Список приложений, приобретенных скриптом (Files/PurchasedAppsList.json)"
		"ClearMenu2" = "2. Приложения в папке Apps"
		"ClearMenuTitle" = "Выберите данные для очистки"
		"CustomAppsListMenu" = "3. Пользовательский список приложений (Files/AppsListCustom.txt)"
		"DebugEnabled" = "Режим отладки включен."
		"DebugDisabled" = "Режим отладки отключен."
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
		"ErrorAppsListAccountLoad" = "Ошибка: Не удалось получить список приложений из истории покупок аккаунта Apple."
		"ErrorAppsListAccountUpdate" = "Ошибка: Не удалось обновить список приложений из истории покупок аккаунта Apple.`nПоказан ранее сохраненный список."
		"ErrorAppsListCustomEmpty" = "Ошибка: Пользовательский список приложений пуст.`nДобавьте приложения в Files/AppsListCustom.txt"
		"ErrorAppsListLoad" = "Ошибка: Не удалось загрузить список приложений."
		"ErrorAuthCheck" = "Ошибка: Не удалось подтвердить вход в аккаунт Apple."
		"ErrorDeviceOSVersionTooLow" = "Ошибка: Версия iOS на устройстве ({0}) ниже минимальной версии iOS приложения ({1})."
		"ErrorDownloadFiles" = "Ошибка: Не удалось загрузить файл:"
		"ErrorideviceidNotFound" = "Ошибка: idevice_id не найден.`nПоиск подключенных устройств невозможен."
		"ErrorideviceinstallerNotFound" = "Ошибка: ideviceinstaller не найден.`nУстановка приложений невозможна (только по AirDrop на macOS)."
		"ErrorInstallipa" = "Ошибка: Не удалось установить/обновить приложение."
		"ErrorInvalidInput" = "Ошибка: Неверный ввод."
		"ErrorMissingFiles" = "Ошибка: Следующие файлы не найдены:"
		"ErrorNoApps" = "Ошибка: В папке Apps отсутствуют приложения."
		"ErrorNoAppsFound" = "Ошибка: Приложения не найдены."
		"ErrorNoDevices" = "Ошибка: Подключенные устройства не найдены.`nПодключите устройство и подтвердите доверие компьютеру."
		"ErrorNoOtherAccounts" = "Ошибка: Других аккаунтов Apple не найдено."
		"ErrorNoVersionsFound" = "Ошибка: Версии приложения не найдены."
		"ErrorOpenUrl" = "Ошибка: Не удалось открыть страницу."
		"ErrorPurchasedAppsListEmpty" = "Ошибка: Список приложений, приобретенных скриптом (Files/PurchasedAppsList.json), пуст."
		"ErrorUpdateCheck" = "Ошибка: Не удалось проверить наличие обновлений."
		"FileName" = "Имя файла:"
		"FileSaved" = "Готово. Файл сохранен в папку Apps."
		"HeaderAppID" = "ID:"
		"HeaderAppName" = "Название:"
		"HeaderDeviceiOS" = "Версия iOS:"
		"HeaderDeviceName" = "Имя устройства:"
		"HeaderKind" = "Вид:"
		"HeaderMinIOS" = "Мин. версия iOS:"
		"HeaderMinPlatformVersion" = "Мин. версия {0}:"
		"HeaderNum" = "№"
		"HeaderPurchaseDate" = "Дата покупки:"
		"HeaderUDID" = "UDID:"
		"HeaderVersion" = "Версия:"
		"HeaderVersionID" = "ID версии:"
		"InstallApp" = "Установка:"
		"InstallDevice" = "Устройство:"
		"InstallerMenu1" = "1. Проверка минимальной версии iOS для приложений в папке Apps"
		"InstallerMenu2" = "2. Установка приложений из папки Apps"
		"InstallerMenu3" = "3. Банка для чаевых"
		"InstallerMenu4" = "4. Сменить язык (Change Language)"
		"InstallerMenu5" = "5. Перейти в IPA_Downloader"
		"KbSyncGeneration" = "Формирование kbsync. Это может занять некоторое время..."
		"LanguageChanged" = "Язык успешно изменен на русский."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"Link" = "Ссылка:"
		"ListMenuTitle" = "Выберите список для отображения"
		"LoadingVersionsIDList" = "Загрузка списка ID версий приложения..."
		"LoggedOut" = "Выполнен выход из аккаунта Apple."
		"LoginMenu1" = "1. Войти в аккаунт Apple"
		"LoginMenu2" = "2. Перейти в режим IPA_Installer"
		"LoginMenu3" = "3. Сменить язык (Change Language)"
		"LogoutAllAccounts" = "Выйти из всех аккаунтов Apple и сбросить настройки скрипта"
		"MenuTitle" = "Введите команду:"
		"MinPlatformVersion" = "Минимальная версия {0} для установки:"
		"NotPurchasedAppsListMenu" = "2. Список популярных приложений, не приобретенных скриптом"
		"PopularAppsListMenu" = "1. Список популярных приложений (Files/AppsList.txt)"
		"PurchasedAppsListCleared" = "Готово. Список приложений, приобретенных скриптом (Files/PurchasedAppsList.json), очищен."
		"SelectedApp" = "Выбрано приложение:"
		"SelectedVersion" = "Выбрана версия:"
		"SelectedVersionsList" = "Выбраны следующие версии:"
		"TipJar" = "Спасибо за поддержку!"
		"UpdateAvailableTitle" = "Доступно обновление (версия {0}). Перейти на страницу репозитория для загрузки обновления?"
		"UpdateMenu1" = "1. Да"
		"UpdateMenu2" = "2. Нет"
	}
	"EN" = @{
		"AccountAppsListLoad" = "Loading the list of apps from the Apple account's purchase history.`nThis may take some time..."
		"AccountAppsListMenu" = "2. List of apps from the Apple account purchase history (Files/AppsListAccount_.txt)"
		"AccountAppsListUpdate" = "Updating the list of apps from the Apple account purchase history (since {0}).`nThis may take some time..."
		"AccountCleared" = "Done. Account {0} data cleared."
		"AccountCurrent" = "(current)"
		"AccountLoggedOut" = "Successfully logged out of Apple account: {0}"
		"AccountLogoutMenuTitle" = "Select Apple account to log out of"
		"AccountMenu1" = "1. Add account"
		"AccountMenu2" = "2. Switch account"
		"AccountMenu3" = "3. Log out of Apple account"
		"AccountMenuTitle" = "Apple account operations"
		"AccountSwitchMenuTitle" = "Select Apple account to switch to"
		"AirInstallEnabled" = "Installing apps via Wi-Fi enabled."
		"AirInstallDisabled" = "Installing apps via Wi-Fi disabled."
		"AppsCleared" = "Done. Apps folder has been cleared."
		"AskAppNumDownload" = "Enter index numbers (#) of apps to download"
		"AskAppNumPurchase" = "Enter index numbers (#) of apps to purchase"
		"AskAppSearch" = "Enter app name or app IDs"
		"AskDeviceNum" = "Enter index numbers (#) of devices to install on"
		"AskFileNum" = "Enter index numbers (#) of files to install"
		"AskVersionsDownloadNum" = "Enter index numbers (#) of app versions to download"
		"AskVersionsListNum" = "Enter index numbers (#) of version IDs or version IDs to display app versions"
		"AuthFail" = "Not authenticated with Apple account."
		"AuthSuccess" = "Apple account login successful.`nAccount details:"
		"BatchHintDownload" = "Downloading multiple apps is available, for example, by entering: 1, 2 and/or 3-5."
		"BatchHintInstallApps" = "Installing multiple apps is available, for example, by entering: 1, 2 and/or 3-5."
		"BatchHintInstallDevices" = "Installing on multiple devices is available, for example, by entering: 1, 2 and/or 3-5."
		"BatchHintPurchase" = "Purchasing multiple apps is available, for example, by entering: 1, 2 and/or 3-5."
		"BatchHintVersionIDs" = "Selecting multiple app version IDs is available, for example, by entering: 1, 2 and/or 3-5."
		"BatchHintVersions" = "Downloading multiple app versions is available, for example, by entering: 1, 2 and/or 3-5."
		"CancelStep" = "(0: Return to main menu):"
		"CancelStepVerID" = "(0: Return to entering index numbers (#) or version IDs):"
		"ClearAccountMenuTitle" = "Select Apple account to clear"
		"ClearAllAccounts" = "All Apple accounts"
		"ClearMenu1" = "1. List of apps purchased by the script (Files/PurchasedAppsList.json)"
		"ClearMenu2" = "2. Apps in Apps folder"
		"ClearMenuTitle" = "Select data to clear"
		"CustomAppsListMenu" = "3. Custom apps list (Files/AppsListCustom.txt)"
		"DebugEnabled" = "Debug mode enabled."
		"DebugDisabled" = "Debug mode disabled."
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
		"ErrorAppsListAccountLoad" = "Error: Failed to retrieve list of apps from the Apple account purchase history."
		"ErrorAppsListAccountUpdate" = "Error: Failed to update the list of apps from the Apple account purchase history.`nShowing the previously saved list."
		"ErrorAppsListCustomEmpty" = "Error: Custom apps list is empty.`nAdd apps to the Files/AppsListCustom.txt file."
		"ErrorAppsListLoad" = "Error: Failed to load apps list."
		"ErrorAuthCheck" = "Error: Failed to verify the Apple account login."
		"ErrorDeviceOSVersionTooLow" = "Error: The iOS version on the device ({0}) is lower than the minimum iOS version required by the app ({1})."
		"ErrorDownloadFiles" = "Error: Failed to download file:"
		"ErrorideviceidNotFound" = "Error: idevice_id not found.`nScanning connected devices is impossible."
		"ErrorideviceinstallerNotFound" = "Error: ideviceinstaller not found.`nInstalling apps is impossible (only via AirDrop on macOS)."
		"ErrorInstallipa" = "Error: Failed to install/upgrade the app."
		"ErrorInvalidInput" = "Error: Invalid input."
		"ErrorMissingFiles" = "Error: Following files were not found:"
		"ErrorNoApps" = "Error: No apps found in Apps folder."
		"ErrorNoAppsFound" = "Error: No apps found."
		"ErrorNoDevices" = "Error: No connected devices found.`nConnect a device and trust this computer."
		"ErrorNoOtherAccounts" = "Error: No other Apple accounts found."
		"ErrorNoVersionsFound" = "Error: No app versions found."
		"ErrorOpenUrl" = "Error: Failed to open the page."
		"ErrorPurchasedAppsListEmpty" = "Error: List of apps purchased by the script (Files/PurchasedAppsList.json) is empty."
		"ErrorUpdateCheck" = "Error: Failed to check for updates."
		"FileName" = "File name:"
		"FileSaved" = "Done. File saved to Apps folder."
		"HeaderAppID" = "ID:"
		"HeaderAppName" = "Name:"
		"HeaderDeviceiOS" = "iOS version:"
		"HeaderDeviceName" = "Device Name:"
		"HeaderKind" = "Kind:"
		"HeaderMinIOS" = "Min. iOS version:"
		"HeaderMinPlatformVersion" = "Min. {0} version:"
		"HeaderNum" = "#"
		"HeaderPurchaseDate" = "Purchase date:"
		"HeaderUDID" = "UDID:"
		"HeaderVersion" = "Version:"
		"HeaderVersionID" = "Version ID:"
		"InstallApp" = "Installing:"
		"InstallDevice" = "Device:"
		"InstallerMenu1" = "1. Check the minimum iOS version for apps in the Apps folder"
		"InstallerMenu2" = "2. Install apps from Apps folder"
		"InstallerMenu3" = "3. Tip Jar"
		"InstallerMenu4" = "4. Change Language (Сменить язык)"
		"InstallerMenu5" = "5. Switch to IPA_Downloader"
		"KbSyncGeneration" = "Generation of kbsync. This may take some time..."
		"LanguageChanged" = "Language successfully changed to English."
		"LanguageMenu1" = "1. Русский"
		"LanguageMenu2" = "2. English"
		"LanguageMenuTitle" = "Выберите язык (Select language):"
		"Link" = "Link:"
		"ListMenuTitle" = "Select list to display"
		"LoadingVersionsIDList" = "Loading list of app version IDs..."
		"LoggedOut" = "Successfully logged out of Apple account."
		"LoginMenu1" = "1. Log in to Apple account"
		"LoginMenu2" = "2. Switch to IPA_Installer mode"
		"LoginMenu3" = "3. Change Language (Сменить язык)"
		"LogoutAllAccounts" = "Log out of all Apple accounts and reset script settings"
		"MenuTitle" = "Enter a command:"
		"MinPlatformVersion" = "Minimum {0} version required to install:"
		"NotPurchasedAppsListMenu" = "2. List of popular apps not purchased by the script"
		"PopularAppsListMenu" = "1. Popular apps list (Files/AppsList.txt)"
		"PurchasedAppsListCleared" = "Done. List of apps purchased by the script (Files/PurchasedAppsList.json) cleared."
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
$script:reSurrogates = New-Object System.Text.RegularExpressions.Regex('[\uD800-\uDBFF][\uDC00-\uDFFF]', 'Compiled')
$script:reUnsafe = New-Object System.Text.RegularExpressions.Regex('[^\u0020-\u007E\u00A0-\u017F\u0400-\u045F\u0490\u0491\u2013\u2014\u2018-\u201E\u2022\u2026\u2116\u20AC\u2122]', 'Compiled')

# Определение консоли Windows 7, 8 и 8.1:
$script:LegacyConsole = $IsWin -and ([Environment]::OSVersion.Version.Major -lt 10)

# Функция вывода данных в виде таблицы:
function Out-Table {
	param (
		[array]$Data,
		[Parameter(Mandatory = $true)][string[]]$Headers,
		[Parameter(Mandatory = $true)][string[]]$Properties
	)
	
	if (-not $Data -or $Data.Count -eq 0) { return }
	
	# Очистка и измерение ячеек:
	function Get-CellInfo([string]$Text) {
		if ([string]::IsNullOrEmpty($Text)) { return @{ Text = ""; Width = 0 } }
		
		# Замена текста для корректного отображения:
		$CleanText = $script:reANSI.Replace($Text, '')
		$CleanText = $script:reSpaces.Replace($CleanText, ' ')
		$CleanText = $script:reDashes.Replace($CleanText, '-')
		$CleanText = $script:reHidden.Replace($CleanText, '')
		$CleanText = $CleanText.Normalize([System.Text.NormalizationForm]::FormC)
		
		# Замена знаков, которые не отображаются в консоли Windows 7, 8 и 8.1, на знак "?":
		if ($script:LegacyConsole) {
			$CleanText = $script:reSurrogates.Replace($CleanText, '?')
			$CleanText = $script:reUnsafe.Replace($CleanText, '?')
		}
		
		# Расчет ширины:
		$VisualWidth = $CleanText.Length + $script:reWide.Matches($CleanText).Count
		
		return @{ Text = $CleanText; Width = $VisualWidth }
	}
	
	# Определение количества колонок:
	$ColumnCount = $Properties.Count
	
	# Обработка заголовков таблицы:
	$CleanHeaders = @()
	$ColWidths = New-Object 'int[]' $ColumnCount
	for ($ColumnIndex = 0; $ColumnIndex -lt $ColumnCount; $ColumnIndex++) {
		$HeaderText = if ($ColumnIndex -lt $Headers.Count) { "$($Headers[$ColumnIndex])" } else { "" }
		$HeaderInfo = Get-CellInfo $HeaderText
		$CleanHeaders += , $HeaderInfo
		$ColWidths[$ColumnIndex] = $HeaderInfo.Width
	}
	
	# Обработка данных:
	$CleanRows = @()
	foreach ($Row in $Data) {
		$Cells = @()
		for ($ColumnIndex = 0; $ColumnIndex -lt $Properties.Count; $ColumnIndex++) {
			$CellInfo = Get-CellInfo "$($Row.($Properties[$ColumnIndex]))"
			
			# Обновление ширины колонки:
			if ($CellInfo.Width -gt $ColWidths[$ColumnIndex]) {
				$ColWidths[$ColumnIndex] = $CellInfo.Width
			}
			$Cells += $CellInfo
		}
		# Добавление массива ячеек:
		$CleanRows += , $Cells 
	}
	
	# Формирование элементов рамок:
	$TopParts = @(); $SepParts = @(); $BottomParts = @()
	foreach ($ColWidth in $ColWidths) {
		$BorderLine = "─" * ($ColWidth + 2)
		$TopParts += $BorderLine; $SepParts += $BorderLine; $BottomParts += $BorderLine
	}
	
	$LineTop = "┌" + ($TopParts -join "┬") + "┐"
	$LineSep = "├" + ($SepParts -join "┼") + "┤"
	$LineBottom = "└" + ($BottomParts -join "┴") + "┘"
	
	# Сборка готовой строки:
	function Build-Row($CellsInfo) {
		$FormattedCells = for ($ColumnIndex = 0; $ColumnIndex -lt $CellsInfo.Count; $ColumnIndex++) {
			$Cell = $CellsInfo[$ColumnIndex]
			$PadCount = [Math]::Max(0, $ColWidths[$ColumnIndex] - $Cell.Width)
			" " + $Cell.Text + (" " * $PadCount) + " "
		}
		return "│" + ($FormattedCells -join "│") + "│"
	}
	
	# Итоговый вывод:
	Write-Host $LineTop
	Write-Host (Build-Row $CleanHeaders)
	Write-Host $LineSep
	
	for ($RowIndex = 0; $RowIndex -lt $CleanRows.Count; $RowIndex++) {
		Write-Host (Build-Row $CleanRows[$RowIndex])
	}
	
	Write-Host $LineBottom
}

# Функция ограничения длины текста в таблицах:
function Get-ShortText {
	param ([string]$Text)
	
	$TextInfo = [System.Globalization.StringInfo]::new($Text)
	if ($TextInfo.LengthInTextElements -gt 40) {
		return $TextInfo.SubstringByTextElements(0, 39) + "…"
	}
	
	return $Text
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
	# Запрос данных аккаунта:
	$AuthInfo = Invoke-ipatool auth info 2>$null | Out-String
	
	# Проверка успешной авторизации через ipatool auth info:
	$script:AuthSuccess = ($script:reANSI.Replace($AuthInfo, '') -match 'success=true')
	
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
	param ([string]$AppID)
	$RepoName = Get-Repo-AppName -AppID $AppID
	return @{
		Display = if ([string]::IsNullOrWhiteSpace($RepoName)) { $AppID } else { $RepoName }
		Final = if ([string]::IsNullOrWhiteSpace($RepoName)) { "Unknown" } else { $RepoName }
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
		Invoke-ipatool auth login
		
		# Авторизация пройдена:
		if ($LASTEXITCODE -eq 0) {
			# Создание пустого файла login для фиксации успешной авторизации:
			New-Item -Path $LoginFilePath -ItemType File -Force | Out-Null
			
			# Формирование kbsync:
			Separator
			Write-Host (Get-Lang "KbSyncGeneration")
			$null = Invoke-ipatool kbsync --refresh
			
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

# Функция восстановления сохраненного аккаунта при запуске:
function Restore-SavedAppleAccountAtStartup {
	while (@(Get-SavedAppleAccounts).Count -gt 0) {
		# Выбор сохраненного аккаунта:
		Select-AppleAccount
		
		# Продолжение работы, если авторизация выбранного аккаунта успешна:
		if ((Test-Path "$LoginFilePath") -and $script:AuthSuccess) {
			return $true
		}
		
		# Удаление файлов авторизации, если проверка авторизации не пройдена:
		if (Test-Path "$LoginFilePath") {
			Show-Error "ErrorAuthCheck"
			Clear-ActiveAccountFiles
			continue
		}
		
		# Сохранение файлов авторизации для следующего запуска:
		return $false
	}
	
	return $false
}

# Функция обработки проблем с авторизацией:
function Resolve-AppleAuthProblem {
	while ($true) {
		Show-Error "ErrorAuthCheck"
		
		# Удаление файлов авторизации нерабочего аккаунта:
		Clear-ActiveAccountFiles
		
		# Возврат к входу в аккаунт Apple, если других аккаунтов нет:
		if (@(Get-SavedAppleAccounts).Count -eq 0) { return }
		
		# Выбор другого аккаунта и проверка авторизации:
		Select-AppleAccount
		if ((Test-Path "$LoginFilePath") -and $script:AuthSuccess) { return }
	}
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
	Invoke-ipatool auth revoke
	
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
		Invoke-ipatool auth revoke
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

# Функция преобразования названия платформы из Info.plist в название для имени файла:
function ConvertTo-PlatformName {
	param ([string]$Name)
	
	$PlatformNames = @{
		iphoneos = "iOS"
		appletvos = "tvOS"
		macosx = "macOS"
		watchos = "watchOS"
		xros = "visionOS"
	}
	
	$PlatformKey = $Name.Trim().ToLower()
	if ($PlatformNames.ContainsKey($PlatformKey)) {
		return $PlatformNames[$PlatformKey]
	}
	
	return $null
}

# Функция извлечения метаданных из ipa:
function Get-IPA-Metadata {
	param ([string]$ipaPath)
	if (!(Test-Path $ipaPath)) { return $null }
	
	$Metadata = [PSCustomObject]@{
		AppName = "App"
		Version = "0"
		MinIOS = "NA"
		Platform = "iOS"
	}
	
	try {
		$Zip = [System.IO.Compression.ZipFile]::OpenRead($ipaPath)
		$PlistEntry = $Zip.Entries | Where-Object { $_.FullName -match '^Payload/[^/]+\.app/Info\.plist$' } | Select-Object -First 1
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
			
			# Название платформы берется из DTPlatformName, при его отсутствии из CFBundleSupportedPlatforms:
			$PlatformValue = $null
			if ($Content -match '<key>DTPlatformName</key>\s*<string>([^<]+)</string>') {
				$PlatformValue = $Matches[1]
			} elseif ($Content -match '<key>CFBundleSupportedPlatforms</key>\s*<array>\s*<string>([^<]+)</string>') {
				$PlatformValue = $Matches[1]
			}
			
			if ($PlatformValue) {
				$PlatformName = ConvertTo-PlatformName -Name $PlatformValue
				if ($PlatformName) {
					$Metadata.Platform = $PlatformName
				}
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

# Функция инициализации и кэширования списка популярных приложений (Files/AppsList.txt):
function Initialize-Repo-List {
	if ($null -ne $script:RepoParsedList) {
		return
	}
	
	# Чтение локального файла:
	$script:RepoParsedList = @(Read-AppsListFile -FilePath $AppsListPath)
}

# Функция переименования файлов старых версий скрипта в папке Files:
function Rename-Legacy-Files {
	$LegacyFiles = @(
		[PSCustomObject]@{ OldName = "Apps_ID_List.txt"; NewPath = $AppsListPath }
		[PSCustomObject]@{ OldName = "Purchased_IDs.json"; NewPath = $PurchasedAppsListFilePath }
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

# Функция чтения и парсинга файла со списком приложений (Files/AppsList.txt, Files/AppsListCustom.txt, Files/AppsListAccount_.txt):
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
			# Разбор строки в формате: Название: ID Вид Дата покупки:
			$LineMatch = [regex]::Match($Line, '^(.*):\s*(\d+)(?:[ \t]+([^\d\s][^\r\n]*?))?(?:[ \t]+(\d{1,2}\.\d{1,2}\.\d{4}))?\s*$')
			
			# Разбор строк с произвольным текстом после ID:
			if (!$LineMatch.Success) {
				$LineMatch = [regex]::Match($Line, '^(.*?):\s*(\d+)')
			}
			
			if ($LineMatch.Success) {
				$Result += [PSCustomObject]@{
					Name = $LineMatch.Groups[1].Value.Trim()
					ID = $LineMatch.Groups[2].Value.Trim()
					Kind = $LineMatch.Groups[3].Value.Trim()
					PurchaseDate = $LineMatch.Groups[4].Value
				}
			}
		}
	}
	catch {
	}
	
	return $Result
}

# Функция удаления дублей приложений по ID с сохранением исходного порядка:
function Remove-Duplicate-IDs {
	param ([array]$Items)
	
	$SeenIDs = @{}
	$Result = @()
	
	foreach ($Item in $Items) {
		$Key = "$($Item.ID)"
		if (-not $SeenIDs.ContainsKey($Key)) {
			$SeenIDs[$Key] = $true
			$Result += $Item
		}
	}
	
	return $Result
}

# Функция получения пользовательского списка приложений (Files/AppsListCustom.txt):
function Get-Custom-List {
	Initialize-Custom-List-File
	
	# Игнорирование вида приложения и даты покупки в пользовательском списке приложений:
	$List = @(Read-AppsListFile -FilePath $AppsListCustomPath | ForEach-Object {
		[PSCustomObject]@{
			Name = $_.Name
			ID = $_.ID
		}
	})
	
	# Удаление дублей приложений по ID внутри пользовательского списка приложений (Files/AppsListCustom.txt):
	return @(Remove-Duplicate-IDs -Items $List)
}

# Функция получения пути к списку приложений из истории покупок аккаунта Apple (Files/AppsListAccount_.txt):
function Get-Account-List-Path {
	$SafeAccountName = $script:CurrentAppleAccount -replace '[\\/:*?"<>|]', '_'
	return Join-Path -Path $FilesFolderPath -ChildPath "AppsListAccount_${SafeAccountName}.txt"
}

# Функция нормализации названия приложения из истории покупок аккаунта Apple:
function ConvertTo-Account-AppName {
	param ([string]$Name)
	
	$RtlPattern = '[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFE]'
	
	$CleanName = [string]$Name
	$CleanName = $CleanName -replace '[\r\n]+', ' '
	$CleanName = $script:reHidden.Replace($CleanName, '')
	
	# Удаление текста справа налево, пустых скобок и разделителей вокруг него:
	if ($CleanName -match $RtlPattern) {
		$CleanName = $CleanName -replace $RtlPattern, ''
		$CleanName = $CleanName -replace '\(\s*\)|\[\s*\]|\{\s*\}|«\s*»|"\s*"', ''
		$CleanName = $CleanName -replace '^[\s|¦‖\-–—:]+|[\s|¦‖\-–—:]+$', ''
	}
	
	$CleanName = $CleanName -replace '^\s*[|¦‖]+\s*|\s*[|¦‖]+\s*$', ''
	$CleanName = $CleanName -replace '\s{2,}', ' '
	$CleanName = $CleanName.Trim()
	
	# Название только из удаленных символов:
	if ([string]::IsNullOrWhiteSpace($CleanName)) {
		return "Unknown"
	}
	
	return $CleanName
}

# Функция преобразования формата даты покупки:
function Convert-PurchaseDate {
	param ([string]$DateText)
	
	$MonthNumbers = @{ Jan = 1; Feb = 2; Mar = 3; Apr = 4; May = 5; Jun = 6; Jul = 7; Aug = 8; Sep = 9; Oct = 10; Nov = 11; Dec = 12 }
	
	$DateDay = $null
	$DateMonthName = $null
	$DateYear = $null
	
	if ($DateText -match '([A-Za-z]{3})[A-Za-z]*\.?\s+(\d{1,2})\D+?(\d{4})') {
		# Формат даты в аккаунтах США:
		$DateMonthName = $Matches[1]
		$DateDay = [int]$Matches[2]
		$DateYear = $Matches[3]
	} elseif ($DateText -match '(\d{1,2})\D+?([A-Za-z]{3})[A-Za-z]*\D*?(\d{4})') {
		# Формат даты в других аккаунтах:
		$DateDay = [int]$Matches[1]
		$DateMonthName = $Matches[2]
		$DateYear = $Matches[3]
	}
	
	if ($null -ne $DateMonthName -and $MonthNumbers.ContainsKey($DateMonthName)) {
		return ("{0:D2}.{1:D2}.{2}" -f $DateDay, [int]$MonthNumbers[$DateMonthName], $DateYear)
	}
	
	return $DateText
}

# Функция получения числового ключа даты покупки:
function Get-PurchaseDateKey {
	param ([string]$DateText)
	
	if ($DateText -match '^(\d{1,2})\.(\d{1,2})\.(\d{4})$') {
		return (([int]$Matches[3] * 10000) + ([int]$Matches[2] * 100) + [int]$Matches[1])
	}
	
	return 0
}

# Функция запроса списка приложений из истории покупок аккаунта Apple (Files/AppsListAccount_.txt):
function Get-Purchased-Apps {
	param ([string[]]$ListArgs)
	
	$CommandOutput = Invoke-ipatool list-purchases @ListArgs | Out-String
	$AppsMatch = [System.Text.RegularExpressions.Regex]::Match($CommandOutput, '(?m)\bapps=(\[.*\])')
	if (!$AppsMatch.Success) {
		return [PSCustomObject]@{ Success = $false; Output = $CommandOutput; Apps = @() }
	}
	
	try {
		$Apps = @($AppsMatch.Groups[1].Value | ConvertFrom-Json -ErrorAction Stop | ForEach-Object { $_ })
	} catch {
		return [PSCustomObject]@{ Success = $false; Output = ""; Apps = @() }
	}
	
	# Отбор покупок с видом iOS App и Mac App:
	$Apps = @(
		$Apps |
			Where-Object { ![string]::IsNullOrWhiteSpace([string]$_.id) -and ([string]$_.kind).Trim() -in $script:AccountAppKinds }
	)
	
	# Порядок вывода списка приложений из истории покупок аккаунта Apple:
	[array]::Reverse($Apps)
	
	$Result = @()
	foreach ($App in $Apps) {
		$Result += [PSCustomObject]@{
			Name = ConvertTo-Account-AppName -Name ([string]$App.name)
			ID = [string]$App.id
			Kind = ([string]$App.kind).Trim()
			PurchaseDate = Convert-PurchaseDate -DateText ([string]$App.purchaseDate)
		}
	}
	
	return [PSCustomObject]@{ Success = $true; Output = $CommandOutput; Apps = $Result }
}

# Функция сортировки списка приложений из истории покупок аккаунта Apple (Files/AppsListAccount_.txt) по дате покупки:
function Sort-Apps-By-Date {
	param ([array]$Apps)
	
	if ($Apps.Count -eq 0) {
		return @()
	}
	
	$Keyed = @()
	for ($i = 0; $i -lt $Apps.Count; $i++) {
		$Keyed += [PSCustomObject]@{
			Key = (Get-PurchaseDateKey -DateText ([string]$Apps[$i].PurchaseDate))
			Index = $i
			App = $Apps[$i]
		}
	}
	
	return @($Keyed | Sort-Object -Property Key, Index | ForEach-Object { $_.App })
}

# Функция сохранения списка приложений из истории покупок аккаунта Apple (Files/AppsListAccount_.txt):
function Save-Account-List {
	param (
		[string]$FilePath,
		[array]$Apps
	)
	
	if ($Apps.Count -eq 0) {
		return
	}
	
	$Lines = @()
	foreach ($App in $Apps) {
		$AppName = ConvertTo-Account-AppName -Name ([string]$App.Name)
		$LineParts = @($App.ID, $App.Kind, $App.PurchaseDate) | Where-Object { ![string]::IsNullOrWhiteSpace([string]$_) }
		$Lines += "${AppName}: $($LineParts -join ' ')"
	}
	
	# Запись во временный файл и замена основного файла после успешной записи:
	$TempPath = "${FilePath}.tmp"
	try {
		[System.IO.File]::WriteAllLines($TempPath, [string[]]$Lines, (New-Object System.Text.UTF8Encoding($false)))
		Move-Item -LiteralPath $TempPath -Destination $FilePath -Force -ErrorAction Stop
	}
	catch {
		if (Test-Path -LiteralPath $TempPath) {
			Remove-Item -LiteralPath $TempPath -Force -ErrorAction SilentlyContinue
		}
	}
}

# Функция получения списка приложений из истории покупок аккаунта Apple с сохранением в файл (Files/AppsListAccount_.txt):
function Get-Account-Apps {
	$CachePath = Get-Account-List-Path
	$CachedApps = @(Read-AppsListFile -FilePath $CachePath)
	
	$CachedAppsChanged = $false
	for ($i = 0; $i -lt $CachedApps.Count; $i++) {
		$OriginalName = [string]$CachedApps[$i].Name
		$CleanName = ConvertTo-Account-AppName -Name $OriginalName
		if ($CleanName -cne $OriginalName) {
			$CachedApps[$i].Name = $CleanName
			$CachedAppsChanged = $true
		}
	}
	
	# Удаление из списка приложений из истории покупок аккаунта Apple приложений с видом, отличным от iOS App и Mac App:
	$FilteredCachedApps = @($CachedApps | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Kind) -or ([string]$_.Kind) -in $script:AccountAppKinds })
	if ($FilteredCachedApps.Count -ne $CachedApps.Count) {
		$CachedApps = $FilteredCachedApps
		$CachedAppsChanged = $true
	}
	
	if ($CachedAppsChanged) {
		Save-Account-List -FilePath $CachePath -Apps $CachedApps
	}
	
	# Определение устаревшего формата сохраненного списка:
	$LegacyCache = @($CachedApps | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Kind) }).Count -gt 0
	
	# Определение года и ID последней покупки в сохраненном списке приложений:
	$LastKey = 0
	$LastID = ""
	foreach ($CachedApp in $CachedApps) {
		$DateKey = Get-PurchaseDateKey -DateText ([string]$CachedApp.PurchaseDate)
		if ($DateKey -gt 0 -and $DateKey -ge $LastKey) {
			$LastKey = $DateKey
			$LastID = [string]$CachedApp.ID
		}
	}
	$LastYear = [int][Math]::Floor($LastKey / 10000)
	
	# Повторная загрузка списка приложений, начиная с года последней покупки:
	if (!$LegacyCache -and $LastYear -gt 0 -and $LastYear -le (Get-Date).Year) {
		Separator
		Write-Host ((Get-Lang "AccountAppsListUpdate") -f $LastYear)
		
		$UpdateResult = Get-Purchased-Apps -ListArgs @("--since-year", "$LastYear")
		
		# Проверка наличия последнего сохраненного приложения в ответе:
		if ($UpdateResult.Success -and (@($UpdateResult.Apps | Where-Object { $_.ID -eq $LastID }).Count -gt 0)) {
			$KnownIDs = @{}
			foreach ($CachedApp in $CachedApps) {
				$KnownIDs[[string]$CachedApp.ID] = $true
			}
			
			# Добавление отсутствующих приложений в список:
			$NewApps = @()
			foreach ($UpdateApp in $UpdateResult.Apps) {
				if (!$KnownIDs.ContainsKey($UpdateApp.ID)) {
					$KnownIDs[$UpdateApp.ID] = $true
					$NewApps += $UpdateApp
				}
			}
			
			if ($NewApps.Count -eq 0) {
				return [PSCustomObject]@{ Success = $true; Apps = $CachedApps }
			}
			
			$MergedApps = @(Sort-Apps-By-Date -Apps (@($CachedApps) + $NewApps))
			Save-Account-List -FilePath $CachePath -Apps $MergedApps
			return [PSCustomObject]@{ Success = $true; Apps = $MergedApps }
		}
	}
	
	# Загрузка полного списка приложений из истории покупок аккаунта Apple при первой загрузке, устаревшем формате списка, ошибке повторной загрузки:
	Separator
	Write-Host (Get-Lang "AccountAppsListLoad")
	$FullResult = Get-Purchased-Apps -ListArgs @("--all")
	
	if ($FullResult.Success) {
		$FullApps = @(Sort-Apps-By-Date -Apps @(Remove-Duplicate-IDs -Items $FullResult.Apps))
		Save-Account-List -FilePath $CachePath -Apps $FullApps
		return [PSCustomObject]@{ Success = $true; Apps = $FullApps }
	}
	
	if (![string]::IsNullOrWhiteSpace($FullResult.Output)) {
		Write-Host $FullResult.Output.Trim()
	}
	
	# Вывод ранее сохраненного списка приложений при ошибке загрузки полного списка приложений:
	if ($CachedApps.Count -gt 0) {
		Show-Error "ErrorAppsListAccountUpdate"
		return [PSCustomObject]@{ Success = $true; Apps = $CachedApps }
	}
	
	Show-Error "ErrorAppsListAccountLoad"
	return [PSCustomObject]@{ Success = $false; Apps = @() }
}

# Функция предварительной загрузки списка популярных приложений (Files/AppsList.txt) и предупреждения (Files/Warning.txt):
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
	
	# Чтение списка популярных приложений (Files/AppsList.txt) и сохранение в памяти:
	Initialize-Repo-List
	
	# Чтение предупреждения (Files/Warning.txt) и сохранение в памяти:
	$script:WarningText = $null
	
	if (Test-Path $WarningPath) {
		$script:WarningText = Get-Content -Path $WarningPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
	}
}

# Функция сохранения списка приложений, приобретенных скриптом (Files/PurchasedAppsList.json):
function Save-Purchased-App {
	param (
		[string]$AppID,
		[string]$AppNameOnly
	)
	
	if ([string]::IsNullOrWhiteSpace($AppNameOnly) -or $AppNameOnly -eq "Unknown") {
		return
	}
	
	$HistoryFile = "$PurchasedAppsListFilePath"
	
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
	
	# Загрузка списка популярных приложений (Files/AppsList.txt):
	Initialize-Repo-List
	
	# Создание хэш-таблицы для поиска актуальных имен и индексов:
	$ReferenceMap = @{}
	for ($i = 0; $i -lt $script:RepoParsedList.Count; $i++) {
		$RefApp = $script:RepoParsedList[$i]
		$ReferenceMap[$RefApp.ID] = @{ Index = $i; Name = $RefApp.Name }
	}
	
	# Добавление приложений из пользовательского списка приложений (Files/AppsListCustom.txt):
	$CustomList = @(Get-Custom-List)
	for ($i = 0; $i -lt $CustomList.Count; $i++) {
		$RefApp = $CustomList[$i]
		if ($ReferenceMap.ContainsKey($RefApp.ID)) {
			$ReferenceMap[$RefApp.ID].Name = $RefApp.Name
		} else {
			$ReferenceMap[$RefApp.ID] = @{ Index = $script:RepoParsedList.Count + $i; Name = $RefApp.Name }
		}
	}
	
	$IsDuplicate = $false
	
	# Синхронизация имен сохраненных приложений со списком и поиск дубликатов:
	foreach ($Item in $AccountApps) {
		if ($ReferenceMap.ContainsKey($Item.AppID)) {
			$Item.Name = $ReferenceMap[$Item.AppID].Name
		}
		if ($Item.AppID -eq $AppID) {
			$IsDuplicate = $true
		}
	}
	
	# Добавление нового приложения:
	if (-not $IsDuplicate) {
		$NewItem = [PSCustomObject]@{
			Name = $AppNameOnly;
			AppID = $AppID }
		$AccountApps = @($AccountApps) + $NewItem
	}
	
	# Сортировка:
	$AccountApps = @($AccountApps | Sort-Object `
		@{ Expression = { if ($ReferenceMap.ContainsKey($_.AppID)) { $ReferenceMap[$_.AppID].Index } else { [int]::MaxValue } } }, `
		@{ Expression = {
			$Name = [regex]::Replace("$($_.Name)".ToUpper().Replace('Ё','Е'), '\d+', { $args[0].Value.PadLeft(10, '0') })
			[BitConverter]::ToString([Text.Encoding]::BigEndianUnicode.GetBytes($Name))
		} })
	
	# Сохранение данных:
	$Data."$script:CurrentAppleAccount" = $AccountApps
	$Data | ConvertTo-Json -Depth 5 | Set-Content $HistoryFile -Encoding UTF8
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
	param ([string]$AppID)
	Initialize-Repo-List
	# Поиск в пользовательском списке приложений (Files/AppsListCustom.txt):
	$App = @(Get-Custom-List) | Where-Object { $_.ID -eq $AppID } | Select-Object -First 1
	if ($App) { return $App.Name }
	
	# Поиск в списке популярных приложений (Files/AppsList.txt):
	$App = $script:RepoParsedList | Where-Object { $_.ID -eq $AppID } | Select-Object -First 1
	if ($App) { return $App.Name } else { return $null }
}

# Функция перемещения и автоматического переименования:
function Move-IPA-Files {
	param (
		[string]$AppID,
		[string]$AppName
	)
	# Создание папки Apps:
	if (!(Test-Path $AppsFolderPath)) {
		New-Item -Path $AppsFolderPath -ItemType Directory -Force | Out-Null
	}
	
	$ipaFiles = Get-ChildItem -Path "$PSScriptRoot" -Filter "*.ipa" -File
	if ($ipaFiles) {
		foreach ($File in $ipaFiles) {
			$DestPath = Join-Path -Path $AppsFolderPath -ChildPath $File.Name
			Move-Item -Path $File.FullName -Destination $DestPath -Force
			Separator
			Write-Host (Get-Lang "FileSaved")
			
			$Meta = Get-IPA-Metadata -ipaPath $DestPath
			if ($Meta) {
				$FinalAppName = $Meta.AppName
				
				# Проверка списка популярных приложений (Files/AppsList.txt):
				if ([string]::IsNullOrWhiteSpace($AppName) -or $AppName -eq "Unknown") {
					$RepoName = Get-Repo-AppName -AppID $AppID
					if (![string]::IsNullOrWhiteSpace($RepoName)) {
						$AppName = $RepoName
					}
				}
				
				# Применение найденного имени:
				if (![string]::IsNullOrWhiteSpace($AppName) -and $AppName -ne "Unknown") {
					$FinalAppName = $AppName -replace '[\\/:*?"<>|]', ''
				}
				
				# Удаление пробелов вокруг дефиса в названии приложения:
				$FinalAppName = $FinalAppName -replace '\s*-\s*', '-'
				
				# Формирование имени файла с платформой и замена всех пробелов на "_":
				$NewName = "$($FinalAppName)_$($Meta.Version)_$($Meta.Platform)_$($Meta.MinIOS)+_$($script:CurrentAppleAccount).ipa" -replace '\s+', '_'
				$TargetFile = Join-Path -Path $AppsFolderPath -ChildPath $NewName
				
				if (Test-Path $TargetFile) {
					Remove-Item $TargetFile -Force -ErrorAction SilentlyContinue
				}
				
				Rename-Item -Path $DestPath -NewName $NewName -Force
				Write-Host "$(Get-Lang 'FileName') $NewName"
				Write-Host "$((Get-Lang 'MinPlatformVersion') -f $Meta.Platform) $($Meta.MinIOS)"
				
			}
		}
	}
}

# Функция проверки числового ввода:
function Test-NumericInput {
	param ([string]$InputValue)
	if ([string]::IsNullOrWhiteSpace($InputValue) -or $InputValue -notmatch '^\d+$') {
		Show-Error "ErrorInvalidInput"
		return $false
	}
	return $true
}

# Функция получения введенных номеров и диапазонов:
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
		[int]$MaxCount,
		[string]$CancelKey = 'CancelStep',
		[string]$HintKey
	)
	
	while ($true) {
		# Вывод подсказки о вводе нескольких номеров:
		if (![string]::IsNullOrEmpty($HintKey) -and $MaxCount -gt 1) {
			Write-Host (Get-Lang $HintKey)
			Separator
		}
		
		$Selection = Read-Host "$(Get-Lang $PromptKey) (1-$MaxCount) $(Get-Lang $CancelKey)`n"
		
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

# Функция запроса порядковых номеров (№) из таблицы ID версий или ID версий:
function Read-VersionIDSelection {
	param ([array]$VersionMapping)
	
	$MaxCount = @($VersionMapping).Count
	
	while ($true) {
		# Вывод подсказки о пакетном вводе номеров:
		if ($MaxCount -gt 1) {
			Write-Host (Get-Lang "BatchHintVersionIDs")
			Separator
		}
		
		$Selection = Read-Host "$(Get-Lang 'AskVersionsListNum') (1-$MaxCount) $(Get-Lang 'CancelStep')`n"
		
		if ($Selection -eq '0') { return $null }
		
		if ([string]::IsNullOrWhiteSpace($Selection)) {
			Show-Error "ErrorInvalidInput"
			Separator
			continue
		}
		
		# Разделение введенных значений на ID версий и порядковые номера (№):
		$CustomIDs = @()
		$IndexParts = @()
		foreach ($Part in ($Selection -split ',')) {
			$Part = $Part.Trim()
			
			if ($Part -match '^\d{6,}$') {
				$CustomIDs += $Part
			} elseif (![string]::IsNullOrWhiteSpace($Part)) {
				$IndexParts += $Part
			}
		}
		
		# Преобразование порядковых номеров (№) в ID версий из таблицы:
		$SelectedIDs = @()
		if ($IndexParts.Count -gt 0) {
			$SelectedIndices = Parse-NumberSelection -Selection ($IndexParts -join ',') -MaxCount $MaxCount
			if ($null -eq $SelectedIndices) {
				Show-Error "ErrorInvalidInput"
				Separator
				continue
			}
			
			foreach ($Index in $SelectedIndices) {
				$SelectedIDs += [string]$VersionMapping[$Index - 1].ID
			}
		}
		
		# Добавление ID версий и удаление дублей:
		$SelectedIDs = @(($SelectedIDs + $CustomIDs) | Select-Object -Unique)
		
		if ($SelectedIDs.Count -eq 0) {
			Show-Error "ErrorInvalidInput"
			Separator
			continue
		}
		
		return $SelectedIDs
	}
}

# Функция загрузки приложений:
function IPA-Download {
	param (
		[string]$AppID,
		[string]$AppName
	)
	if (!(Test-NumericInput -InputValue $AppID)) { return }
	Separator
	Invoke-ipatool download -i $AppID --purchase
	Move-IPA-Files -AppID $AppID -AppName $AppName
}

# Функция загрузки приложений с выбором версии:
function IPA-Download-With-Version {
	param (
		[string]$AppID,
		[string]$AppName
	)
	if (!(Test-NumericInput -InputValue $AppID)) { return }
	
	$RawOutput = Invoke-ipatool list-versions -i $AppID --purchase
	
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
	
	# Вывод ошибки, если версии приложения не найдены:
	if ($RawVersions.Count -eq 0) {
		Show-Error "ErrorNoVersionsFound"
		return
	}
	
	Separator
	Write-Host (Get-Lang "LoadingVersionsIDList")
	
	$VersionMapping = @()
	$Counter = 1
	foreach ($VersionID in $RawVersions) {
		$VersionMapping += [PSCustomObject]@{
			Num = $Counter
			ID = $VersionID
		}
		$Counter++
	}
	
	# Внешний цикл:
	while ($true) {
		Separator
		Out-Table -Data @($VersionMapping) -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderVersionID") -Properties "Num", "ID"
		Separator
		
		# Запрос порядковых номеров (№) или ID версий для вычисления и вывода версий:
		$PreSelectedIDs = Read-VersionIDSelection -VersionMapping $VersionMapping
		
		# Ввод 0: возврат в главное меню:
		if ($null -eq $PreSelectedIDs) { return } 
		
		$DetailedMapping = @()
		$DetailCounter = 1
		
		# Запрос метаданных для выбранных ID:
		foreach ($VersionID in $PreSelectedIDs) {
			$Meta = Invoke-ipatool get-version-metadata -i $AppID --external-version-id $VersionID
			$MetaText = ($Meta | Out-String)
			
			$DisplayVersion = if ($MetaText -match 'displayVersion=([^\s,]+)') { $Matches[1] } else { "NA" }
			$DisplayVersion = $script:reANSI.Replace($DisplayVersion, '')
			
			# Минимальная версия iOS из значения minimumOSVersion:
			$MinOSVersion = if ($MetaText -match 'minimumOSVersion=([^\s,]+)') { $Matches[1] } else { "NA" }
			$MinOSVersion = $script:reANSI.Replace($MinOSVersion, '')
			
			$DetailedMapping += [PSCustomObject]@{
				Index = $DetailCounter
				ID = $VersionID
				Version = $DisplayVersion
				MinOS = $MinOSVersion
			}
			$DetailCounter++
		}
		
		Separator
		Write-Host (Get-Lang "SelectedVersionsList")
		Separator
		
		# Отрисовка таблицы:
		Out-Table -Data $DetailedMapping -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderVersion"), (Get-Lang "HeaderMinIOS"), (Get-Lang "HeaderVersionID") -Properties "Index", "Version", "MinOS", "ID"
		Separator
		
		# Запрос порядковых номеров (№) версий для загрузки:
		$FinalIndices = Read-NumberSelection -PromptKey 'AskVersionsDownloadNum' -MaxCount $DetailedMapping.Count -CancelKey 'CancelStepVerID' -HintKey 'BatchHintVersions'
		
		# Возврат цикла к основной таблице, если пользователь ввел 0:
		if ($null -eq $FinalIndices) {
			continue
		}
		
		# Загрузка выбранных финальных версий:
		$VersionsTotal = @($FinalIndices).Count
		$VersionsCurrent = 0
		foreach ($Index in $FinalIndices) {
			$VersionsCurrent++
			$SelectedToDownload = $DetailedMapping[$Index - 1]
			Separator
			
			# Вывод выбранной версии приложения:
			Write-Host "$VersionsCurrent/$VersionsTotal $(Get-Lang 'SelectedVersion') $($SelectedToDownload.Version)"
			Separator
			$FinalID = $SelectedToDownload.ID
			Invoke-ipatool download -i $AppID --external-version-id $FinalID
			Move-IPA-Files -AppID $AppID -AppName $AppName
		}
		
		# Выход из цикла после успешной загрузки:
		break 
	}
}

# Функция выполнения действия с приложением:
function Invoke-AppAction {
	param (
		[string]$AppID,
		[string]$AppName,
		[string]$DisplayName,
		[ValidateSet("Purchase", "Download", "DownloadVersion")][string]$Action,
		[int]$Current,
		[int]$Total
	)
	Separator
	
	# Счетчик выбранных приложений:
	$CounterText = if ($Total -gt 0) { "$Current/$Total " } else { "" }
	Write-Host "$CounterText$(Get-Lang 'SelectedApp') $DisplayName (ID: $AppID)"
	switch ($Action) {
		"Purchase" {
			Separator
			Invoke-ipatool purchase -i $AppID
			Save-Purchased-App -AppID $AppID -AppNameOnly $AppName
		}
		"Download" {
			IPA-Download -AppID $AppID -AppName $AppName
		}
		"DownloadVersion" {
			IPA-Download-With-Version -AppID $AppID -AppName $AppName
		}
	}
}

# Функция выполнения действия со списком выбранных приложений:
function Invoke-AppsBatch {
	param (
		$Apps,
		[ValidateSet("Purchase", "Download", "DownloadVersion")][string]$Action
	)
	
	if ($null -eq $Apps) { return }
	
	$AppsTotal = @($Apps).Count
	$AppsCurrent = 0
	foreach ($App in @($Apps)) {
		$AppsCurrent++
		Invoke-AppAction -AppID $App.ID -AppName $App.Name -DisplayName $App.Display -Action $Action -Current $AppsCurrent -Total $AppsTotal
	}
}

# Функция поиска приложений по названию или ID приложений:
function Search-Apps {
	param (
		[string]$PromptKey
	)
	
	while ($true) {
		Separator
		$AppName = Read-Host "$(Get-Lang 'AskAppSearch') $(Get-Lang 'CancelStep')`n"
		
		if ($AppName -eq '0') {
			return $null
		}
		
		# Ввод ID через запятую:
		$IDParts = @($AppName.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
		
		if ([string]::IsNullOrWhiteSpace($AppName) -or $IDParts.Count -eq 0) {
			Show-Error "ErrorInvalidInput"
			continue
		}
		
		# Определение ввода ID приложения (число от 6 знаков):
		if (@($IDParts | Where-Object { $_ -notmatch '^\d{6,}$' }).Count -eq 0) {
			$IDApps = @()
			
			foreach ($ID in $IDParts) {
				$AppNames = Resolve-AppDisplayName -AppID $ID
				$IDApps += [PSCustomObject]@{
					ID = $ID
					Name = $AppNames.Final
					Display = $AppNames.Display
				}
			}
			
			return $IDApps
		}
		
		# Инициализация списка популярных приложений (Files/AppsList.txt):
		Initialize-Repo-List
		
		# Поиск в пользовательском списке приложений (Files/AppsListCustom.txt):
		$CustomList = @(Get-Custom-List)
		$FoundApps = @(
			$CustomList |
			Where-Object { $_.Name -match [regex]::Escape($AppName) } |
			ForEach-Object {
				[PSCustomObject]@{
					Name = $_.Name
					ID = $_.ID
				}
			}
		)
		
		# Поиск в списке популярных приложений (Files/AppsList.txt):
		$CustomIDs = @($CustomList | ForEach-Object { $_.ID })
		
		if ($null -ne $script:RepoParsedList) {
			$FoundApps += @(
				$script:RepoParsedList |
				Where-Object {
					$CustomIDs -notcontains $_.ID -and
					$_.Name -match [regex]::Escape($AppName)
				} |
				ForEach-Object {
					[PSCustomObject]@{
						Name = $_.Name
						ID = $_.ID
					}
				}
			)
		}
		
		# Поиск в App Store:
		$SearchOutput = Invoke-ipatool search $AppName --limit 10 --format json --non-interactive | Out-String
		
		if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrWhiteSpace($SearchOutput)) {
			try {
				$SearchResult = $SearchOutput | ConvertFrom-Json
				
				if ($SearchResult.apps) {
					foreach ($Item in @($SearchResult.apps)) {
						$FoundApps += [PSCustomObject]@{
							Name = ConvertTo-Account-AppName -Name ([string]$Item.Name)
							ID = $Item.ID
						}
					}
				}
			}
			catch {
			}
		}
		
		# Удаление дублей приложений по ID:
		$FoundApps = @(Remove-Duplicate-IDs -Items $FoundApps)
		
		# Возврат к вводу названия/ID, если ничего не найдено:
		if ($FoundApps.Count -eq 0) {
			Show-Error "ErrorNoAppsFound"
			continue
		}
		
		# Вывод результатов:
		Separator
		$Counter = 1
		
		$TableData = foreach ($App in $FoundApps) {
			[PSCustomObject]@{
				Num = $Counter++
				Name = Get-ShortText -Text ([string]$App.Name)
				ID = $App.ID
			}
		}
		
		Out-Table -Data $TableData `
			-Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID") `
			-Properties "Num", "Name", "ID"
			
		Separator
		
		# Выбор приложений:
		$HintKey = if ($PromptKey -eq 'AskAppNumPurchase') { 'BatchHintPurchase' } else { 'BatchHintDownload' }
		$Indices = Read-NumberSelection -PromptKey $PromptKey -MaxCount $FoundApps.Count -HintKey $HintKey
		
		# Ввод 0: возврат в главное меню:
		if ($null -eq $Indices) {
			return $null
		}
		
		$SelectedApps = @()
		
		foreach ($Index in $Indices) {
			$SelectedApp = $FoundApps[$Index - 1]
			
			$SelectedApps += [PSCustomObject]@{
				ID = $SelectedApp.ID
				Name = $SelectedApp.Name
				Display = $SelectedApp.Name
			}
		}
		
		return $SelectedApps
	}
}

# Функция получения списка выбранных приложений:
function Get-Apps-From-List {
	param (
		[string]$ListMode
	)
	
	$TargetFile = "$PurchasedAppsListFilePath"
	$MenuTitle = Get-Lang 'ListMenuTitle'
	
	if ($ListMode -eq "Purchase") {
		$MenuItems = @(
			(Get-Lang 'PopularAppsListMenu')
			(Get-Lang 'NotPurchasedAppsListMenu')
			(Get-Lang 'CustomAppsListMenu')
		)
	} else {
		$MenuItems = @(
			(Get-Lang 'PopularAppsListMenu')
			(Get-Lang 'AccountAppsListMenu')
			(Get-Lang 'CustomAppsListMenu')
		)
	}
	
	$MenuText = (@("$MenuTitle $(Get-Lang 'CancelStep')") + $MenuItems) -join "`n"
	
	while ($true) {
		# Меню выбора списка приложений:
		$ListChoice = Read-MenuChoice -MenuText "$MenuText`n" -OptionsCount $MenuItems.Count -AllowCancel
		if ($ListChoice -eq '0') { return $null }
		
		$AppItems = @()
		$ShowPurchaseDate = $false
		
		# 1. Список популярных приложений:
		if ($ListChoice -eq '1') {
			Initialize-Repo-List
			if ($script:RepoParsedList.Count -eq 0) {
				Show-Error "ErrorAppsListLoad"
				Separator
				continue
			}
			$AppItems = @($script:RepoParsedList)
		}
		
		# 2. Список популярных приложений, не приобретенных скриптом:
		elseif ($ListMode -eq "Purchase" -and $ListChoice -eq '2') {
			Initialize-Repo-List
			if ($script:RepoParsedList.Count -eq 0) {
				Show-Error "ErrorAppsListLoad"
				Separator
				continue
			}
			
			# Добавление приложения в список приложений, приобретенных скриптом (Files/PurchasedAppsList.json):
			$SavedIDs = @()
			if (Test-Path -LiteralPath $TargetFile) {
				try {
					$HistoryRaw = Get-Content -LiteralPath $TargetFile -Raw -Encoding UTF8 -ErrorAction Stop
					if (![string]::IsNullOrWhiteSpace($HistoryRaw) -and $HistoryRaw.Trim() -ne '{}') {
						$HistoryRoot = $HistoryRaw | ConvertFrom-Json -ErrorAction Stop
						$HistoryRecords = @()
						if ($HistoryRoot -is [System.Collections.IEnumerable] -and $HistoryRoot -isnot [System.Management.Automation.PSCustomObject]) {
							$HistoryRecords = @($HistoryRoot)
						} elseif ($HistoryRoot -and $HistoryRoot.psobject.properties.Name -contains $script:CurrentAppleAccount) {
							$HistoryRecords = @($HistoryRoot."$script:CurrentAppleAccount")
						}
						$SavedIDs = @($HistoryRecords | ForEach-Object { [string]$_.AppID } | Where-Object { ![string]::IsNullOrWhiteSpace($_) })
					}
				} catch {
					$SavedIDs = @()
				}
			}
			
			foreach ($App in $script:RepoParsedList) {
				if ($App.ID -and $SavedIDs -notcontains [string]$App.ID) {
					$AppItems += $App
				}
			}
		}
		
		# 2. Список приложений из истории покупок аккаунта Apple (Files/AppsListAccount_.txt):
		elseif ($ListMode -ne "Purchase" -and $ListChoice -eq '2') {
			$AccountResult = Get-Account-Apps
			if (!$AccountResult.Success) {
				Separator
				continue
			}
			
			$AppItems = @($AccountResult.Apps)
			$ShowPurchaseDate = $true
		}
		
		# 3. Пользовательский список приложений (Files/AppsListCustom.txt):
		elseif ($ListChoice -eq '3') {
			$CustomList = @(Get-Custom-List)
			if ($CustomList.Count -eq 0) {
				Show-Error "ErrorAppsListCustomEmpty"
				Separator
				continue
			}
			$AppItems = @($CustomList)
		}
		
		if ($AppItems.Count -eq 0) {
			Show-Error "ErrorNoAppsFound"
			Separator
			continue
		}
		
		# Подготовка строк таблицы:
		$TableData = @(
			for ($i = 0; $i -lt $AppItems.Count; $i++) {
				$DisplayName = [string]$AppItems[$i].Name
				if ($ShowPurchaseDate) {
					$DisplayName = ConvertTo-Account-AppName -Name $DisplayName
				}
				
				[PSCustomObject]@{
					Num = $i + 1
					Name = [string]$AppItems[$i].Name
					DisplayName = Get-ShortText -Text $DisplayName
					ID = [string]$AppItems[$i].ID
					Kind = [string]$AppItems[$i].Kind
					PurchaseDate = [string]$AppItems[$i].PurchaseDate
				}
			}
		)
		
		Separator
		if ($ShowPurchaseDate) {
			Out-Table -Data $TableData -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID"), (Get-Lang "HeaderKind"), (Get-Lang "HeaderPurchaseDate") -Properties "Num", "DisplayName", "ID", "Kind", "PurchaseDate"
		} else {
			Out-Table -Data $TableData -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderAppName"), (Get-Lang "HeaderAppID") -Properties "Num", "DisplayName", "ID"
		}
		Separator
		
		$PromptKey = if ($ListMode -eq "Purchase") { 'AskAppNumPurchase' } else { 'AskAppNumDownload' }
		$HintKey = if ($ListMode -eq "Purchase") { 'BatchHintPurchase' } else { 'BatchHintDownload' }
		$SelectedIndices = Read-NumberSelection -PromptKey $PromptKey -MaxCount $TableData.Count -HintKey $HintKey
		if ($null -eq $SelectedIndices) { return $null }
		
		$SelectedApps = @()
		foreach ($Index in $SelectedIndices) {
			$SelectedObject = $TableData[$Index - 1]
			if (![string]::IsNullOrEmpty($SelectedObject.ID)) {
				$SelectedAppName = [string]$SelectedObject.Name
				
				# Вывод названия приложения:
				if ($ListMode -ne "Purchase" -and $ListChoice -eq '2') {
					$PreferredName = Get-Repo-AppName -AppID ([string]$SelectedObject.ID)
					if (![string]::IsNullOrWhiteSpace($PreferredName)) {
						$SelectedAppName = $PreferredName
					}
				}
				
				$SelectedApps += [PSCustomObject]@{
					ID = $SelectedObject.ID
					Name = $SelectedAppName
					Display = $SelectedAppName
				}
			}
		}
		return $SelectedApps
	}
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
		$Meta = Get-IPA-Metadata -ipaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)" } else { "Error" }
		
		[PSCustomObject]@{
			Num = $Counter++
			DisplayName = Get-ShortText -Text $File.Name
			MinOs = $MinOs
			Platform = if ($Meta) { $Meta.Platform } else { $null }
		}
	}
	
	# Название платформы в заголовке:
	$PlatformNames = @($TableData | ForEach-Object { $_.Platform } | Where-Object { $_ } | Select-Object -Unique)
	if ($PlatformNames.Count -eq 0) {
		$PlatformNames = @("iOS")
	}
	$MinVersionHeader = (Get-Lang "HeaderMinPlatformVersion") -f ($PlatformNames -join "/")
	
	Out-Table -Data @($TableData) -Headers (Get-Lang "HeaderNum"), (Get-Lang "FileName"), $MinVersionHeader -Properties "Num", "DisplayName", "MinOs"
		
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

# Функция установки путей к ipatool/ideviceinstaller/idevice_id и применения PATH/прав запуска:
function Set-ipatoolBinaryPaths {
	param ([string]$FolderPath)
	
	if ($IsWin) {
		$ipatoolFile = Get-ChildItem -Path $FolderPath -Filter "ipatool*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
		$ideviceinstallerFile = Get-ChildItem -Path $FolderPath -Filter "ideviceinstaller*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
		$ideviceidFile = Get-ChildItem -Path $FolderPath -Filter "idevice_id*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
		
		if ($ipatoolFile) { $script:ipatoolFilePath = $ipatoolFile.FullName }
		if ($ideviceinstallerFile) { $script:ideviceinstallerFilePath = $ideviceinstallerFile.FullName }
		if ($ideviceidFile) { $script:ideviceidFilePath = $ideviceidFile.FullName }
		
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
		$RequiredPatterns = @(
			"idevice_id*.exe",
			"ideviceinfo*.exe",
			"ideviceinstaller*.exe",
			"ipatool*.exe",
			"libimobiledevice-1.0.dll",
			"libplist-2.0.dll"
		)
		
		foreach ($Pattern in $RequiredPatterns) {
			$Found = Get-ChildItem -Path $FolderPath -Filter $Pattern -File -ErrorAction SilentlyContinue
			if (-not $Found) {
				$MissingFiles += $Pattern
			}
		}
	} else {
		$Foundipatool = Get-ChildItem -Path $FolderPath -Filter "ipatool*" -File -ErrorAction SilentlyContinue
		if (-not $Foundipatool) {
			$MissingFiles += "ipatool*"
		}
	}
	
	return $MissingFiles
}

# Функция преобразования версии iOS для сравнения:
function ConvertTo-iOSVersion {
	param ([string]$Text)
	
	if ($Text -notmatch '^\d+(\.\d+){0,3}$') { return $null }
	
	$Parts = @($Text -split '\.')
	while ($Parts.Count -lt 3) { $Parts += '0' }
	
	return [version]($Parts -join '.')
}

# Функция получения аргументов idevice_id, ideviceinfo и ideviceinstaller для работы с устройствами по Wi-Fi:
function Get-AirInstallArgs {
	if ($script:AirInstallEnabled) {
		return @("-n")
	}
	
	return @()
}

# Функция получения списка подключенных устройств:
function Get-ConnectedDevices {
	$Devices = @()
	$NetworkArgs = @(Get-AirInstallArgs)
	
	# Поиск устройств, подключенных по Wi-Fi (-n) или по USB (-l):
	$DeviceListFlag = if ($script:AirInstallEnabled) { "-n" } else { "-l" }
	$UDIDList = @(& "$script:ideviceidFilePath" $DeviceListFlag 2>$null)
	
	# Вид подключения устройств:
	$ConnectionType = if ($script:AirInstallEnabled) { "Wi-Fi" } else { "USB" }
	
	# Поиск ideviceinfo:
	$ideviceinfoFilePath = $null
	if ($IsWin) {
		$ideviceinfoFile = Get-ChildItem -Path (Split-Path -Path $script:ideviceidFilePath -Parent) -Filter "ideviceinfo*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
		if ($ideviceinfoFile) { $ideviceinfoFilePath = $ideviceinfoFile.FullName }
	} else {
		$ideviceinfoCommand = Get-Command ideviceinfo -ErrorAction SilentlyContinue | Select-Object -First 1
		if ($ideviceinfoCommand) { $ideviceinfoFilePath = $ideviceinfoCommand.Source }
	}
	
	foreach ($UDID in $UDIDList) {
		$UDID = "$UDID".Trim()
		
		# Пропуск строк, не похожих на UDID:
		if ($UDID -notmatch '^[0-9A-Fa-f-]{20,}$') { continue }
		
		# Получение имени устройства:
		$DeviceName = (& "$script:ideviceidFilePath" @NetworkArgs $UDID 2>$null | Out-String).Trim()
		if ([string]::IsNullOrWhiteSpace($DeviceName)) { $DeviceName = "Unknown" }
		
		# Получение версии iOS устройства:
		$DeviceVersion = "?"
		if ($ideviceinfoFilePath) {
			$VersionOutput = (& "$ideviceinfoFilePath" @NetworkArgs -u $UDID -k ProductVersion 2>$null | Out-String).Trim()
			if ($VersionOutput -match '^\d+(\.\d+)+$') { $DeviceVersion = $VersionOutput }
		}
		
		# Ограничение длины UDID в таблице:
		$DisplayUDID = $UDID
		if ($DisplayUDID.Length -gt 15) {
			$DisplayUDID = $DisplayUDID.Substring(0, 15) + "…"
		}
		
		$Devices += [PSCustomObject]@{
			Num = $Devices.Count + 1
			Name = $DeviceName
			iOSVersion = $DeviceVersion
			UDID = $UDID
			DisplayUDID = $DisplayUDID
			Connection = $ConnectionType
		}
	}
	
	return $Devices
}

# Функция установки приложений из папки Apps:
function Install-Apps {
	if ([string]::IsNullOrWhiteSpace($script:ideviceinstallerFilePath)) {
		Show-Error "ErrorideviceinstallerNotFound"
		return
	}
	
	if ([string]::IsNullOrWhiteSpace($script:ideviceidFilePath)) {
		Show-Error "ErrorideviceidNotFound"
		return
	}
	
	# Аргументы для установки приложений на устройства, подключенные по Wi-Fi:
	$NetworkArgs = @(Get-AirInstallArgs)
	
	while ($true) {
		# Поиск подключенных устройств:
		$Devices = @(Get-ConnectedDevices)
		if ($Devices.Count -eq 0) {
			Show-Error "ErrorNoDevices"
			return
		}
		
		# Выбор устройств для установки:
		Separator
		Out-Table -Data $Devices -Headers (Get-Lang "HeaderNum"), (Get-Lang "HeaderDeviceName"), (Get-Lang "HeaderDeviceiOS"), (Get-Lang "HeaderUDID"), (Get-Lang "HeaderKind") -Properties "Num", "Name", "iOSVersion", "DisplayUDID", "Connection"
		Separator
		
		$SelectedDeviceIndices = Read-NumberSelection -PromptKey 'AskDeviceNum' -MaxCount $Devices.Count -HintKey 'BatchHintInstallDevices'
		if ($null -eq $SelectedDeviceIndices) {
			return
		}
		
		# Получение списка приложений после выбора устройств:
		$ipaFiles = Get-iOS-MinVersion
		if ($null -eq $ipaFiles) {
			return
		}
		
		# Выбор приложений для установки:
		Separator
		$SelectedIndices = Read-NumberSelection -PromptKey 'AskFileNum' -MaxCount $ipaFiles.Count -HintKey 'BatchHintInstallApps'
		if ($null -eq $SelectedIndices) {
			return
		}
		
		$InstallFailed = $false
		
		foreach ($Index in $SelectedIndices) {
			$SelectedFile = $ipaFiles[$Index - 1]
			
			# Минимальная версия iOS приложения:
			$FileMeta = Get-IPA-Metadata -ipaPath $SelectedFile.FullName
			$RequiredVersion = if ($FileMeta) { ConvertTo-iOSVersion $FileMeta.MinIOS } else { $null }
			
			# Установка приложения:
			Separator
			Write-Host "$(Get-Lang 'InstallApp') $($SelectedFile.Name)"
			
			$TempFile = "$TempipaFilePath"
			Copy-Item -Path $SelectedFile.FullName -Destination $TempFile -Force
			
			try {
				foreach ($DeviceIndex in $SelectedDeviceIndices) {
					$Device = $Devices[$DeviceIndex - 1]
					$DeviceUDID = $Device.UDID
					
					Separator
					Write-Host "$(Get-Lang 'InstallDevice') $($Device.Name) ($($Device.DisplayUDID))"
					Separator
					
					# Проверка минимальной версии iOS перед установкой:
					$DeviceVersion = ConvertTo-iOSVersion $Device.iOSVersion
					if ($RequiredVersion -and $DeviceVersion -and $DeviceVersion -lt $RequiredVersion) {
						Write-Host ((Get-Lang 'ErrorDeviceOSVersionTooLow') -f $Device.iOSVersion, $FileMeta.MinIOS) -ForegroundColor DarkRed
						$InstallFailed = $true
						continue
					}
					
					& "$script:ideviceinstallerFilePath" @NetworkArgs --udid $DeviceUDID install $TempFile
					
					if ($LASTEXITCODE -ne 0) {
						& "$script:ideviceinstallerFilePath" @NetworkArgs --udid $DeviceUDID upgrade $TempFile
						
						if ($LASTEXITCODE -ne 0) {
							Show-Error "ErrorInstallipa"
							$InstallFailed = $true
						}
					}
				}
			}
			# Удаление временного файла приложения:
			finally {
				Remove-Item -Path $TempFile -Force -ErrorAction SilentlyContinue
			}
		}
		
		# Возврат к выбору устройств при ошибке установки:
		if ($InstallFailed) {
			continue
		}
		
		return
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
			
			# Проверка, что обе переменные не пустые:
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
					
					# Вывод ссылки при ошибке открытия в браузере:
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
	} else {
		$ipatoolFileName = if ($script:ipatoolFilePath) {
			Split-Path -Leaf $script:ipatoolFilePath
		} else {
			$Filter = if ($IsWin) { "ipatool*.exe" } else { "ipatool*" }
			$FoundFile = Get-ChildItem -Path $script:BinaryFolderPath -Filter $Filter -File -ErrorAction SilentlyContinue | Select-Object -First 1
			if ($FoundFile) { $FoundFile.Name } else { "ipatool" }
		}
		
		Write-Host "IPA_Downloader $ScriptVersion ($ipatoolFileName)"
	}
	
	Show-SystemInfo
	
	# Вывод сообщений о включенных режимах отладки и установки приложений по Wi-Fi:
	if ($script:IsDebugEnabled -or $script:AirInstallEnabled) {
		Separator
		
		if ($script:IsDebugEnabled) {
			Write-Host (Get-Lang "DebugEnabled")
		}
		
		if ($script:AirInstallEnabled) {
			Write-Host (Get-Lang "AirInstallEnabled")
		}
	}
}

# Функция открытия банки для чаевых:
function Open-TipJar {
	# Ссылка на банку с чаевыми:
	$TipJarUrl = "https://pay.cloudtips.ru/p/93c0b094"
	
	# Вывод ссылки при ошибке открытия в браузере:
	if (-not (Open-Url $TipJarUrl)) {
		Show-Error "ErrorOpenUrl"
		Separator
		Write-Host (Get-Lang "Link") $TipJarUrl
	}
	
	Separator
	Write-Host (Get-Lang "TipJar")
}

# Функция смены языка:
function Switch-Language {
	$script:CurrentLang = if ($script:CurrentLang -eq "RU") { "EN" } else { "RU" }
	Set-Setting -Key "Language" -Value $script:CurrentLang
	Separator
	Write-Host (Get-Lang "LanguageChanged")
}

# Функция включения/отключения режима отладки:
function Switch-DebugMode {
	$script:IsDebugEnabled = -not $script:IsDebugEnabled
	Set-Setting -Key "DebugEnabled" -Value $script:IsDebugEnabled
	Separator
	if ($script:IsDebugEnabled) {
		Write-Host (Get-Lang "DebugEnabled")
	} else {
		Write-Host (Get-Lang "DebugDisabled")
	}
}

# Функция включения/отключения установки приложений по Wi-Fi:
function Switch-AirInstallMode {
	$script:AirInstallEnabled = -not $script:AirInstallEnabled
	Set-Setting -Key "AirInstallEnabled" -Value $script:AirInstallEnabled
	Separator
	if ($script:AirInstallEnabled) {
		Write-Host (Get-Lang "AirInstallEnabled")
	} else {
		Write-Host (Get-Lang "AirInstallDisabled")
	}
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
	
	# Сохранение режима работы, состояния keychain-passphrase и вывод баннера:
	Set-Setting -Key "Mode" -Value $script:WorkMode
	Set-Setting -Key "KeychainEnabled" -Value $script:KeychainEnabled
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
Get-ChildItem -Path $PSScriptRoot -Filter "*.pkg.tmp" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
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
				Switch-Language
			}
			
			# 5. Перейти в IPA_Downloader:
			"5" {
				$script:WorkMode = "Downloader"
				return
			}
			
			# Режим отладки:
			"debug" {
				Switch-DebugMode
			}
			
			# Установка приложений по Wi-Fi:
			"airinstall" {
				Switch-AirInstallMode
			}
			
			# Неверный ввод:
			default {
				Show-Error "ErrorInvalidInput"
			}
		}
	}
}

# Функция запуска ipatool c аргументами:
function Invoke-ipatool {
	$ipatoolArgs = @($args)
	
	# Добавление параметра --keychain-passphrase, если $script:KeychainEnabled = $true:
	if ($script:KeychainEnabled) {
		$ipatoolArgs += "--keychain-passphrase", $script:Kp
	}
	
	# Добавление флага --debug при включении режима отладки:
	if ($script:IsDebugEnabled) {
		$ipatoolArgs += "--debug"
	}
	
	# Запуск ipatool с переданными аргументами:
	& "$script:ipatoolFilePath" @ipatoolArgs
}

# Функция режима IPA_Downloader:
function Invoke-DownloaderMode {
	# Инициализация keychain-passphrase на Windows при $script:KeychainEnabled = $true:
	if ($IsWin -and $script:KeychainEnabled) {
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
		# Формирование пустой keychain-passphrase на macOS, Linux или при $script:KeychainEnabled = $false:
		$script:Kp = ""
	}
	
	# Удаление файла keychain-passphrase при $script:KeychainEnabled = $false:
	if (!$script:KeychainEnabled) {
		Remove-Item -Path (Join-Path -Path $ipatoolHomePath -ChildPath "keychain-passphrase") -Force -ErrorAction SilentlyContinue
	}
	
	# Проверка осуществленного входа с аккаунтом Apple:
	if (Test-Path "$LoginFilePath") {
		Get-Current-AppleAccount
		
		# Проверка авторизации:
		if (!$script:AuthSuccess) {
			Resolve-AppleAuthProblem
		}
	}
	
	# Выбор сохраненных аккаунтов при отсутствии файла login в папке .ipatool:
	if (!(Test-Path "$LoginFilePath") -and @(Get-SavedAppleAccounts).Count -gt 0) {
		Restore-SavedAppleAccountAtStartup | Out-Null
	}
	
	# Вход в аккаунт Apple:
	if (!(Test-Path "$LoginFilePath")) {
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
			switch ($LoginChoice) {
				# 1. Войти в аккаунт Apple:
				"1" {
					Connect-AppleAccount
				}
				
				# 2. Перейти в режим IPA_Installer:
				"2" {
					$script:WorkMode = "Installer"
					Set-Setting -Key "Mode" -Value "Installer"
					return
				}
				
				# 3. Сменить язык (Change Language):
				"3" {
					Switch-Language
				}
				
				# Режим отладки:
				"debug" {
					Switch-DebugMode
				}
				
				# Установка приложений по Wi-Fi:
				"airinstall" {
					Switch-AirInstallMode
				}
				
				# Неверный ввод:
				default {
					Show-Error "ErrorInvalidInput"
				}
			}
		}
	}
	
	# Сохранение настроек режима IPA_Downloader только после успешной авторизации с аккаунтом Apple:
	Set-Setting -Key "Language" -Value $script:CurrentLang
	Set-Setting -Key "Mode" -Value "Downloader"
	Set-Setting -Key "KeychainEnabled" -Value $script:KeychainEnabled
	
	# Основной цикл:
	while (Test-Path "$LoginFilePath") {
		# Вывод данных текущего аккаунта Apple:
		Separator
		Write-Host (Get-Lang "AuthSuccess")
		Invoke-ipatool auth info
		
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
				Invoke-AppsBatch -Apps (Search-Apps -PromptKey 'AskAppNumPurchase') -Action "Purchase"
			}
			
			# 2. Поиск приложений по названию или ID и загрузка последней версии:
			"2" {
				Invoke-AppsBatch -Apps (Search-Apps -PromptKey 'AskAppNumDownload') -Action "Download"
			}
			
			# 3. Поиск приложений по названию или ID и загрузка (с выбором версии):
			"3" {
				Invoke-AppsBatch -Apps (Search-Apps -PromptKey 'AskAppNumDownload') -Action "DownloadVersion"
			}
			
			# 4. Выбор списка приложений и покупка (без загрузки):
			"4" {
				Separator
				Invoke-AppsBatch -Apps (Get-Apps-From-List -ListMode "Purchase") -Action "Purchase"
			}
			
			# 5. Выбор списка приложений и загрузка последней версии:
			"5" {
				Separator
				Invoke-AppsBatch -Apps (Get-Apps-From-List -ListMode "Download") -Action "Download"
			}
			
			# 6. Выбор списка приложений и загрузка (с выбором версии):
			"6" {
				Separator
				Invoke-AppsBatch -Apps (Get-Apps-From-List -ListMode "Download") -Action "DownloadVersion"
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
$(Get-Lang 'ClearMenu2')`n
"@
				$ClearChoice = Read-MenuChoice -MenuText $ClearMenu -OptionsCount 2 -AllowCancel
				
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
				Switch-Language
			}
			
			# Режим отладки:
			"debug" {
				Switch-DebugMode
			}
			
			# Установка приложений по Wi-Fi:
			"airinstall" {
				Switch-AirInstallMode
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
		Set-ipatoolBinaryPaths -FolderPath $script:BinaryFolderPath
		
		# Поиск ideviceinstaller и idevice_id в системе (macOS и Linux):
		if (-not $IsWin) {
			$ideviceCommand = Get-Command ideviceinstaller* -ErrorAction SilentlyContinue | Select-Object -First 1
			$script:ideviceinstallerFilePath = if ($ideviceCommand) { $ideviceCommand.Source } else { $null }
			$ideviceidCommand = Get-Command idevice_id -ErrorAction SilentlyContinue | Select-Object -First 1
			$script:ideviceidFilePath = if ($ideviceidCommand) { $ideviceidCommand.Source } else { $null }
			
			if (-not $script:ideviceinstallerFilePath) {
				Show-Error "ErrorideviceinstallerNotFound"
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