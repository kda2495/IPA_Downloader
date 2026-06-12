[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/latest/total?label=Downloads%20(latest)&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)

# IPA_Downloader
[![Russian README](https://img.shields.io/badge/README-Russian-blue.svg)](README.md)  
A PowerShell script to download previously purchased apps from the App Store and install them on Apple devices (powered by [ipatool-cpp](https://github.com/Sorvigolova/ipatool)).

## Requirements:
• Windows 7–11 (x64)  
• AppleMobileDeviceSupport driver installed (included with iTunes):  
[iTunes Download Link](https://www.apple.com/itunes/download/win64)  
Instead of a full iTunes installation, you can perform a selective installation of `AppleMobileDeviceSupport64.msi` by extracting the iTunes installer with any file archiver.  
• Internet connection  
• Apple ID with previously purchased/downloaded apps

## Features:
• Search for an app and purchase
• Search for an app and download the latest version
• Search for an app and download (with version selection)
• Enter App IDs and purchase
• Enter App IDs and download the latest version
• Enter App IDs and download (with version selection)
• Show list of App IDs and purchase
• Show list of App IDs and download the latest version
• Show list of App IDs and download (with version selection)
• Check minimum iOS version for .ipa files in Apps folder
• Install .ipa files from Apps folder

#### Note:  
For commands requiring IDs, you can enter multiple IDs in the format `1, 2, 3`.  
For version selection commands, you can enter multiple versions in the format `1, 2, 3-5`.  
For commands listing IDs, you can enter multiple apps in the format `1, 2, 3-5`.  

## How to use:
1\. Double-click the `Start_IPA_Downloader.bat` file.  
2\. Upon the first launch, you will need to log in to your Apple ID:  
• Enter your Apple ID (email)  
• Enter your password  
• Enter your two-factor authentication (2FA) code  
3\. Follow the on-screen prompts to enter the desired command.  

## Additional Information:
### Windows 7 Support:
1\. Update system certificates via UpdRootsCert:  
[UpdRootsCert Download Link](https://disk.yandex.ru/d/SdHMgwJ55MTQRg)
<details>
 <summary>Screenshot (click to view)</summary>
<img width="521" height="407" alt="UpdRootsCert" src="https://github.com/user-attachments/assets/437390c2-f820-4caa-b679-30377b388c72" />
</details>

2\. Install .NET Framework 4.8:  
[.NET Framework 4.8 Download Link](https://go.microsoft.com/fwlink/?linkid=2088631)

3\. Install update KB3191566 (to add PowerShell 5.1 support):  
[KB3191566 Download Link](https://www.microsoft.com/en-us/download/details.aspx?id=54616)
<details>
 <summary>Screenshot (click to view)</summary>
<img width="973" height="616" alt="KB3191566" src="https://github.com/user-attachments/assets/940968fc-359f-4ed6-a6d4-2ca834fc989b" />
</details>

### Keeping track of new apps:
[AppBank Website](https://pwa.appbank.pw/)  
[AppBank Telegram Channel](https://t.me/appbankRu)  

### Search for an App ID:
Find the app in the App Store and copy the numeric ID (the value after `id` in the URL).  
<details>
 <summary>Screenshot (click to view)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

## Project Support:
IPA_Downloader is completely free. However, if you would like to support the project, you can do so here:  
[Support via CloudTips](https://pay.cloudtips.ru/p/93c0b094)  

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
