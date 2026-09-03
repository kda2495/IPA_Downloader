[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/latest/total?label=Downloads%20(latest)&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)  
[![CloudTips](https://img.shields.io/badge/Tip_Jar_on-CloudTips-blue?style=flat)](https://pay.cloudtips.ru/p/93c0b094)

# IPA_Downloader
[![Russian README](https://img.shields.io/badge/README-Russian-blue.svg)](README.md)  
A script for purchasing/downloading any available App Store apps, as well as restoring removed ones - provided they were previously purchased via your Apple Account (powered by [ipatool-cpp](https://github.com/Sorvigolova/ipatool) and [ipatool-go](https://github.com/majd/ipatool)).

## Script Features:
#### IPA_Installer:
* Check minimum iOS version for apps in the IPA_Downloader/Apps folder;
* Install apps from the IPA_Downloader/Apps folder.
#### IPA_Downloader:
* Search for app and purchase (without downloading);
* Search for app and download latest version;
* Search for app and download (with version selection);
* Enter app IDs and purchase (without downloading);
* Enter app IDs and download latest version;
* Enter app IDs and download (with version selection);
* Show list of apps and purchase (without downloading);
* Show list of apps and download latest version;
* Show list of apps and download (with version selection);
* Check minimum iOS version for apps in the IPA_Downloader/Apps folder;
* Install apps from the IPA_Downloader/Apps folder.

#### The script CANNOT:
* Download apps that have **NOT** been previously purchased from the App Store;
* Copy apps directly from the device.

#### Note:
* To purchase or download apps, they must be previously acquired in the App Store;
* Apps are downloaded directly from the App Store;
* It is recommended to disable security keys and switch to standard two-factor authentication;
* The script supports bulk purchasing/downloading of apps. Simply enter the index numbers of the apps/versions from the tables, separated by commas or hyphens. For example, entering 1, 2, 3-5 will purchase/download the apps with index numbers 1, 2, 3, 4, and 5.

## General requirements for use:
* Windows 7, 8.1, 10, 11 (x64);
* macOS starting from 10.15 Catalina (both Apple Silicon and Intel are supported);
* Linux (x64 and ARM64: Arch Linux, Ubuntu, Debian, Fedora, etc.);
* Stable internet connection;
* An Apple Account with previously downloaded apps.

## To run on Windows:
### Windows requirements:
* Installed AppleMobileDeviceSupport64 driver for supporting app installation via script (included in iTunes):  
[Link to download iTunes from the Apple website](https://www.apple.com/itunes/download/win64)
* Instead of a full iTunes installation, you can extract the iTunes installer with any archiver (7-Zip, WinRAR) and selectively install AppleMobileDeviceSupport64.msi.

### Requirements for Windows 7 and 8.1:
#### All steps must be performed strictly in the following order:
Download the complete set of programs/updates for Windows 7/8.1 via the link:  
[Link for the complete set of programs/updates](https://disk.yandex.ru/d/Fft0whzAz-C7Jg)

#### 1. Update system certificates via UpdRootsCert:
* Follow the link to download UpdRootsCert:  
[Link to download UpdRootsCert](https://disk.yandex.ru/d/SdHMgwJ55MTQRg)  
* Download the UpdRootsCert.exe file;  
* Run the UpdRootsCert.exe file;  
* Check the boxes: System Root Certificates, Add a monthly task to the Task Scheduler;  
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

#### 4. Install the KB2999226 update:
* Run the files: Windows7-KB2999226-x64 (for Windows 7) or Windows8.1-KB2999226-x64 (for Windows 8.1);
* Install the KB2999226 update following the installation wizard instructions.

### How to use (Windows):
#### 1. Extract the IPA_Downloader.zip archive using any archiver;
#### 2. Double-click the Start_IPA_Downloader.bat file;
#### 3. On the first run, initial configuration is required:
* Select language;
* Press Enter;
* When update is available, choose to either visit GitHub to download new script version or continue with current version;
* Press Enter.
#### 4. By default, the script starts in IPA_Installer mode:
* Enter the required command;
* Press Enter.
* To switch to IPA_Downloader mode, enter command 5. Switch to IPA_Downloader.
#### 5. After switching to IPA_Downloader mode:
* Select ipatool version (ipatool-cpp or ipatool-go);
* Press Enter;
* Enter Apple Account (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to Settings - Apple Account - Sign-In & Security - Get Verification Code (this is the two-factor authentication (2FA) code);
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter the required command;
* Press Enter.

## To run on macOS:
### macOS requirements:
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
[Link to download PowerShell](https://github.com/PowerShell/PowerShell/releases)
* Find the appropriate PowerShell version;
* Click Show all assets;
* Download the file: powershell-@-osx-x64.pkg (for Mac with Intel processors) or powershell-@-osx-arm64.pkg (for Mac with Apple Silicon processors);
* Install powershell-@-osx-x64.pkg (for Mac with Intel processors) or powershell-@-osx-arm64.pkg (for Mac with Apple Silicon processors);
* Type in Terminal: `brew install ideviceinstaller minizip`
* Press Enter.
#### Note:
* On macOS Big Sur/Catalina, you need to install PowerShell 7.3.12:  
[Link to download PowerShell 7.3.12](https://github.com/PowerShell/PowerShell/releases/tag/v7.3.12)
* To update Homebrew and all its components, type in Terminal: `brew update && brew upgrade && brew cleanup` and press Enter.

### How to use (macOS):
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
#### 4. By default, the script starts in IPA_Installer mode:
* Enter the required command;
* Press Enter.
* To switch to IPA_Downloader mode, enter command 5. Switch to IPA_Downloader.
#### 5. After switching to IPA_Downloader mode:
* Select ipatool version (ipatool-cpp or ipatool-go);
* Press Enter;
* Enter Apple Account (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to Settings - Apple Account - Sign-In & Security - Get Verification Code (this is the two-factor authentication (2FA) code);
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter your Mac password;
* Click Always Allow;
* Enter the required command;
* Press Enter.

#### Note:
* You can use AirDrop to install the app: simply transfer the file to your iPhone, and the app will be installed automatically.

## To run on Linux:
### Linux requirements:
#### Install the required packages:
#### Arch Linux / Manjaro:
  * Install PowerShell: `sudo pacman -S powershell-bin` (or via AUR: `yay -S powershell-bin`)
  * Install iOS utilities: `sudo pacman -S ideviceinstaller usbmuxd`
  * Enable usbmuxd service: `sudo systemctl enable --now usbmuxd`
#### Ubuntu / Debian:
  * Install PowerShell: [Microsoft Instructions](https://learn.microsoft.com/powershell/scripting/install/install-ubuntu) or `sudo apt install powershell`
  * Install iOS utilities: `sudo apt install ideviceinstaller usbmuxd`
  * Enable usbmuxd service: `sudo systemctl enable --now usbmuxd`
#### Fedora / RHEL:
  * Install PowerShell: `sudo dnf install powershell`
  * Install iOS utilities: `sudo dnf install ideviceinstaller usbmuxd`
  * Enable usbmuxd service: `sudo systemctl enable --now usbmuxd`

### How to use (Linux):
#### 1. Extract the IPA_Downloader archive using any archiver;
#### 2. Make the launcher script executable (if needed):
* Type in Terminal: `chmod +x Start_IPA_Downloader.sh`
* Press Enter.
#### 3. Run the script:
* Type in Terminal: `./Start_IPA_Downloader.sh` (or double-click Start_IPA_Downloader.sh in your file manager);
* Press Enter.
#### 4. On the first run, initial configuration is required:
* Select language;
* Press Enter;
* When update is available, choose to either visit GitHub to download new script version or continue with current version;
* Press Enter.
#### 5. By default, the script starts in IPA_Installer mode:
* Enter the required command;
* Press Enter.
* To switch to IPA_Downloader mode, enter command 5. Switch to IPA_Downloader.
#### 6. After switching to IPA_Downloader mode:
* Select ipatool version (ipatool-cpp or ipatool-go);
* Press Enter;
* Enter Apple Account (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to Settings - Apple Account - Sign-In & Security - Get Verification Code (this is the two-factor authentication (2FA) code);
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter the required command;
* Press Enter.

## IPA_Installer commands description:
#### 1. Check minimum iOS version for apps in the IPA_Downloader/Apps folder:
* Apps must be located in the IPA_Downloader/Apps path;
* The script will check the minimum iOS version required for the app to work.
#### 2. Install apps from the IPA_Downloader/Apps folder:
* Connect the device using a cable;
* Apps must be located in the IPA_Downloader/Apps path;
* Enter the index numbers of the apps to install on the device;
* Press Enter;
* The script will install the selected apps on the device.
#### 3. Tip Jar:
* The script will navigate to the CloudTips page.
#### 4. Change Language:
* The script will change its interface language.
#### 5. Switch to IPA_Downloader:
* The script will switch the mode to IPA_Downloader.

## IPA_Downloader commands description:
#### 1. Search for app and purchase (without downloading):
* Enter the app name to search;
* Press Enter;
* A list of found apps will be displayed;
* Enter the index numbers of the apps to purchase;
* Press Enter;
* The script will purchase the selected apps.
#### 2. Search for app and download latest version:
* Enter the app name to search;
* Press Enter;
* A list of found apps will be displayed;
* Enter the index numbers of the apps to download;
* Press Enter;
* The script will download the selected apps.
#### 3. Search for app and download (with version selection):
* Enter the app name to search;
* Press Enter;
* A list of found apps will be displayed;
* Enter the index numbers of the apps to display app version IDs;
* Press Enter;
* A list of app version IDs will be displayed;
* Enter the index numbers of the app version IDs to download;
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
* Enter the index numbers of the apps to download;
* Press Enter;
* A list of app version IDs will be displayed;
* Enter the index numbers of the app version IDs to download;
* Press Enter;
* The script will download the selected app versions.
#### 7. Show list of apps and purchase (without downloading):
* Enter the list of apps to display (full apps list (GitHub), list of purchased apps, list of non-purchased apps);
* Press Enter;
* The selected list will be displayed;
* Enter the index numbers of the apps to purchase;
* Press Enter;
* The script will purchase the selected apps.
#### 8. Show list of apps and download latest version:
* Enter the list of apps to display (full apps list (GitHub), list of purchased apps, list of non-purchased apps);
* Press Enter;
* The selected list will be displayed;
* Enter the index numbers of the apps to download;
* Press Enter;
* The script will download the selected apps.
#### 9. Show list of apps and download (with version selection):
* Enter the list of apps to display (full apps list (GitHub), list of purchased apps, list of non-purchased apps);
* Press Enter;
* Enter the index numbers of the apps to download;
* Press Enter;
* A list of app version IDs will be displayed;
* Enter the index numbers of the app version IDs to download;
* Press Enter;
* The script will download the selected app versions.
#### 10. Check minimum iOS version for apps in the IPA_Downloader/Apps folder:
* Apps must be located in the IPA_Downloader/Apps path;
* The script will check the minimum iOS version required for the app to work.
#### 11. Install apps from the IPA_Downloader/Apps folder:
* Connect the device using a cable;
* Apps must be located in the IPA_Downloader/Apps path;
* Enter the index numbers of the apps to install on the device;
* Press Enter;
* The script will install the selected apps on the device.
#### 12. Clear data:
* Enter the data list to clear (downloaded apps list, purchased apps list, apps in the Apps folder);
* Press Enter;
* When choosing to clear either the downloaded apps list or the purchased apps list, select the specific account you want to clear;
* Press Enter;
* The script will clear the selected data type.
#### 13. Log out of Apple Account and reset settings:
* The script will log out of the Apple Account and reset all settings.
#### 14. Tip Jar:
* The script will navigate to the CloudTips page.
#### 15. Change Language:
* The script will change its interface language.

## Troubleshooting errors:
* Download error: HTTP request failed: Timeout was reached - Failed to connect to Apple servers, check your internet connection.
* Error: license is required - The app was not previously purchased on this Apple Account.
* Purchase error: app not found - App purchase failed because the app has been removed from the App Store.
* Purchase error: item is temporarily unavailable - The app was not previously purchased on this Apple Account, the purchase failed because the app has been removed from the App Store.
* No device found - Device not found. Make sure the AppleMobileDeviceSupport64 driver is installed (relevant for Windows).
* WARNING: could not locate Payload/App.app/SC_Info/App.sinf in archive! - App signature not found in the installed ipa file.
* Error: anisette exited with code 1 - check that anisette binary is working. iTunes Not Found (0) - iTunes from the Apple website is not installed.
* Error: anisette exited with code 1 - check that anisette binary is working. iCloud Not Found (1) - iCloud from the Apple website is not installed.
* Login error: GSA SRP exception: GSA complete error -27952: Update iCloud for Windows to the latest version to sign in - Advanced Data Protection needs to be disabled via Settings-Account-iCloud-Advanced Data Protection.
* If the app immediately closes when launched after installation, log in to the App Store using the account from which it was downloaded, and install any free/paid app. After that, launch the problematic app again.

## If you encounter an issue:
#### Provide the following information:
* The operating system and ipatool version you are using;
* A screenshot of the error.

## Tracking new app releases:
[AppBank Website](https://pwa.appbank.pw/)

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
