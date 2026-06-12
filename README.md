[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/latest/total?label=Downloads%20(latest)&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)

# IPA_Downloader
[![English README](https://img.shields.io/badge/README-English-blue.svg)](README_EN.md)  
PowerShell-скрипт для загрузки ранее приобретенных приложений из App Store и их установки на устройства Apple (работает на базе [ipatool-cpp](https://github.com/Sorvigolova/ipatool)).

## Требования:
• Windows 7-11 x64  
• Установленный драйвер AppleMobileDeviceSupport (входит в состав iTunes):  
[Ссылка для загрузки iTunes](https://www.apple.com/itunes/download/win64)  
Вместо полной установки iTunes можно выполнить выборочную установку AppleMobileDeviceSupport64.msi, распаковав установщик iTunes любым архиватором  
• Интернет-соединение  
• Аккаунт Apple ID с ранее загруженными приложениями  

## Возможности:
• Поиск приложения и покупка  
• Поиск приложения и загрузка последней версии  
• Поиск приложения и загрузка (с выбором версии)  
• Ввод ID приложений и покупка  
• Ввод ID приложений и загрузка последней версии  
• Ввод ID приложений и загрузка (с выбором версии)  
• Вывод списка ID приложений и покупка  
• Вывод списка ID приложений и загрузка последней версии  
• Вывод списка ID приложений и загрузка (с выбором версии)  
• Проверка минимальной версии iOS для приложений в папке Apps  
• Установка приложений из папки Apps  

#### Примечание:  
В командах с вводом ID доступен ввод нескольких ID приложений в формате 1, 2, 3.  
В командах с выбором версии для загрузки доступен ввод нескольких версий приложения в формате 1, 2, 3-5.  
В командах с выводом списка ID доступен ввод нескольких приложений в формате 1, 2, 3-5.  

## Как использовать:
1\. Дважды кликните по файлу `Start_IPA_Downloader.bat`  
2\. При первом запуске потребуется вход в Apple ID:  
• Введите Apple ID (Enter email)  
• Пароль (Enter password)  
• Код двухфакторной аутентификации (Enter 2FA code)  
3\. Введите необходимую команду

## Прочая информация:
### Поддержка Windows 7:
1\. Обновить системные сертификаты через UpdRootsCert:  
[Ссылка для загрузки UpdRootsCert](https://disk.yandex.ru/d/SdHMgwJ55MTQRg)
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="521" height="407" alt="UpdRootsCert" src="https://github.com/user-attachments/assets/437390c2-f820-4caa-b679-30377b388c72" />
</details>

2\. Установить .NET Framework 4.8:  
[Ссылка для загрузки .NET Framework 4.8](https://go.microsoft.com/fwlink/?linkid=2088631)

3\. Установить обновление KB3191566 (для добавления поддержки PowerShell 5.1):  
[Ссылка для загрузки KB3191566](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="973" height="616" alt="KB3191566" src="https://github.com/user-attachments/assets/940968fc-359f-4ed6-a6d4-2ca834fc989b" />
</details>

### Отслеживание выхода новых приложений:
[Сайт AppBank](https://pwa.appbank.pw/)  
[Telegram-канал AppBank](https://t.me/appbankRu)  

### Поиск ID приложения:
Найдите ссылку на приложение в AppStore и скопируйте числовой идентификатор (значение после `id` в URL-адресе).  
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

## Поддержка проекта:
IPA_Downloader полностью бесплатен, однако, если вы хотите безвозмездно поддержать проект, то можно это сделать по следующим реквизитам:  
[Поддержать через CloudTips](https://pay.cloudtips.ru/p/93c0b094)  

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
