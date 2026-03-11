[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)

# IPA_Downloader
Скрипт для загрузки приложений из истории покупок Apple ID и установки на устройства Apple (работает на базе [IPATool](https://github.com/majd/ipatool)).

## Требования:
• Windows 10/11 x64  
• Установленный драйвер AppleMobileDeviceSupport (входит в состав iTunes):  
[Ссылка для загрузки iTunes](https://www.apple.com/itunes/download/win64)  
• Интернет-соединение  
• Аккаунт Apple ID с ранее загруженными приложениями  

## Как использовать:
**1\. Дважды кликните по файлу `Start_IPA_Downloader.bat`**  
**2\. При первом запуске потребуется вход в Apple ID:**  
• Введите Apple ID  
• Пароль (INF enter password)  
• Код двухфакторной аутентификации (INF enter 2FA code)  

**Обратите внимание:**  
• Пароль **не отображается при вводе** (в целях безопасности)  
• Все действия в скрипте подтверждаются нажатием клавиши Enter  
• Все загруженные приложения сохраняются в папку `IPA_Downloader/Apps`  
• Имя загруженного файла содержит ID и версию приложения  

## Описание команд скрипта:
#### 1. Поиск приложения и загрузка последней версии
• Введите название приложения для поиска  
• Скрипт отобразит результаты поиска  
• Для загрузки введите ID приложения, когда появится запрос: `Введите ID приложения для загрузки`
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 1" src="https://github.com/user-attachments/assets/ca585876-648c-49d8-a9b8-7647f6053ce1" />
</details>

#### 2. Ввод ID приложения и загрузка последней версии
• Для загрузки введите ID приложения, когда появится запрос: `Введите ID приложения для загрузки`
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 2" src="https://github.com/user-attachments/assets/62676fa0-d66c-41e0-be21-eb6f58fa7dc5" />
</details>

#### 3. Ввод ID приложения и загрузка (с выбором версии)
• Для загрузки введите ID приложения, когда появится запрос: `Введите ID приложения для поиска`  
• Скрипт отобразит список доступных версий через запятую (версии отсортированы по возрастанию от старой к новой)  
• Введите нужную версию
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 3" src="https://github.com/user-attachments/assets/929b2a2d-be0e-4167-817b-9792d267bef5" />
</details> 

**Важное замечание:**  
Если приложение недоступно в вашем регионе, то при наличии обновления в AppStore оно будет отображаться, но при попытке обновления будет ошибка.  
Для обновления необходимо удалить старую версию приложения, загрузить новую версию через IPA_Downloader и заново установить.

#### 4. Вывод списка ID приложений и загрузка последней версии
• Отобразится список приложений  
• Для загрузки введите порядковый номер приложения или его ID, когда появится запрос: `Введите номер или ID приложения для загрузки`  
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="511" alt="Команда 4" src="https://github.com/user-attachments/assets/9cda70ad-657c-471c-ba10-303bd49ac418" />
</details>

#### 5. Вывод списка ID приложений и загрузка (с выбором версии)
• Отобразится список приложений  
• Для загрузки введите порядковый номер приложения или его ID, когда появится запрос: `Введите номер или ID приложения для поиска`  
• Скрипт отобразит список доступных версий через запятую (версии отсортированы по возрастанию от старой к новой)  
• Введите нужную версию
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 5" src="https://github.com/user-attachments/assets/a22f2c8f-3c50-4dfb-be86-94c893837f45" />
</details>

**Важное замечание:**  
Если приложение недоступно в вашем регионе, то при наличии обновления в AppStore оно будет отображаться, но при попытке обновления будет ошибка.  
Для обновления необходимо удалить старую версию приложения, загрузить новую версию через IPA_Downloader и заново установить.

#### 6. Установка приложений, загруженных в папку Apps
• Предварительно необходимо установить iTunes с официального сайта Apple, либо пакет драйверов AppleMobileDeviceSupport (идут в комплекте с iTunes)  
• Для установки необходимо подключить устройство к ПК через USB и разрешить подключение  
• Скрипт установит все приложения, находящиеся в папке Apps
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="979" height="512" alt="Команда 6" src="https://github.com/user-attachments/assets/705828ec-b76b-48b7-8862-4b3703f411c8" />
</details>

#### 7. Очистка папки Apps
• Скрипт очистит папку Apps со всеми загруженными приложениями

#### 8. Выход из аккаунта Apple ID
• Скрипт выполнит выход из Apple ID

#### 9. Страница проекта на GitHub
• Скрипт откроет страницу проекта на GitHub

## Как найти ID приложения:
Для поиска ID приложения, необходимо знать его ссылку в AppStore (к примеру, ищем в поисковике приложение, находим ссылку в AppStore и из ссылки необходимо взять числовой идентификатор после `id`).  
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

Также можно найти приложения через сайт [appmagic.rocks](https://appmagic.rocks/top-charts/apps) (вверху справа вводим название приложения в поле Search for app or publisher...), далее переходим на страницу приложения и в ссылке будет номер ID.  

Список ID актуальных приложений также можно вывести с помощью команд 4 и 5.  

## Поддержка Windows 7 (временно неактуально, в процессе):
**1\. Обновить системные сертификаты через UpdRootsCert:**  
[Ссылка для загрузки UpdRootsCert](https://disk.yandex.ru/d/SdHMgwJ55MTQRg)
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="521" height="407" alt="UpdRootsCert" src="https://github.com/user-attachments/assets/437390c2-f820-4caa-b679-30377b388c72" />
</details>

**2\. Установить .NET Framework 4.8:**  
[Ссылка для загрузки .NET Framework 4.8](https://go.microsoft.com/fwlink/?linkid=2088631)

**3\. Установить обновление KB3191566 (для добавления поддержки PowerShell 5.1):**  
[Ссылка для загрузки KB3191566](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
<details>
 <summary>Скриншот (нажмите для просмотра)</summary>
<img width="973" height="616" alt="KB3191566" src="https://github.com/user-attachments/assets/940968fc-359f-4ed6-a6d4-2ca834fc989b" />
</details>

**4\. Изменение шрифта в консоли (если отображаются ??? вместо слов):**  
• Нажмите правой кнопкой мыши на заголовок окна консоли  
• Свойства  
• Вкладка Шрифт  
• Выберите Lucida Console или Consolas (эти шрифты поддерживает кириллицу в отличие от шрифта по умолчанию)  
• Нажмите ОК  

## Обновление библиотек libimobiledevice для установки приложений:
**1\. Скачать MSYS2_x86_64 по ссылке:**  
[Ссылка для загрузки MSYS2](https://github.com/msys2/msys2-installer/releases)  
**2\. Запустить MSYS2 MINGW64 и ввести:**  
```
pacman -S \
mingw-w64-x86_64-libimobiledevice \
mingw-w64-x86_64-libplist \
mingw-w64-x86_64-libusbmuxd \
mingw-w64-x86_64-ideviceinstaller
```
**3\. После загрузки в папке C:\msys64\mingw64\bin будут находиться обновленные библиотеки libimobiledevice.**

## Поддержка проекта:
IPA_Downloader полностью бесплатен, однако, если вы хотите безвозмездно поддержать проект, то можно это сделать по следующим реквизитам:  
[Поддержать через CloudTips](https://pay.cloudtips.ru/p/93c0b094)  

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
