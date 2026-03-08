[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/latest/IPA_Downloader.zip?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)

# IPA_Downloader
Скрипт для загрузки приложений из истории покупок Apple ID и установки на устройства Apple (работает с [IPATool](https://github.com/majd/ipatool)).

## Требования:
• Windows 10/11  
• Интернет-соединение  
• Apple ID с ранее загруженными приложениями  

## Как использовать:
1\. Дважды кликните по файлу `Start_IPA_Downloader.bat`  
2\. При первом запуске потребуется вход в Apple ID:  
• Введите Apple ID  
• Пароль (INF enter password)  
• Код двухфакторной аутентификации (INF enter 2FA code)  

**Обратите внимание:**  
• Пароль **не отображается при вводе** (в целях безопасности)  
• Все действия в скрипте подтверждаются нажатием клавиши Enter  
• Все загруженные приложения сохраняются в папку `IPA_Downloader/Apps`. Имя файла содержит ID и версию приложения.  

## Описание команд скрипта:
#### 1. Поиск приложения и загрузка последней версии
• Введите название приложения для поиска  
• Скрипт отобразит результаты поиска  
• Для загрузки введите ID приложения, когда появится запрос: `Введите ID приложения для загрузки`
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 1" src="https://github.com/user-attachments/assets/21d3e1a0-de3d-4200-a5ab-7269064eecec" />
</details>

#### 2. Ввод ID приложения и загрузка последней версии
• Для загрузки введите ID приложения, когда появится запрос: `Введите ID приложения для загрузки`
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 2" src="https://github.com/user-attachments/assets/7d272e2c-08c6-4d8d-b9be-bd51d1afc998" />
</details>

#### 3. Ввод ID приложения и загрузка (с выбором версии)
• Для загрузки введите ID приложения, когда появится запрос: `Введите ID приложения для поиска`  
• Скрипт отобразит список доступных версий через запятую (версии отсортированы по возрастанию от старой к новой)  
• Введите нужную версию
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 3" src="https://github.com/user-attachments/assets/2b84a46a-ae9c-4715-a185-b2111af68bc0" />
</details> 

**Важное замечание.** Если приложение недоступно в вашем регионе, то при наличии обновления в AppStore оно будет отображаться, но при попытке обновления будет ошибка.  
Для обновления необходимо удалить старую версию приложения, загрузить новую версию через IPA_Downloader и заново установить.

#### 4. Вывод списка ID приложений и загрузка последней версии
• Отобразится список приложений  
• Для загрузки введите порядковый номер приложения или его ID, когда появится запрос: `Введите номер или ID приложения для загрузки`  
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 4" src="https://github.com/user-attachments/assets/e1c662bd-57b7-4b53-854b-6fdd3658fbe7" />
</details>

#### 5. Вывод списка ID приложений и загрузка (с выбором версии)
• Отобразится список приложений  
• Для загрузки введите порядковый номер приложения или его ID, когда появится запрос: `Введите номер или ID приложения для поиска`  
• Скрипт отобразит список доступных версий через запятую (версии отсортированы по возрастанию от старой к новой)  
• Введите нужную версию
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 5" src="https://github.com/user-attachments/assets/31a2233e-7e03-4acd-bce8-20105a2b9fca" />
</details>

**Важное замечание.** Если приложение недоступно в вашем регионе, то при наличии обновления в AppStore оно будет отображаться, но при попытке обновления будет ошибка.  
Для обновления необходимо удалить старую версию приложения, загрузить новую версию через IPA_Downloader и заново установить.

#### 6. Установить приложения, загруженные в папку Apps
• Предварительно необходимо установить iTunes с официального сайта Apple, либо пакет драйверов AppleMobileDeviceSupport (идут в комплекте с iTunes):  
[Скачать iTunes (официальный сайт Apple)](https://www.apple.com/itunes/download/win64)  
• Для установки необходимо подключить устройство к ПК через USB и разрешить подключение  
• Скрипт установит все приложения, находящиеся в папке Apps

#### 7. Очистить папку Apps
• Скрипт очистит папку Apps со всеми загруженными приложениями
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="978" height="340" alt="Команда 6" src="https://github.com/user-attachments/assets/0f29fc78-eecd-45be-b557-44321589bada" />
</details>

#### 8. Отозвать Apple ID из IPATool
• Скрипт выполнит выход из Apple ID
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="978" height="511" alt="Команда 7" src="https://github.com/user-attachments/assets/332354e2-4064-463b-97de-b96f55db34e9" />
</details>

#### 9. Перейти на страницу проекта в GitHub
• Скрипт откроет страницу проекта на GitHub

## Как найти ID приложения:
Для поиска ID приложения, необходимо знать его ссылку в AppStore (к примеру, ищем в поисковике приложение, находим ссылку в AppStore и из ссылки необходимо взять числовой идентификатор после `id`).  
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

Также можно найти приложения через сайт [appmagic.rocks](https://appmagic.rocks/top-charts/apps) (вверху справа вводим название приложения в поле Search for app or publisher...), далее переходим на страницу приложения и в ссылке будет номер ID.  

Список ID актуальных приложений также можно вывести с помощью команд 4 и 5.  

## В чем плюсы данного скрипта в сравнении с iMazing?
Данный скрипт позволяет загрузить любые приложения, которые ранее загружались под Apple ID (даже недоступные в данный момент в российском регионе, либо удаленные из AppStore), а не только те, что видит iMazing (за определенное время).  
К примеру, некоторые приложения были загружены мной ещё в 2020 году, iMazing их не видит для установки, а данный скрипт позволяет загрузить их и установить.

## Поддержка Windows 7:
1\. Для добавления поддержки IPATool, необходимо применить к ipatool.exe данный патч:  
[GoWin7Fixer](https://github.com/stunndard/golangwin7patch/releases/tag/v0.2)  
Запускаете GoWin7Fixer.exe и либо переносите ipatool.exe прямо на окно с программой, либо нажимаете Open и указываете путь к ipatool.exe.
<details>
<summary>Скриншот (нажмите для просмотра)</summary>
<img width="878" height="595" alt="5" src="https://github.com/user-attachments/assets/64d4086b-4f96-4f56-a2b3-be308f8b34bf" />
</details>

2\. Для добавления поддержки PowerShell 3.0 необходимо установить обновление KB2506143:  
[Ссылка для загрузки](https://www.microsoft.com/en-us/download/details.aspx?id=34595)  
Для Windows 7 x64: Windows6.1-KB2506143-x64.msu  
Для Windows 7 x86: Windows6.1-KB2506143-x86.msu  
<details>
 <summary>Скриншот</summary>
<img width="972" height="617" alt="4" src="https://github.com/user-attachments/assets/586ad840-6f3f-4d6d-9f73-fda18b838642" />
</details>
Без данного обновления не будет доступна загрузка списка приложений через команды 4-5.

## Поддержка проекта:
IPA_Downloader полностью бесплатен, однако, если вы хотите безвозмездно поддержать проект, то можно это сделать по следующим реквизитам:  
[Поддержать через CloudTips](https://pay.cloudtips.ru/p/93c0b094)  

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
