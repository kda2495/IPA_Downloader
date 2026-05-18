[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)

# IPA_Downloader
[![Russian README](https://img.shields.io/badge/README-Russian-blue.svg)](README.md)  
A script for downloading applications from your Apple ID purchase history and installing them onto Apple devices (powered by [ipatool-cpp](https://github.com/Sorvigolova/ipatool)).

## Requirements:
• Windows 7-11 x64  
• Installed AppleMobileDeviceSupport driver (included with iTunes):  
[iTunes Download Link](https://www.apple.com/itunes/download/win64)  
Instead of installing the full iTunes package, you can perform a custom installation of `AppleMobileDeviceSupport64.msi` by extracting the iTunes installer using any archive manager.  
• Active Internet connection  
• An Apple ID account with previously downloaded/purchased applications  

## How to use:
**1\. Double-click the `Start_IPA_Downloader.bat` file.**  
**2\. On the first launch, you will need to log into your Apple ID:**  
• Enter Apple ID (Enter email)  
• Enter password  
• Enter 2FA code (Two-Factor Authentication)  

**Please note:**  
• All actions in the script are confirmed by pressing the Enter key.  
• All downloaded applications are saved to the `IPA_Downloader/Apps` folder.  
• The downloaded file name contains the application ID and its version.  

## Script Commands Overview:
#### 1. Search for an app and download the latest version
• Enter the name of the application you want to find  
• The script will display the search results  
• To download, enter the App ID when prompted: `Enter the App ID to download`

#### 2. Enter App ID and download the latest version
• To download, directly enter the App ID when prompted: `Enter the App ID to download`

#### 3. Enter App ID and download (with version selection)
• Enter the App ID when prompted: `Enter the App ID to search`  
• The script will ask for the number of versions you want to display  
• The script will show a list of available application versions (from newest to oldest)  
• To download, enter the version index number or the specific Version ID  

**Important Note:**  
If an application is unavailable in your region, it will still show up if an update is available in the AppStore, but trying to update it directly will result in an error.  
To update such apps, you must delete the old version from your device, download the new version via IPA_Downloader, and then reinstall it.

#### 4. Show list of App IDs and download the latest version
• A predefined list of applications will be displayed  
• To download, enter the apps' index numbers when prompted: `Enter the numbers of apps to download`  
(for example: 1, 2, 3-5)  

#### 5. Show list of App IDs and download (with version selection)
• A predefined list of applications will be displayed  
• To download, enter the apps' index numbers when prompted: `Enter the numbers of apps to download`  
(for example: 1, 2, 3-5)  
• The script will ask for the number of versions you want to display  
• The script will show a list of available application versions (from newest to oldest)  
• To download, enter the version index number or the specific Version ID  

**Important Note:**  
If an application is unavailable in your region, it will still show up if an update is available in the AppStore, but trying to update it directly will result in an error.  
To update such apps, you must delete the old version from your device, download the new version via IPA_Downloader, and then reinstall it.

#### 6. Show minimum iOS version for ipa files in Apps folder
• The script will display the minimum iOS version required for installation for all `.ipa` files currently located in the `Apps` folder  

#### 7. Install apps downloaded to the Apps folder
• Make sure you have iTunes installed from the official Apple website, or the `AppleMobileDeviceSupport` driver package (bundled with iTunes)  
• Connect your device to the PC via USB and trust the computer  
• The script will automatically install all applications found in the `Apps` folder

**Important Note:**  
To install the app, the name of the ipa-file must be in Latin characters.

#### 8. Clear Apps folder
• The script will wipe the `Apps` folder, deleting all downloaded applications

#### 9. Log out of Apple ID account
• The script will securely log out of your Apple ID account

#### 10. GitHub project page
• The script will open the official project page on GitHub in your default browser

#### 11. Change Language (Сменить язык)
• Toggles the script interface language

## How to find an App ID:
To find an App ID, you need to know its AppStore URL link (for example, search for the app via a search engine, open its AppStore link, and copy the numeric identifier that comes right after `id`).  
<details>
 <summary>Screenshot (click to expand)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

You can also find application IDs using the [appmagic.rocks](https://appmagic.rocks/top-charts/apps) website (type the app or publisher name in the search field at the top right), then go to the app page and copy the ID number from the URL.  

You can also display a list of actual app IDs using commands 4 and 5.  

## Track New App Releases:
[Telegram Channel AppBank](https://t.me/appbankRu)  
[AppBank Website](https://appbank.pw/)

## Windows 7 Support:
**1\. Update system certificates via UpdRootsCert:**  
[Download Link for UpdRootsCert](https://disk.yandex.ru/d/SdHMgwJ55MTQRg)
<details>
 <summary>Screenshot (click to expand)</summary>
<img width="521" height="407" alt="UpdRootsCert" src="https://github.com/user-attachments/assets/437390c2-f820-4caa-b679-30377b388c72" />
</details>

**2\. Install .NET Framework 4.8:**  
[Download Link for .NET Framework 4.8](https://go.microsoft.com/fwlink/?linkid=2088631)

**3\. Install update KB3191566 (to add PowerShell 5.1 support):**  
[Download Link for KB3191566](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
<details>
 <summary>Screenshot (click to expand)</summary>
<img width="973" height="616" alt="KB3191566" src="https://github.com/user-attachments/assets/940968fc-359f-4ed6-a6d4-2ca834fc989b" />
</details>

## Updating libimobiledevice libraries for App Installation:
**1\. Download msys2-x86_64-latest.exe using the following link:**  
[Download Link for MSYS2](https://github.com/msys2/msys2-installer/releases/tag/nightly-x86_64)  
**2\. Launch MSYS2 MINGW64 and type:**  

```
pacman -S \
mingw-w64-x86_64-libimobiledevice \
mingw-w64-x86_64-libplist \
mingw-w64-x86_64-libusbmuxd \
mingw-w64-x86_64-ideviceinstaller
```
**3\. Once downloaded, the updated libimobiledevice libraries will be located in the `C:\msys64\mingw64\bin` folder.**

## Support the Project:
IPA_Downloader is completely free. However, if you wish to support the project voluntarily, you can do so using the following details:  
[Support via CloudTips](https://pay.cloudtips.ru/p/93c0b094)  

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
