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
#Устанавливаем шрифт Consolas и кодировку UTF8:
[ConsoleFont]::SetFont("Consolas", 16)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "IPA_Downloader 3.3" -ForegroundColor Black -BackgroundColor Yellow
#Функция разделителя:
function Separator {
	Write-Host "========================================" -ForegroundColor Green
}
#Проверка на наличие папки Apps:
if (!(Test-Path ".\Apps")) {
	$null = New-Item -Path ".\Apps" -ItemType "Directory" -Force
}
#Проверка на наличие папки .ipatool:
if (!(Test-Path "$env:USERPROFILE\.ipatool")) {
	$null = New-Item -Path "$env:USERPROFILE\.ipatool" -ItemType "Directory"
}
#Проверка на наличие всех необходимых файлов для работы:
$CheckMainAppFiles = @(
	"ipatool.exe",
	"ideviceinstaller.exe"
)
$MissingMainAppFiles = @()
foreach ($file in $CheckMainAppFiles) {
	if (!(Test-Path ".\MainApp\$file")) {
		$MissingMainAppFiles += $file
	}
}
if ($MissingMainAppFiles.Count -gt 0) {
	Separator
	Write-Host "Ошибка: Следующие файлы не найдены в папке MainApp:" -ForegroundColor Red
	$MissingMainAppFiles | ForEach-Object { Write-Host "$_" -ForegroundColor Red }
	Read-Host "Нажмите Enter для выхода"
	exit
}
#Удаление файлов .ipa.tmp при запуске (в случае неудачной загрузки приложения):
if (Get-ChildItem -Filter "*.ipa.tmp") {
	Remove-Item ".\*.ipa.tmp" -Force -ErrorAction SilentlyContinue
}
#Проверка на Windows 7 и включение TLS 1.2 для запросов:
$OSVersion = [System.Environment]::OSVersion.Version
if ($OSVersion.Major -eq 6 -and $OSVersion.Minor -eq 1) {
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
#Проверка наличия файла account в папке .ipatool:
if (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Separator
	Write-Host "Вход в аккаунт Apple ID выполнен.`nДанные аккаунта Apple ID:"
	.\MainApp\ipatool.exe auth info
}
#Функция входа в аккаунт Apple ID:
function Connect-AppleID {
	while (!(Test-Path "$env:USERPROFILE\.ipatool\account")) {
		Remove-Item "$env:USERPROFILE\.ipatool\cookies" -Force -ErrorAction SilentlyContinue
		Separator
		Write-Host "Вход в аккаунт Apple ID не выполнен."
		.\MainApp\ipatool.exe auth login
	}
}
#Функция перемещения загруженных файлов в папку Apps:
function Move-IPA-Files {
	$IPAFiles = Get-ChildItem -Filter "*.ipa"
	if ($IPAFiles) {
		foreach ($file in $IPAFiles) {
			$DestPath = Join-Path (Get-Location) ".\Apps\$($file.Name)"
			Move-Item -Path $file.FullName -Destination $DestPath -Force
			Separator
			Write-Host "Готово. Файл сохранен в папку Apps." -ForegroundColor Green
			Get-iOS-MinVersion -SpecificFile $DestPath
		}
	}
}
#Универсальная функция валидации числового ввода:
function Test-NumericInput {
	param (
		[string]$InputValue,
		[string]$Type
	)
	if ([string]::IsNullOrWhiteSpace($InputValue)) {
		if ($Type -eq "ID") {
			Write-Host "Ошибка: ID приложения не введен." -ForegroundColor Red
		} elseif ($Type -eq "VersionsQuantity") {
			Write-Host "Ошибка: Количество версий для отображения не введено." -ForegroundColor Red
		}
		return $false
	}
	if ($InputValue -notmatch '^\d+$') {
		if ($Type -eq "ID") {
			Write-Host "Ошибка: Введен неверный ID приложения." -ForegroundColor Red
		} elseif ($Type -eq "VersionsQuantity") {
			Write-Host "Ошибка: Количество версий для отображения введено неверно." -ForegroundColor Red
		}
		return $false
	}
	return $true
}
#Функция загрузки ipa-файлов:
function IPA-Download($AppID) {
	if (!(Test-NumericInput -InputValue $AppID -Type "ID")) { return }
	Separator
	.\MainApp\ipatool.exe download -i $AppID --purchase
	Move-IPA-Files
}
#Функция загрузки ipa-файлов с выбором версии:
function IPA-Download-With-Version($AppID) {
	if (!(Test-NumericInput -InputValue $AppID -Type "ID")) { return }
	#Получаем список ID:
	$RawOutput = .\MainApp\ipatool.exe list-versions -i $AppID 2>$null
	#Если вывод пустой, сразу выходим:
	if ([string]::IsNullOrEmpty($RawOutput)) {
		Write-Host "Ошибка: Введен неверный ID приложения." -ForegroundColor Red
		return
	}
	#Извлекаем ID версий только если RawOutput не пуст:
	$RawVersions = [regex]::Matches($RawOutput, '(?<=")\d+(?=")') | ForEach-Object { $_.Value }
	#Запрос количества версий:
	Separator
	$VersionsQuantity = Read-Host "Введите количество версий для отображения"
	if (!(Test-NumericInput -InputValue $VersionsQuantity -Type "VersionsQuantity")) { return }
	if ([int]$VersionsQuantity -le 0) {
		Write-Host "Ошибка: Количество версий должно быть больше 0." -ForegroundColor Red
		return
	}
	$RecentVersions = $RawVersions | Select-Object -Last $VersionsQuantity
	[array]::Reverse($RecentVersions)
	$VersionMapping = @()
	$Counter = 1
	Separator
	Write-Host ("{0,-3} {1,-12} {2}" -f "№", "ID версии", "Версия")
	foreach ($VersionID in $RecentVersions) {
		#Запрос метаданных:
		$Meta = .\MainApp\ipatool.exe get-version-metadata -i $AppID --external-version-id $VersionID 2>$null
		$DisplayVersion = if ($Meta -match 'displayVersion=([^\s,]+)') { $Matches[1] } else { "N/A" }
		Write-Host ("{0,-3} {1,-12} {2}" -f $Counter, $VersionID, $DisplayVersion)
		$VersionMapping += [PSCustomObject]@{ Index = $Counter; ID = $VersionID; Version = $DisplayVersion }
		$Counter++
	}
	Separator
	$MaxIndex = $VersionMapping.Count
	$Version = Read-Host "Введите номер (1-$MaxIndex) или введите ID версии"
	Separator
	if ([string]::IsNullOrWhiteSpace($Version)) {
		Write-Host "Ошибка: Номер или ID версии не введен." -ForegroundColor Red
		return $null
	}
	#Ищем совпадение по порядковому номеру или по точному ID версии:
	$SelectedObject = $VersionMapping | Where-Object { $_.Index -eq $Version -or $_.ID -eq $Version }
	if ($SelectedObject) {
		Write-Host "Выбрана версия: $($SelectedObject.Version)"
		Separator
		$FinalID = $SelectedObject.ID
	} else {
		#Если ввод не совпал ни с индексом, ни с существующим ID в списке:
		Write-Host "Ошибка: Неверный ввод. Введите число от 1 до $MaxIndex." -ForegroundColor Red
		return
	}
	.\MainApp\ipatool.exe download -i $AppID --external-version-id $FinalID
	Move-IPA-Files
}
#Функция получения списка приложений со страницы проекта на GitHub:
function Get-AppID-From-List {
	try {
		$AppsIDList = Invoke-WebRequest "https://raw.githubusercontent.com/kda2495/IPA_Downloader/refs/heads/main/Apps_ID_List.txt" -UseBasicParsing -ErrorAction Stop | Select-Object -Expand Content
	} catch {
		Write-Host "Ошибка загрузки списка приложений." -ForegroundColor Red
		return $null
	}
	$Lines = $AppsIDList -split "`n" | Where-Object { $_.Trim() -ne "" }
	for ($i = 0; $i -lt $Lines.Count; $i++) {
		$Index = $i + 1
		Write-Host ("{0}. {1}" -f $Index, $Lines[$i])
	}
	Separator
	$Selection = Read-Host "Введите номер (1-$($Lines.Count)) или ID приложения для загрузки"
	Separator
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
	}
	elseif ($Selection -match '^\d+$' -and $Selection.Length -lt 6) {
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
		Separator
		return $AppID.Trim()
	}
	else {
		Write-Host "Ошибка: Введите номер или ID приложения." -ForegroundColor Red
		return $null
	}
}
#Функция проверки минимальной версии iOS для файлов в папке Apps:
function Get-iOS-MinVersion {
	param (
		[string]$SpecificFile = $null
	)
	if (![string]::IsNullOrWhiteSpace($SpecificFile)) {
		$FilesToProcess = @(Get-Item -Path $SpecificFile -ErrorAction SilentlyContinue)
	} else {
		$FilesToProcess = Get-ChildItem -Path ".\Apps\*.ipa" -ErrorAction SilentlyContinue
	}
	if (-not $FilesToProcess) {
		Write-Host "В папке Apps нет приложений." -ForegroundColor Red
		return
	}
	Add-Type -AssemblyName System.IO.Compression.FileSystem
	Separator
	Write-Host ("{0,-3} {1,-25} {2}" -f "№", "Название файла", "Мин. iOS")
	$Counter = 1
	foreach ($file in $FilesToProcess) {
		$iOSmin = "N/A"
		try {
			$Zip = [System.IO.Compression.ZipFile]::OpenRead($file.FullName)
			$PlistEntry = $Zip.Entries | Where-Object { $_.FullName -match 'Payload/.*\.app/Info\.plist$' } | Select-Object -First 1
			if ($PlistEntry) {
				$Reader = New-Object System.IO.StreamReader($PlistEntry.Open())
				$Content = $Reader.ReadToEnd()
				$Reader.Close()
				if ($Content -match '<key>MinimumOSVersion</key>\s*<string>([^<]+)</string>') {
					$iOSmin = $Matches[1]
				}
			}
			$Zip.Dispose()
		} catch { $iOSmin = "Error" }
		$PrintName = if ($file.Name.Length -gt 25) { $file.Name.Substring(0,22) + "..." } else { $file.Name }
		Write-Host ("{0,-3} {1,-25} {2}" -f $Counter, $PrintName, "$iOSmin+")
		$Counter++
	}
}
#Вход с Apple ID:
Connect-AppleID
#Вывод меню:
$MainMenu = @"
Введите команду:
1. Поиск приложения и загрузка последней версии
2. Ввод ID приложения и загрузка последней версии
3. Ввод ID приложения и загрузка (с выбором версии)
4. Вывод списка ID приложений и загрузка последней версии
5. Вывод списка ID приложений и загрузка (с выбором версии)
6. Показать минимальную версию iOS для ipa-файлов в папке Apps
7. Установка приложений, загруженных в папку Apps
8. Очистка папки Apps
9. Выход из аккаунта Apple ID
10. Страница проекта на GitHub`n
"@
#Работа скрипта, если вход с Apple ID выполнен:
while (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Separator
	$SwitchValue = Read-Host $MainMenu
	#Пункты меню:
	switch ($SwitchValue) {
		#1. Поиск приложения и загрузка последней версии:
		1 {
			Separator
			$AppName = Read-Host "Введите название приложения для поиска"
			Separator
			.\MainApp\ipatool.exe search $AppName --limit 10 2> $null
			Separator
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		#2. Ввод ID приложения и загрузка последней версии:
		2 {
			Separator
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		#3. Ввод ID приложения и загрузка (с выбором версии):
		3 {
			Separator
			$AppID = Read-Host "Введите ID приложения для поиска"
			IPA-Download-With-Version $AppID
		}
		#4. Вывод списка ID приложений и загрузка последней версии:
		4 {
			Separator
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download $AppID
			}
		}
		#5. Вывод списка ID приложений и загрузка (с выбором версии):
		5 {
			Separator
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download-With-Version $AppID
			}
		}
		#6. Показать минимальную версию iOS для ipa-файлов в папке Apps:
		6 {
			Get-iOS-MinVersion
		}
		#7. Установка приложений, загруженных в папку Apps:
		7 {
			if (Test-Path ".\Apps\*.ipa") {
				Get-ChildItem ".\Apps\*.ipa" | ForEach-Object {
					.\MainApp\ideviceinstaller.exe install "$($_.FullName)"
				}
			}
			else {
				Write-Host "Ошибка: В папке Apps отсутствуют приложения." -ForegroundColor Red
			}
		}
		
		#8. Очистка папки Apps:
		8 {
			Remove-Item ".\Apps\*" -Force -ErrorAction SilentlyContinue
			Separator
			Write-Host "Готово. Файлы в папке Apps удалены." -ForegroundColor Green
		}
		#9. Отзыв Apple ID из IPATool:
		9 {
			Separator
			Write-Host "Выполнен выход из аккаунта Apple ID."
			.\MainApp\ipatool.exe auth revoke
			Connect-AppleID
		}
		#10. Страница проекта на GitHub:
		10 {
			Start-Process "https://github.com/kda2495/IPA_Downloader"
		}
		#Стандартный вывод в случае ввода неверного пункта меню:
		default {
			Write-Host "Неверный ввод. Попробуйте снова." -ForegroundColor Red
		}
	}
}
