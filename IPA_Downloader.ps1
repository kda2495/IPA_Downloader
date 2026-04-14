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
Write-Host "IPA_Downloader 3.1" -ForegroundColor Black -BackgroundColor Yellow
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
	Write-Host "========================================" -ForegroundColor Green
	Write-Host "Вход в аккаунт Apple ID выполнен.`nДанные аккаунта Apple ID:"
	.\MainApp\ipatool.exe auth info
}
#Функция входа в аккаунт Apple ID:
function Connect-AppleID {
	while (!(Test-Path "$env:USERPROFILE\.ipatool\account")) {
		Remove-Item "$env:USERPROFILE\.ipatool\cookies" -Force -ErrorAction SilentlyContinue
		Write-Host "========================================" -ForegroundColor Green
		Write-Host "Вход в аккаунт Apple ID не выполнен."
		.\MainApp\ipatool.exe auth login
	}
}
#Функция перемещения загруженных файлов в папку Apps:
function Move-IPA-Files {
	$IPAFiles = Get-ChildItem -Filter "*.ipa"
	if ($IPAFiles) {
		$IPAFiles | Move-Item -Destination ".\Apps" -Force
		Write-Host "Готово. Файл сохранен в папку Apps." -ForegroundColor Green
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
		} else {
			Write-Host "Ошибка: Версия приложения не введена." -ForegroundColor Red
		}
		return $false
	}
	if ($InputValue -notmatch '^\d+$') {
		if ($Type -eq "ID") {
			Write-Host "Ошибка: ID приложения должен состоять только из цифр." -ForegroundColor Red
		} else {
			Write-Host "Ошибка: Версия приложения должна состоять только из цифр." -ForegroundColor Red
		}
		return $false
	}
	return $true
}
#Функция загрузки ipa файлов:
function IPA-Download($AppID) {
	if (!(Test-NumericInput -InputValue $AppID -Type "ID")) {
		return
	}
	.\MainApp\ipatool.exe download -i $AppID --purchase
	Move-IPA-Files
}
#Функция загрузки ipa файлов с выбором версии:
function IPA-Download-With-Version($AppID) {
	if (!(Test-NumericInput -InputValue $AppID -Type "ID")) {
		return
	}
	.\MainApp\ipatool.exe list-versions -i $AppID
	$AppVersion = Read-Host "Введите версию приложения для загрузки"
	if (!(Test-NumericInput -InputValue $AppVersion -Type "Version")) {
		return
	}
	.\MainApp\ipatool.exe get-version-metadata -i $AppID --external-version-id $AppVersion
	.\MainApp\ipatool.exe download -i $AppID --external-version-id $AppVersion
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
	$Selection = Read-Host "Введите номер (1-$($Lines.Count)) или ID приложения для загрузки"
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
		return $AppID.Trim()
	}
	else {
		Write-Host "Ошибка: Введите номер или ID приложения." -ForegroundColor Red
		return $null
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
6. Установка приложений, загруженных в папку Apps
7. Очистка папки Apps
8. Выход из аккаунта Apple ID
9. Страница проекта на GitHub`n
"@
#Работа скрипта, если вход с Apple ID выполнен:
while (Test-Path "$env:USERPROFILE\.ipatool\account") {
	Write-Host "========================================" -ForegroundColor Green
	$SwitchValue = Read-Host $MainMenu
	#Пункты меню:
	switch ($SwitchValue) {
		#1. Поиск приложения и загрузка последней версии:
		1 {
			Write-Host "========================================" -ForegroundColor Green
			$AppName = Read-Host "Введите название приложения для поиска"
			.\MainApp\ipatool.exe search $AppName --limit 10 2> $null
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		#2. Ввод ID приложения и загрузка последней версии:
		2 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для загрузки"
			IPA-Download $AppID
		}
		#3. Ввод ID приложения и загрузка (с выбором версии):
		3 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Read-Host "Введите ID приложения для поиска"
			IPA-Download-With-Version $AppID
		}
		#4. Вывод списка ID приложений и загрузка последней версии:
		4 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download $AppID
			}
		}
		#5. Вывод списка ID приложений и загрузка (с выбором версии):
		5 {
			Write-Host "========================================" -ForegroundColor Green
			$AppID = Get-AppID-From-List
			if ($null -ne $AppID) {
				IPA-Download-With-Version $AppID
			}
		}
		#6. Установка приложений, загруженных в папку Apps:
		6 {
			if (Test-Path ".\Apps\*.ipa") {
				Get-ChildItem ".\Apps\*.ipa" | ForEach-Object {
					.\MainApp\ideviceinstaller.exe install "$($_.FullName)"
				}
			}
			else {
				Write-Host "Ошибка: В папке Apps отсутствуют приложения." -ForegroundColor Red
			}
		}
		#7. Очистка папки Apps:
		7 {
			Remove-Item ".\Apps\*" -Force -ErrorAction SilentlyContinue
			Write-Host "========================================" -ForegroundColor Green
			Write-Host "Готово. Файлы в папке Apps удалены." -ForegroundColor Green
		}
		#8. Отзыв Apple ID из IPATool:
		8 {
			Write-Host "========================================" -ForegroundColor Green
			Write-Host "Выполнен выход из аккаунта Apple ID."
			.\MainApp\ipatool.exe auth revoke
			Connect-AppleID
		}
		#9. Страница проекта на GitHub:
		9 {
			Start-Process "https://github.com/kda2495/IPA_Downloader"
		}
		#Стандартный вывод в случае ввода неверного пункта меню:
		default {
			Write-Host "Неверный ввод. Попробуйте снова." -ForegroundColor Red
		}
	}
}
