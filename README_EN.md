[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/latest/total?label=Downloads%20(latest)&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)

# IPA_Downloader
[![Russian README](https://img.shields.io/badge/README-Russian-blue.svg)](README.md)  
A script for purchasing/downloading any available App Store apps, as well as restoring removed ones - provided they were previously purchased via your Apple ID account (powered by [ipatool-cpp](https://github.com/Sorvigolova/ipatool)).

## IPA_Downloader Features:
* Search for app and purchase (without downloading);
* Search for app and download latest version;
* Search for app and download (with version selection);
* Enter app IDs and purchase (without downloading);
* Enter app IDs and download latest version;
* Enter app IDs and download (with version selection);
* Show list of apps and purchase (without downloading);
* Show list of apps and download latest version;
* Show list of apps and download (with version selection);
* Check minimum iOS version for apps in Apps folder;
* Install apps from Apps folder.

#### The script CANNOT:
* Download apps that have **NOT** been previously purchased from the App Store;
* Copy apps directly from the device.

#### Note:
* To purchase or download apps, they must be previously acquired in the App Store;
* Apps are downloaded directly from the App Store.

## IPA_Installer Features:
* Check minimum iOS version for apps in Apps folder;
* Install apps from Apps folder.

## General requirements for use:
* Windows 7, 8.1, 10, 11 (x64);
* macOS starting from 10.15 Catalina (both Apple Silicon and Intel are supported);
* Stable internet connection;
* An Apple ID account with previously downloaded apps.

## To run on Windows:
* iTunes from the Apple website (to support app installation via script):  
[Link to download iTunes from the Apple website](https://www.apple.com/itunes/download/win64)
* Instead of a full iTunes installation, you can extract the installer with any archiver and selectively install AppleMobileDeviceSupport64.msi.
* iCloud from the Apple website (for ipatool v3 only):  
[Link to download iCloud from the Apple website](https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe)

## To run on Windows 7 and 8.1:
#### All steps must be performed strictly in the following order:
#### 1. Update system certificates via UpdRootsCert:
* Follow the link to download UpdRootsCert:  
[Link to download UpdRootsCert](https://disk.yandex.ru/d/SdHMgwJ55MTQRg)  
* Download the UpdRootsCert.exe file;  
* Run the UpdRootsCert.exe file;  
* Check the boxes: System Root Certificates, Russian Ministry of Digital Development Certificates, Add a monthly task to the Task Scheduler;  
* Click the Install button.

#### 2. Install .NET Framework 4.8:
* Follow the link to download .NET Framework 4.8:  
[Link to download .NET Framework 4.8](https://go.microsoft.com/fwlink/?linkid=2088631)  
* Download the NDP48-x86-x64-AllOS-ENU.exe file;  
* Run the NDP48-x86-x64-AllOS-ENU.exe file;  
* Install .NET Framework 4.8 following the installation wizard instructions.

#### 3. Install the KB3191566 update (to add PowerShell 5.1 support):
* Follow the link to download KB3191566:  
[Link to download KB3191566](https://www.microsoft.com/en-us/download/details.aspx?id=54616)  
* Click the Download button;  
* Check the boxes: Win7AndW2K8R2-KB3191566-x64.zip (for Windows 7) or Win8.1AndW2K12R2-KB3191564-x64.msu (for Windows 8.1);  
* Click the Download button;  
* Download the files: Win7AndW2K8R2-KB3191566-x64.zip (for Windows 7) or Win8.1AndW2K12R2-KB3191564-x64.msu (for Windows 8.1);  
* Extract the Win7AndW2K8R2-KB3191566-x64.zip archive (for Windows 7);  
* Run the files: Win7AndW2K8R2-KB3191566-x64.msu (for Windows 7) or Win8.1AndW2K12R2-KB3191564-x64.msu (for Windows 8.1);  
* Install the KB3191566 update following the installation wizard instructions.

A complete set of the above programs/updates for Windows 7/8.1 is available at the link:  
[Link for the complete set of programs/updates](https://disk.yandex.ru/d/Fft0whzAz-C7Jg)  

## How to use (Windows):
#### 1. Extract the IPA_Downloader.zip archive using any archiver;
#### 2. Double-click the Start_IPA_Downloader.bat file;
#### 3. On the first run, initial configuration is required:
* Select language;
* Press Enter;
* When update is available, choose to either visit GitHub to download new script version or continue with current version;
* Press Enter.
#### 4. Select one of the available modes:
* IPA_Downloader (full version, works after logging in with Apple ID);
* IPA_Installer (limited version with minimum iOS version check and app installation, works without logging in with Apple ID);
* Press Enter.
#### 5. If IPA_Downloader mode is selected, then:
* Select ipatool version (v2 by default; if v2 doesn't work, select v3);
* Press Enter;
* Enter Apple ID (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter the required command;
* Press Enter.
#### 5.1. If IPA_Installer mode is selected, then:
* Enter the required command;
* Press Enter.

## To run on macOS:
#### All steps must be performed strictly in the following order:
#### 1. Install the Homebrew package manager:
* Open Terminal (Command + Space, then type Terminal in the Spotlight search field);
* Type in Terminal: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
* Press Enter;
* During the Homebrew installation, you may be prompted to enter your password;
* After Homebrew is installed, the text ==> Next steps will appear at the bottom of the Terminal.
#### 2. When installing on a Mac with Intel processors:
* Type in Terminal: `echo >> ~/.zprofile`
* Press Enter;
* Type in Terminal: `echo 'eval "$(/usr/local/bin/brew shellenv zsh)"' >> ~/.zprofile`
* Press Enter;
* Type in Terminal: `eval "$(/usr/local/bin/brew shellenv zsh)"`
* Press Enter.
#### 2.1. When installing on a Mac with Apple Silicon processors:
* Type in Terminal: `echo >> ~/.zprofile`
* Press Enter;
* Type in Terminal: `echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile`
* Press Enter;
* Type in Terminal: `eval "$(/opt/homebrew/bin/brew shellenv zsh)"`
* Press Enter.
#### 3. Install ideviceinstaller, minizip and powershell packages:
* Type in Terminal: `brew install ideviceinstaller minizip powershell`
* Press Enter.
#### 3.1 Alternative PowerShell installation:
* Repeat steps 1–2 from the previous section;
* Go to the PowerShell download page:  
  [PowerShell Download Link](https://github.com/PowerShell/PowerShell/releases)
* Find the appropriate PowerShell version;
* Click Show all assets;
* Download the file: powershell-@-osx-x64.pkg (for Mac with Intel CPU) or powershell-@-osx-arm64.pkg (for Mac with Apple Silicon CPU);
* Install powershell-@-osx-x64.pkg (for Mac with Intel CPU) or powershell-@-osx-arm64.pkg (for Mac with Apple Silicon CPU);
* Open Terminal and run the following command: `brew install ideviceinstaller minizip`
* Press Enter.

## How to use (macOS):
#### 1. Extract the IPA_Downloader.zip archive using any archiver;
* Type in Terminal: `chmod +x ` (including the trailing space after x) and drag and drop the Start_IPA_Downloader.command file into Terminal;
* Press Enter.
#### 2. Double-click the Start_IPA_Downloader.command file;
* The first time, macOS will block Start_IPA_Downloader.command from running;
* Click "Done" in the prompt that appears;
* Click the Apple menu () in the top-left corner of the screen and select "System Settings...";
* In the left sidebar, scroll down and select "Privacy & Security";
* Scroll down the right side of the screen to the "Security" section;
* Next to "Start_IPA_Downloader.command was blocked from use because it is not from an identified developer", click "Open Anyway";
* In the pop-up window, click "Open Anyway";
* Enter your Mac password or use Touch ID;
* If necessary, double-click the Start_IPA_Downloader.command file again.
#### 3. On the first run, initial configuration is required:
* Select language;
* Press Enter;
* When update is available, choose to either visit GitHub to download new script version or continue with current version;
* Press Enter.
#### 4. Select one of the available modes:
* IPA_Downloader (full version, works after logging in with Apple ID);
* IPA_Installer (limited version with minimum iOS version check and app installation, works without logging in with Apple ID);
* Press Enter.
#### 5. If IPA_Downloader mode is selected, then:
* Select ipatool version (v2 by default; if v2 doesn't work, select v3);
* Press Enter;
* Enter Apple ID (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter the required command;
* Press Enter.
#### 5.1. If IPA_Installer mode is selected, then:
* Enter the required command;
* Press Enter.

#### Note:
* macOS Catalina supports PowerShell version 7.3.12.
* To update Homebrew and all its components, open Terminal, run the following command: `brew update && brew upgrade && brew cleanup` and press Enter.
* When using ipatool v3 on macOS, to obtain the two-factor authentication (2FA) code, you need to put your device in Airplane Mode and navigate to Settings > Your account > Sign-In & Security > Get Verification Code.
* There is a bug in ipatool v3 for macOS: an unknown MacBook Pro is added to your account's device list (due to how anisette works). If necessary, you can remove it from the device list, but you will have to obtain a two-factor authentication (2FA) code again.
* You can use AirDrop to install the app: simply transfer file to your iPhone, and the app will be installed automatically.

## IPA_Downloader commands description:
#### 1. Search for app and purchase (without downloading):
* Enter the app name to search;
* Press Enter;
* A list of found apps will be displayed;
* Enter the index numbers of the apps to purchase (in the format 1, 2, 3-5);
* Press Enter;
* The script will purchase the selected apps.
#### 2. Search for app and download latest version:
* Enter the app name to search;
* Press Enter;
* A list of found apps will be displayed;
* Enter the index numbers of the apps to download (in the format 1, 2, 3-5);
* Press Enter;
* The script will download the selected apps.
#### 3. Search for app and download (with version selection):
* Enter the app name to search;
* Press Enter;
* A list of found apps will be displayed;
* Enter the index numbers of the apps to display versions (in the format 1, 2, 3-5);
* Press Enter;
* Enter the number of app versions to display;
* Press Enter;
* A list of app versions will be displayed;
* Enter the index numbers of the app versions to download (in the format 1, 2, 3-5);
* Press Enter;
* The script will download the selected app versions.
#### 4. Enter app IDs and purchase (without downloading):
* Enter the app IDs to purchase (in the format 1, 2, 3);
* Press Enter;
* The script will purchase the selected apps.
#### 5. Enter app IDs and download latest version:
* Enter the app IDs to download (in the format 1, 2, 3);
* Press Enter;
* The script will download the selected apps.
#### 6. Enter app IDs and download (with version selection):
* Enter the app IDs to download (in the format 1, 2, 3);
* Press Enter;
* Enter the number of app versions to display;
* Press Enter;
* A list of app versions will be displayed;
* Enter the index numbers of the app versions to download (in the format 1, 2, 3-5);
* Press Enter;
* The script will download the selected app versions.
#### 7. Show list of apps and purchase (without downloading):
* Enter the list of apps to display (ready-made apps list, purchased apps list, not purchased apps list);
* Press Enter;
* The selected list will be displayed;
* Enter the index numbers of the apps to purchase (in the format 1, 2, 3-5);
* Press Enter;
* The script will purchase the selected apps.
#### 8. Show list of apps and download latest version:
* Enter the list of apps to display (ready-made apps list, purchased apps list, not purchased apps list);
* Press Enter;
* The selected list will be displayed;
* Enter the index numbers of the apps to download (in the format 1, 2, 3-5);
* Press Enter;
* The script will download the selected apps.
#### 9. Show list of apps and download (with version selection):
* Enter the list of apps to display (ready-made apps list, purchased apps list, not purchased apps list);
* Press Enter;
* Enter the index numbers of the apps to download (in the format 1, 2, 3-5);
* Press Enter;
* Enter the number of app versions to display;
* Press Enter;
* A list of app versions will be displayed;
* Enter the index numbers of the app versions to download (in the format 1, 2, 3-5);
* Press Enter;
* The script will download the selected app versions.
#### 10. Check minimum iOS version for apps in Apps folder:
* Apps must be located in the IPA_Downloader/Apps path;
* The script will check the minimum iOS version required for the app to work.
#### 11. Install apps from Apps folder:
* Connect the device using a cable;
* Apps must be located in the IPA_Downloader/Apps path;
* Enter the index numbers of the apps to install on the device (in the format 1, 2, 3-5);
* Press Enter;
* The script will install the selected apps on the device.
#### 12. Clear data:
* Enter the data list to clear (downloaded apps list, purchased apps list, apps in Apps folder);
* Press Enter;
* When choosing to clear either the downloaded apps list or the purchased apps list, select the specific account you want to clear;
* Press Enter;
* The script will clear the selected data type.
#### 13. Log out of Apple ID + reset settings:
* The script will log out of the Apple ID and reset all settings.
#### 14. GitHub project page:
* The script will navigate to the project page on GitHub.
#### 15. Change Language (Сменить язык):
* The script will change its interface language.

## IPA_Installer commands description:
#### 1. Check minimum iOS version for apps in Apps folder:
* Apps must be located in the IPA_Downloader/Apps path;
* The script will check the minimum iOS version required for the app to work.
#### 2. Install apps from Apps folder:
* Connect the device using a cable;
* Apps must be located in the IPA_Downloader/Apps path;
* Enter the index numbers of the apps to install on the device (in the format 1, 2, 3-5);
* Press Enter;
* The script will install the selected apps on the device.
#### 3. GitHub project page:
* The script will navigate to the project page on GitHub.
#### 4. Change Language:
* The script will change its interface language.
#### 5. Switch to IPA_Downloader:
* The script will switch the mode to IPA_Downloader.

## Troubleshooting errors:
* Download error: HTTP request failed: Timeout was reached - Failed to connect to Apple servers, check your internet connection;
* Error: license is required - The app was not previously purchased on this Apple ID;
* Purchase error: app not found - App purchase failed because the app has been removed from the App Store;
* Purchase error: item is temporarily unavailable - The app was not previously purchased on this Apple ID, the purchase failed because the app has been removed from the App Store;
* No device found - Device not found. Make sure the AppleMobileDeviceSupport64 driver is installed (relevant for Windows);
* WARNING: could not locate Payload/App.app/SC_Info/App.sinf in archive! - App signature not found in the installed ipa file;
* Error: anisette exited with code 1 - check that anisette binary is working. iTunes Not Found (0) - iTunes from the Apple website is not installed;
* Error: anisette exited with code 1 - check that anisette binary is working. iCloud Not Found (1) - iCloud from the Apple website is not installed;
* Login error: GSA SRP exception: GSA complete error -27952: Update iCloud for Windows to the latest version to sign in - Advanced Data Protection needs to be disabled via Settings-Account Name-iCloud-Advanced Data Protection.

## If you encounter an issue:
#### Provide the following information:
* The system and ipatool version you are using;
* The full path to the IPA_Downloader folder;
* A screenshot of the error;
* The sequence of actions to reproduce the error.

## Tracking new app releases:
[AppBank Website](https://pwa.appbank.pw/)  
[AppBank Telegram Channel](https://t.me/appbankRu)  

## Finding an App ID:
#### Option 1:
Find the app link in the App Store and copy the numeric identifier (the value after "id" in the URL).
#### Option 2:
If the app is installed on your device, press and hold the app icon:
* The Share App option will appear;
* Copy the link and paste it into a browser;
* Copy the numeric identifier (the value after id in the URL).
<details>
 <summary>Screenshot (click to view)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

## Project support:
IPA_Downloader is completely free, however, if you want to support the project voluntarily, you can do so via the link below or using the QR code:  
[Support via CloudTips](https://pay.cloudtips.ru/p/93c0b094)  

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
