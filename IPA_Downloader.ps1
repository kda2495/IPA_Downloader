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

# Подключение системных сборок для работы с Zip-архивами:
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Устанавливаем шрифт Consolas и кодировку UTF8:
[ConsoleFont]::SetFont("Consolas", 16)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null

# Файл языка скрипта:
$LangConfigFile = ".\MainApp\Lang_Config.txt"

# Загрузка сохраненного языка или установка по умолчанию:
if (Test-Path $LangConfigFile) {
	$SavedLang = (Get-Content $LangConfigFile -Raw).Trim().ToUpper()
	if ($SavedLang -eq "RU" -or $SavedLang -eq "EN") {
		$Global:CurrentLang = $SavedLang
	} else {
		$Global:CurrentLang = "RU"
	}
} else {
	# Язык по умолчанию при первом запуске (русский):
	$Global:CurrentLang = "RU"
	Set-Content -Path $LangConfigFile -Value $Global:CurrentLang -Force
}

# Перевод текста:
$LangStrings = @{
	"RU" = @{
		"ErrorMissingFiles" = "Ошибка: Следующие файлы не найдены в папке MainApp:"
		"PressEnter" = "Нажмите Enter для выхода"
		"AuthSuccess" = "Вход в аккаунт Apple ID выполнен.`nДанные аккаунта Apple ID:"
		"AuthFail" = "Вход в аккаунт Apple ID не выполнен."
		"FileSaved" = "Готово. Файл сохранен в папку Apps."
		"FileName" = "Название файла:"
		"MinIOS" = "Минимальная версия iOS:"
		"ErrorInvalidInput" = "Ошибка: Неверный ввод."
		"ErrorNotPurchased" = "Ошибка: Приложение не приобретено на данном аккаунте Apple ID."
		"AskVerCount" = "Введите количество версий для отображения"
		"HeaderVerID" = "ID версии"
		"HeaderVersion" = "Версия"
		"AskVerNum" = "Введите номер или введите ID версии"
		"SelectedVer" = "Выбрана версия:"
		"ErrorListLoadError" = "Ошибка загрузки списка приложений."
		"AskAppNum" = "Введите номера приложений для загрузки"
		"SelectedApp" = "Выбрано приложение:"
		"HeaderFileName" = "Название файла"
		"HeaderMinIOS" = "Мин. iOS"
		"MenuTitle" = "Введите команду:"
		"Menu1" = "1. Поиск приложения и загрузка последней версии"
		"Menu2" = "2. Ввод ID приложения и загрузка последней версии"
		"Menu3" = "3. Ввод ID приложения и загрузка (с выбором версии)"
		"Menu4" = "4. Вывод списка ID приложений и загрузка последней версии"
		"Menu5" = "5. Вывод списка ID приложений и загрузка (с выбором версии)"
		"Menu6" = "6. Показать минимальную версию iOS для ipa-файлов в папке Apps"
		"Menu7" = "7. Установка приложений, загруженных в папку Apps"
		"Menu8" = "8. Очистка данных"
		"Menu9" = "9. Выход из аккаунта Apple ID"
		"Menu10" = "10. Страница проекта на GitHub"
		"Menu11" = "11. Сменить язык (Change Language)"
		"AskSearch" = "Введите название приложения для поиска"
		"AskIdDownload" = "Введите ID приложения для загрузки"
		"AskIdSearch" = "Введите ID приложения для поиска"
		"ErrorNoApps" = "Ошибка: В папке Apps отсутствуют приложения."
		"AppsCleared" = "Готово. Файлы в папке Apps удалены."
		"ListCleared" = "Готово. Список загруженных приложений очищен."
		"LoggedOut" = "Выполнен выход из аккаунта Apple ID."
		"LangChanged" = "Язык успешно изменен на Русский."
		"AlreadyInList" = "Уже есть в списке: {0} - {1}"
		"AddedToList" = "Добавлено в список: {0} - {1}"
		"ListMenuTitle" = "Выберите список для загрузки:"
		"ListMenu1" = "1. Полный список приложений (GitHub)"
		"ListMenu2" = "2. Список ранее загруженных приложений"
		"ErrorHistoryEmpty" = "Ошибка: История загрузок пуста."
		"ClearMenuTitle" = "Выберите данные для очистки:"
		"ClearMenu1" = "1. Очистка списка ранее загруженных приложений"
		"ClearMenu2" = "2. Очистка папки Apps"		
	}
	"EN" = @{
		"ErrorMissingFiles" = "Error: The following files were not found in the MainApp folder:"
		"PressEnter" = "Press Enter to exit"
		"AuthSuccess" = "Apple ID account login successful.`nApple ID account details:"
		"AuthFail" = "Not authenticated with Apple ID."
		"FileSaved" = "Done. File saved to the Apps folder."
		"FileName" = "File name:"
		"MinIOS" = "Minimum iOS version:"
		"ErrorInvalidInput" = "Error: Invalid input."
		"ErrorNotPurchased" = "Error: The app is not purchased on this Apple ID account."
		"AskVerCount" = "Enter the number of versions to display"
		"HeaderVerID" = "Version ID"
		"HeaderVersion" = "Version"
		"AskVerNum" = "Enter index number or Version ID"
		"SelectedVer" = "Selected version:"
		"ErrorListLoadError" = "Failed to load the application list."
		"AskAppNum" = "Enter index numbers of apps to download"
		"SelectedApp" = "Selected app:"
		"HeaderFileName" = "File name"
		"HeaderMinIOS" = "Min. iOS"
		"MenuTitle" = "Enter a command:"
		"Menu1" = "1. Search for an app and download the latest version"
		"Menu2" = "2. Enter App ID and download the latest version"
		"Menu3" = "3. Enter App ID and download (with version selection)"
		"Menu4" = "4. Show list of App IDs and download the latest version"
		"Menu5" = "5. Show list of App IDs and download (with version selection)"
		"Menu6" = "6. Show minimum iOS version for ipa files in Apps folder"
		"Menu7" = "7. Install apps downloaded to the Apps folder"
		"Menu8" = "8. Clear data"
		"Menu9" = "9. Log out of Apple ID account"
		"Menu10" = "10. GitHub project page"
		"Menu11" = "11. Change Language (Сменить язык)"
		"AskSearch" = "Enter the application name to search"
		"AskIdDownload" = "Enter the App ID to download"
		"AskIdSearch" = "Enter the App ID to search"
		"ErrorNoApps" = "Error: No applications found in the Apps folder."
		"AppsCleared" = "Done. Apps folder has been cleared."
		"ListCleared" = "Done. List of downloaded apps cleared."
		"LoggedOut" = "Successfully logged out of the Apple ID account."
		"LangChanged" = "Language successfully changed to English."
		"AlreadyInList" = "Already in the list: {0} - {1}"
		"AddedToList" = "Added to the list: {0} - {1}"
		"ListMenuTitle" = "Select list source:"
		"ListMenu1" = "1. Full application list (GitHub)"
		"ListMenu2" = "2. List of previously downloaded apps"
		"ErrorHistoryEmpty" = "Error: Download history is empty."
		"ClearMenuTitle" = "Select data to clear:"
		"ClearMenu1" = "1. Clear list of previously downloaded apps"
		"ClearMenu2" = "2. Clear Apps folder"		
	}
}

# Функция перевода текста:
function Get-Lang($Key) {
	return $LangStrings[$Global:CurrentLang][$Key]
}

# Версия скрипта:
Write-Host "IPA_Downloader 3.6" -ForegroundColor Black -BackgroundColor Yellow

# Функция разделителя:
function Separator {
	Write-Host "==============================================" -ForegroundColor Green
}

# Проверка на наличие папки Apps:
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory"
}

# Проверка на наличие папки Lists:
if (!(Test-Path ".\Lists")) {
	$null = New-Item -Path ".\Lists" -ItemType "Directory"
}


# Проверка на наличие папки .ipatool:
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}

# Проверка на наличие всех необходимых файлов для работы:
$CheckMainAppFiles = @(
	"ipatool.exe",
	"ideviceinstaller.exe"
)
$MissingMainAppFiles = @()
foreach ($File in $CheckMainAppFiles) {
	if (!(Test-Path ".\MainApp\$File")) {
		$MissingMainAppFiles += $File
	}
}
if ($MissingMainAppFiles.Count -gt 0) {
	Separator
	Write-Host (Get-Lang "ErrorMissingFiles") -ForegroundColor Red
	$MissingMainAppFiles | ForEach-Object { Write-Host "$_" -ForegroundColor Red }
	Separator
	Read-Host (Get-Lang "PressEnter")
	exit
}

# Удаление файлов .ipa.tmp при запуске:
if (Get-ChildItem -Filter "*.ipa.tmp") {
	Remove-Item ".\*.ipa.tmp" -Force -ErrorAction SilentlyContinue
}

# Проверка на Windows 7 и включение TLS 1.2:
$OsVersion = [System.Environment]::OSVersion.Version
if ($OsVersion.Major -eq 6 -and $OsVersion.Minor -eq 1) {
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Проверка наличия файла account:
if (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Separator
	Write-Host (Get-Lang "AuthSuccess")
	.\MainApp\ipatool.exe auth info
}

# Функция входа в аккаунт Apple ID:
function Connect-AppleID {
	while (!(Test-Path "$env:USERPROFILE\.ipatool\account")) {
		Remove-Item "$env:USERPROFILE\.ipatool\cookies" -Force -ErrorAction SilentlyContinue
		Separator
		Write-Host (Get-Lang "AuthFail")
		.\MainApp\ipatool.exe auth login
	}
}

# Универсальная функция извлечения метаданных из IPA:
function Get-IPA-Metadata {
	param ([string]$IpaPath)
	if (!(Test-Path $IpaPath)) { return $null }
	
	$Metadata = [PSCustomObject]@{
		AppName = "App"
		Version = "0"
		MinIOS = "N/A"
	}
	
	try {
		$Zip = [System.IO.Compression.ZipFile]::OpenRead($IpaPath)
		$PlistEntry = $Zip.Entries | Where-Object { $_.FullName -match 'Payload/.*\.app/Info\.plist$' } | Select-Object -First 1
		if ($PlistEntry) {
			$Reader = New-Object System.IO.StreamReader($PlistEntry.Open(), [System.Text.Encoding]::UTF8)
			$Content = $Reader.ReadToEnd()
			$Reader.Close()
			
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
		if ($Zip) { $Zip.Dispose() }
	}
	
	$Metadata.AppName = $Metadata.AppName -replace '[\\/:*?"<>|]', ''
	return $Metadata
}

# Функция сохранения информации о загруженных ранее приложениях:
function Save-App-To-History {
	param (
		[string]$AppId,
		[string]$FinalFileName
	)

	$HistoryFile = ".\Lists\Downloaded_IDs.json"
	
	if (!(Test-Path ".\Lists\Downloaded_IDs.json")) {
		$null = New-Item -Path ".\Lists\Downloaded_IDs.json" -ItemType "File" -Value ''
	}
	
	$JsonRaw = Get-Content $HistoryFile -Raw -Encoding UTF8

	if ([string]::IsNullOrWhiteSpace($JsonRaw)) {
		$Data = @()
	} else {
		$Data = $JsonRaw | ConvertFrom-Json
	}

	if ($Data -eq $null) {
		$Data = @()
	}

	if ($Data -isnot [System.Collections.IEnumerable]) {
		$Data = @($Data)
	}

	foreach ($Item in $Data) {
		if ($Item.appid -eq $AppId) {
			Write-Host ((Get-Lang "AlreadyInList") -f $Item.name, $AppId)
			return
		}
	}

	$CleanName = [System.IO.Path]::GetFileNameWithoutExtension($FinalFileName)
	$Parts = $CleanName.Split("_")
	$AppNameOnly = $Parts[0].Trim()

	$NewItem = [PSCustomObject]@{
		name = $AppNameOnly
		appid = $AppId
	}

	$Data = @($Data) + $NewItem

	$Data | ConvertTo-Json -Depth 5 | Set-Content $HistoryFile -Encoding UTF8

	Write-Host ((Get-Lang "AddedToList") -f $AppNameOnly, $AppId)
}

# Функция перемещения и автоматического переименования:
function Move-IPA-Files {
	param ([string]$AppId)
	$IPAFiles = Get-ChildItem -Filter "*.ipa"
	if ($IPAFiles) {
		foreach ($File in $IPAFiles) {
			$DestPath = Join-Path (Get-Location) ".\Apps\$($File.Name)"
			Move-Item -Path $File.FullName -Destination $DestPath -Force
			Separator
			Write-Host (Get-Lang "FileSaved")
			
			$Meta = Get-IPA-Metadata -IpaPath $DestPath
			if ($Meta) {
				$NewName = "$($Meta.AppName)_$($Meta.Version)_iOS $($Meta.MinIOS)+.ipa"
				$TargetFile = Join-Path (Get-Location) ".\Apps\$NewName"
				
				if (Test-Path $TargetFile) {
					Remove-Item $TargetFile -Force -ErrorAction SilentlyContinue
				}
				
				Rename-Item -Path $DestPath -NewName $NewName -Force
				Write-Host "$((Get-Lang 'FileName')) $NewName"
				Write-Host "$((Get-Lang 'MinIOS')) $($Meta.MinIOS)+"

				if (![string]::IsNullOrEmpty($AppId)) {
					Save-App-To-History -AppId $AppId -FinalFileName $NewName
				}
			}
		}
	}
}

# Универсальная функция валидации числового ввода:
function Test-NumericInput {
	param ([string]$InputValue)
	if ([string]::IsNullOrWhiteSpace($InputValue) -or $InputValue -notmatch '^\d+$') {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
		return $false
	}
	return $true
}

# Функция загрузки ipa-файлов:
function IPA-Download($AppId) {
	if (!(Test-NumericInput -InputValue $AppId)) { return }
	Separator
	.\MainApp\ipatool.exe download -i $AppId --purchase
	
	if ($LastExitCode -ne 0) {
		Separator
		Write-Host (Get-Lang "ErrorNotPurchased") -ForegroundColor Red
		return
	}
	Move-IPA-Files -AppId $AppId
}

# Функция загрузки ipa-файлов с выбором версии:
function IPA-Download-With-Version($AppId) {
	if (!(Test-NumericInput -InputValue $AppId)) { return }
	
	$RawOutput = .\MainApp\ipatool.exe list-versions -i $AppId 2>&1
	
	if ($RawOutput -match "license is required") {
		Separator
		Write-Host (Get-Lang "ErrorNotPurchased") -ForegroundColor Red
		return
	}

	$RawVersions = [regex]::Matches($RawOutput, '(?<=")\d+(?=")') | ForEach-Object { $_.Value }

	Separator
	$VersionsQuantity = Read-Host (Get-Lang "AskVerCount")`n
	
	$VerQty = 0
	if (![int]::TryParse($VersionsQuantity, [ref]$VerQty) -or $VerQty -le 0) {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
		return
	}

	$RecentVersions = $RawVersions | Select-Object -Last $VerQty
	[array]::Reverse($RecentVersions)
	$VersionMapping = @()
	$Counter = 1
	Separator
	Write-Host ("{0,-3} {1,-12} {2}" -f "№", (Get-Lang "HeaderVerID"), (Get-Lang "HeaderVersion"))
	foreach ($VersionId in $RecentVersions) {
		$Meta = .\MainApp\ipatool.exe get-version-metadata -i $AppId --external-version-id $VersionId 2>$null
		$DisplayVersion = if ($Meta -match 'displayVersion=([^\s,]+)') { $Matches[1] } else { "N/A" }
		Write-Host ("{0,-3} {1,-12} {2}" -f $Counter, $VersionId, $DisplayVersion)
		$VersionMapping += [PSCustomObject]@{ Index = $Counter; ID = $VersionId; Version = $DisplayVersion }
		$Counter++
	}
	Separator
	$Version = Read-Host "$((Get-Lang 'AskVerNum')) (1-$($VersionMapping.Count))`n"
	
	if (!(Test-NumericInput -InputValue $Version)) { return }

	$VersionInt = 0
	$IsInt = [int]::TryParse($Version, [ref]$VersionInt)

	$SelectedObject = $VersionMapping | Where-Object {
		($IsInt -and $_.Index -eq $VersionInt) -or $_.ID -eq $Version
	}

	if ($SelectedObject) {
		Separator
		Write-Host "$((Get-Lang 'SelectedVer')) $($SelectedObject.Version)"
		Separator
		$FinalId = $SelectedObject.ID
	} else {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
		return
	}
	.\MainApp\ipatool.exe download -i $AppId --external-version-id $FinalId
	Move-IPA-Files -AppId $AppId
}

# Функция получения списка выбранных приложений (поддерживает диапазоны и перечисления):
function Get-Apps-From-List {
	$List_Menu = @"
$((Get-Lang 'ListMenuTitle'))
$((Get-Lang 'ListMenu1'))
$((Get-Lang 'ListMenu2'))`n
"@
	$ListChoice = Read-Host ($List_Menu)

	$Lines = @()

	switch ($ListChoice) {
		"1" {
			try {
				$AppsIdList = Invoke-WebRequest "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt" -UseBasicParsing -ErrorAction Stop | Select-Object -Expand Content
				$Lines = $AppsIdList -split "`n" | Where-Object { $_.Trim() -ne "" }
			} catch {
				Write-Host (Get-Lang "ErrorListLoadError") -ForegroundColor Red
				return $null
			}
		}
		"2" {
			$HistoryFile = ".\Lists\Downloaded_IDs.json"
			
			if (!(Test-Path ".\Lists\Downloaded_IDs.json")) {
				Separator
				Write-Host (Get-Lang "ErrorHistoryEmpty") -ForegroundColor Red
				return $null
			}
			
			$JsonRaw = Get-Content $HistoryFile -Raw -Encoding UTF8
			if ([string]::IsNullOrWhiteSpace($JsonRaw)) {
				Separator
				Write-Host (Get-Lang "ErrorHistoryEmpty") -ForegroundColor Red
				return $null
			}
			$HistoryData = $JsonRaw | ConvertFrom-Json
			if ($HistoryData -eq $null) {
				Separator
				Write-Host (Get-Lang "ErrorHistoryEmpty") -ForegroundColor Red
				return $null
			}
			if ($HistoryData -isnot [System.Collections.IEnumerable]) {
				$HistoryData = @($HistoryData)
			}
			foreach ($Item in $HistoryData) {
				$Lines += "{0}: {1}" -f $Item.name, $Item.appid
			}
		}
		default {
			Separator
			Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
			return $null
		}
	}

	if ($Lines.Count -eq 0) {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
		return $null
	}

	Separator
	for ($i = 0; $i -lt $Lines.Count; $i++) {
		$Index = $i + 1
		Write-Host ("{0}. {1}" -f $Index, $Lines[$i])
	}
	Separator
	$Selection = Read-Host "$((Get-Lang 'AskAppNum')) (1-$($Lines.Count))`n"
	
	if ([string]::IsNullOrWhiteSpace($Selection)) {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
		return $null
	}

	$SelectedIndices = @()
	$Parts = $Selection -split ','

	foreach ($Part in $Parts) {
		$Part = $Part.Trim()
		if ($Part -match '^\d+-\d+$') {
			$Range = $Part -split '-'
			$Start = 0
			$End = 0
			# Безопасное чтение диапазона чисел без падений от переполнения:
			if (![int]::TryParse($Range[0], [ref]$Start) -or ![int]::TryParse($Range[1], [ref]$End)) {
				Separator
				Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
				return $null
			}
			if ($Start -le $End) { $SelectedIndices += $Start..$End } else { $SelectedIndices += $End..$Start }
		} elseif ($Part -match '^\d+$') {
			$Val = 0
			# Безопасное чтение одиночного числа:
			if (![int]::TryParse($Part, [ref]$Val)) {
				Separator
				Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
				return $null
			}
			$SelectedIndices += $Val
		} else {
			# Если введены другие символы:
			Separator
			Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
			return $null
		}
	}

	# Оставляем только уникальные индексы, входящие в диапазон списка:
	$SelectedIndices = $SelectedIndices | Select-Object -Unique | Where-Object { $_ -ge 1 -and $_ -le $Lines.Count }

	if ($SelectedIndices.Count -eq 0) {
		Separator
		Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
		return $null
	}

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
	$FilesToProcess = Get-ChildItem -Path ".\Apps\*.ipa" -ErrorAction SilentlyContinue
	if (-not $FilesToProcess) {
		Separator
		Write-Host (Get-Lang "ErrorNoApps") -ForegroundColor Red
		return
	}
	Separator
	Write-Host ("{0,-3} {1,-30} {2}" -f "№", (Get-Lang "HeaderFileName"), (Get-Lang "HeaderMinIOS"))
	$Counter = 1
	foreach ($File in $FilesToProcess) {
		$Meta = Get-IPA-Metadata -IpaPath $File.FullName
		$MinOs = if ($Meta) { "$($Meta.MinIOS)+" } else { "Error" }
		$PrintName = if ($File.Name.Length -gt 30) { $File.Name.Substring(0,22) + "..." } else { $File.Name }
		Write-Host ("{0,-3} {1,-30} {2}" -f $Counter, $PrintName, $MinOs)
		$Counter++
	}
}

# Вход с Apple ID:
Connect-AppleID

# Основной цикл:
while (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Separator
	# Динамическая сборка меню на выбранном языке
	$MainMenu = @"
$((Get-Lang 'MenuTitle'))
$((Get-Lang 'Menu1'))
$((Get-Lang 'Menu2'))
$((Get-Lang 'Menu3'))
$((Get-Lang 'Menu4'))
$((Get-Lang 'Menu5'))
$((Get-Lang 'Menu6'))
$((Get-Lang 'Menu7'))
$((Get-Lang 'Menu8'))
$((Get-Lang 'Menu9'))
$((Get-Lang 'Menu10'))
$((Get-Lang 'Menu11'))`n
"@

	$SwitchValue = Read-Host $MainMenu
	switch ($SwitchValue) {
		# 1. Поиск приложения и загрузка последней версии:
		"1" {
			Separator
			$AppName = Read-Host (Get-Lang "AskSearch")`n
			.\MainApp\ipatool.exe search $AppName --limit 10 2> $null
			Separator
			$AppId = Read-Host (Get-Lang "AskIdDownload")`n
			IPA-Download $AppId
		}
		
		# 2. Ввод ID приложения и загрузка последней версии:
		"2" {
			Separator
			$AppId = Read-Host (Get-Lang "AskIdDownload")`n
			IPA-Download $AppId
		}
		
		# 3. Ввод ID приложения и загрузка (с выбором версии):
		"3" {
			Separator
			$AppId = Read-Host (Get-Lang "AskIdSearch")`n
			IPA-Download-With-Version $AppId
		}
		
		# 4. Вывод списка ID приложений и загрузка последней версии:
		"4" {
			Separator
			$SelectedApps = Get-Apps-From-List
			if ($null -ne $SelectedApps) {
				foreach ($App in $SelectedApps) {
					Separator
					Write-Host "$((Get-Lang 'SelectedApp')) $($App.Name)"
					IPA-Download $App.Id
				}
			}
		}
		
		# 5. Вывод списка ID приложений и загрузка (с выбором версии):
		"5" {
			Separator
			$SelectedApps = Get-Apps-From-List
			if ($null -ne $SelectedApps) {
				foreach ($App in $SelectedApps) {
					Separator
					Write-Host "$((Get-Lang 'SelectedApp')) $($App.Name)"
					IPA-Download-With-Version $App.Id
				}
			}
		}
		
		# 6. Показать минимальную версию iOS для ipa-файлов в папке Apps:
		"6" {
			Get-iOS-MinVersion
		}
		
		# 7. Установка приложений, загруженных в папку Apps:
		"7" {
			if (Test-Path ".\Apps\*.ipa") {
				Get-ChildItem ".\Apps\*.ipa" | ForEach-Object {
					Separator
					.\MainApp\ideviceinstaller.exe install "$($_.FullName)"
				}
			} else {
				Separator
				Write-Host (Get-Lang "ErrorNoApps") -ForegroundColor Red
			}
		}
		
		
		# 8. Очистка данных скрипта:
		"8" {
			Separator
			$Clear_Menu = @"
$((Get-Lang 'ClearMenuTitle'))
$((Get-Lang 'ClearMenu1'))
$((Get-Lang 'ClearMenu2'))`n
"@
			$ClearChoice = Read-Host ($Clear_Menu)
			switch ($ClearChoice) {
				# 1. Очистка списка ранее загруженных приложений
				"1" {
					Remove-Item ".\Lists\Downloaded_IDs.json" -Force -ErrorAction SilentlyContinue
					Separator
					Write-Host (Get-Lang "ListCleared")
				}
				
				# 2. Очистка папки Apps:
				"2" {
					if (Test-Path ".\Apps\*.ipa") {
						Remove-Item ".\Apps\*" -Force -ErrorAction SilentlyContinue
						Separator
						Write-Host (Get-Lang "AppsCleared")
					} else {
						Separator
						Write-Host (Get-Lang "ErrorNoApps") -ForegroundColor Red
					}
				}
				
				default {
					Separator
					Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
				}
			}
		}
		
		# 9. Выход из аккаунта Apple ID:
		"9" {
			Separator
			Write-Host (Get-Lang "LoggedOut")
			.\MainApp\ipatool.exe auth revoke
			Connect-AppleID
		}
		
		# 10. Страница проекта на GitHub:
		"10" {
			Start-Process "https://github.com/kda2495/IPA_Downloader"
		}
		
		# 11. Сменить язык (Change Language):
		"11" {
			$Global:CurrentLang = if ($Global:CurrentLang -eq "RU") {"EN" } else { "RU" }
			Set-Content -Path $LangConfigFile -Value $Global:CurrentLang -Force
			Separator
			Write-Host (Get-Lang "LangChanged")
		}
		
		# Неверный ввод:
		default {
			Separator
			Write-Host (Get-Lang "ErrorInvalidInput") -ForegroundColor Red
		}
	}
}
