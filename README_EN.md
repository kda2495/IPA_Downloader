[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/latest/total?label=Downloads%20(latest)&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)  
[![CloudTips](https://img.shields.io/badge/Tip_Jar_on-CloudTips-blue?style=flat)](https://pay.cloudtips.ru/p/93c0b094)

# IPA_Downloader
[![Russian README](https://img.shields.io/badge/README-Russian-blue.svg)](README.md)  
A script for purchasing/downloading any available App Store apps, as well as restoring removed ones - provided they were previously purchased via your Apple account (powered by [ipatool-cpp](https://github.com/Sorvigolova/ipatool)).

## Information about the script:
### Important:
ipatool is an unofficial tool; therefore, using the script is only at your own risk.
### Script Features:
#### IPA_Downloader (downloading and installing apps):
* Search for apps by name or ID and purchase (without downloading)
* Search for apps by name or ID and download latest version
* Search for apps by name or ID and download (with version selection)
* Select an app list and purchase (without downloading)
* Select an app list and download latest version
* Select an app list and download (with version selection)
* Check the minimum iOS version for apps in the Apps folder
* Install apps from Apps folder

#### IPA_Installer (installing apps):
* Check the minimum iOS version for apps in the Apps folder
* Install apps from Apps folder.

#### The script CANNOT:
* Download apps that have **NOT** been previously purchased from the App Store;
* Copy apps directly from the device.

#### Note:
* To purchase or download apps, they must be previously acquired in the App Store;
* Apps are downloaded directly from the App Store;
* It is recommended to disable security keys and switch to standard two-factor authentication;
* The script supports bulk purchasing/downloading/installing apps. Simply enter the index numbers (#) of the apps/versions from the tables, separated by commas or hyphens. For example, entering 1, 2, 3-5 will purchase/download/installing the apps with index numbers (#) 1, 2, 3, 4, and 5;
* It is possible to create a custom list of applications; you just need to add data in the format `App name: its ID`, for example: `Google: 284815942` to the file Files/AppsListCustom.txt.

### General requirements for use:
* Windows 7 - 11 (x64);
* macOS starting from 10.15 Catalina (both Apple Silicon and Intel are supported);
* Linux (x64 and ARM64: Arch Linux, Ubuntu, Debian, Fedora, etc.);
* Stable internet connection;
* An Apple account with previously downloaded apps.

## Using on Windows:
### Windows requirements:
* To install downloaded apps via the script, the `AppleMobileDeviceSupport64` driver is required (included in iTunes):  
[Link to download iTunes from the Apple website](https://www.apple.com/itunes/download/win64)
* Instead of a full iTunes installation, you can selectively install `AppleMobileDeviceSupport64.msi` by extracting the iTunes installer with any archiver (7-Zip, WinRAR).
* The script works without this driver, but it is required to install downloaded apps on the device.

### Requirements for Windows 7 and 8.1:
#### All steps must be performed strictly in the following order:
Download the complete set of programs/updates for Windows 7/8.1 via the link:  
[Link for the complete set of programs/updates](https://disk.yandex.ru/d/Fft0whzAz-C7Jg)
#### 1. Update system certificates via UpdRootsCert:
* Run the UpdRootsCert.exe file;
* Check the boxes: System Root Certificates, Add a monthly task to the Task Scheduler;
* Click the Install button.
#### 2. Install .NET Framework 4.8:
* Run the NDP48-x86-x64-AllOS-ENU.exe file;
* Install .NET Framework 4.8 following the installation wizard instructions.
#### 3. Install the KB3191566 update (to add PowerShell 5.1 support):
* Run the files: Win7AndW2K8R2-KB3191566-x64.msu (for Windows 7) or Win8.1AndW2K12R2-KB3191564-x64.msu (for Windows 8.1);
* Install the KB3191566 update following the installation wizard instructions.
#### 4. Install the KB2999226 update:
* Run the files: Windows7-KB2999226-x64 (for Windows 7) or Windows8.1-KB2999226-x64 (for Windows 8.1);
* Install the KB2999226 update following the installation wizard instructions.

### How to use (Windows):
#### 1. Extract the IPA_Downloader.zip archive using any archiver (7-Zip, WinRAR);
#### 2. Double-click the Start_IPA_Downloader_Windows.bat file;
#### 3. On the first run, initial configuration is required:
* Select language;
* Press Enter;
* When update is available, choose to either visit the repository to download new script version or continue with current version;
* Press Enter.
#### 4. By default, the script starts in IPA_Downloader mode (downloading and installing apps):
* To log in enter the command: 1. Log in to Apple account;
* Press Enter;
* Enter Apple account (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to `Settings - Apple Account - Sign-In & Security - Get Verification Code` (this is the two-factor authentication (2FA) code);
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter the required command;
* Press Enter.

### macOS requirements:
### All steps must be performed strictly in the following order:
### On a Mac with Apple Silicon processors:
#### 1. Install Xcode Command Line Tools:
* Open Terminal (Command + Space, then type `Terminal` in the Spotlight search field);
* Type in Terminal: `xcode-select --install`
* Press Enter.
#### 2. Install the Homebrew package manager:
* Type in Terminal: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
* Press Enter;
* During the Homebrew installation, you may be prompted to enter your password;
* After Homebrew is installed, the text ==> Next steps will appear at the bottom of the Terminal.
* Type in Terminal:
```
echo >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```
* Press Enter.
#### 3. Install the ideviceinstaller, minizip and powershell packages:
* Type in Terminal: `brew install ideviceinstaller minizip powershell`
* Press Enter.
* When prompted, type `y` in Terminal and press Enter.
### On a Mac with Intel processors:
#### 1. Install Xcode Command Line Tools:
* Open Terminal (Command + Space, then type `Terminal` in the Spotlight search field);
* Press Enter;
* Type in Terminal: `xcode-select --install`
* Press Enter.
#### 2. Install the MacPorts package manager:
* Click the Apple logo () in the top-left corner of the screen, select `About This Mac`, and check the `macOS` field;
* Download the installer for your macOS version:  
[Link to download MacPorts](https://github.com/macports/macports-base/releases)
* Click `Show all assets` and find the file with the `.pkg` extension for your macOS version;
* Install MacPorts using the installer file.
#### 3. Install the ideviceinstaller, minizip and powershell packages:
* Open a `new` Terminal (Command + Space, then type `Terminal` in the Spotlight search field);
* Type in Terminal: `sudo port install ideviceinstaller minizip powershell`
* Press Enter;
* When prompted, type `y` in Terminal and press Enter.
#### Note:
* To uninstall Homebrew and all its components, type in Terminal:  
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"` and press Enter.
* On macOS 10.15 Catalina, you need to install PowerShell version 7.3.12 by downloading the file:
[Link to download PowerShell 7.3.12](https://github.com/PowerShell/PowerShell/releases/download/v7.3.12/powershell-7.3.12-osx-x64.pkg)

### How to use (macOS):
#### 1. Extract the IPA_Downloader.zip archive using any archiver (Keka);
#### 2. Double-click the Start_IPA_Downloader_macOS.command file;
* The first time you run it, macOS will block Start_IPA_Downloader_macOS.command from opening;
* In the dialog that appears, `“Start_IPA_Downloader_macOS.command” was not opened` click `Done`;
* Click the Apple menu () in the top-left corner of the screen and select `System Settings`;
* In the left sidebar, scroll down and select `Privacy & Security`;
* Scroll down the right side of the screen to the `Security" section`;
* Next to `Start_IPA_Downloader_macOS.command was blocked to protect your Mac`, click `Open Anyway`;
* In the pop-up window `Open “Start_IPA_Downloader_macOS.command?`, click `Open Anyway`;
* Enter your Mac password or use Touch ID.
#### 3. On the first run, initial configuration is required:
* Select language;
* Press Enter;
* When update is available, choose to either visit the repository to download new script version or continue with current version;
* Press Enter.
#### 4. By default, the script starts in IPA_Downloader mode (downloading and installing apps):
* To log in enter the command: 1. Log in to Apple account;
* Press Enter;
* Enter Apple account (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to `Settings - Apple Account - Sign-In & Security - Get Verification Code` (this is the two-factor authentication (2FA) code);
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter the required command;
* Press Enter.

#### Note:
* You can use AirDrop to install the app: simply transfer the file to your iPhone, and the app will be installed automatically.

## Using on Linux:
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
* Type in Terminal: `chmod +x Start_IPA_Downloader_Linux.sh`
* Press Enter.
#### 3. Run the script:
* Type in Terminal: `./Start_IPA_Downloader_Linux.sh` (or double-click `Start_IPA_Downloader_Linux.sh` in your file manager);
* Press Enter.
#### 4. On the first run, initial configuration is required:
* Select language;
* Press Enter;
* When update is available, choose to either visit the repository to download new script version or continue with current version;
* Press Enter.
#### 5. By default, the script starts in IPA_Downloader mode (downloading and installing apps):
* To log in enter the command: 1. Log in to Apple account;
* Press Enter;
* Enter Apple account (Enter email:);
* Press Enter;
* Enter password (Enter password:);
* Press Enter;
* Tap Allow on your device and remember the two-factor authentication (2FA) code;
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to `Settings - Apple Account - Sign-In & Security - Get Verification Code` (this is the two-factor authentication (2FA) code);
* Enter the two-factor authentication code (Enter 2FA code:);
* Press Enter;
* Enter the required command;
* Press Enter.

## Script commands description:
### IPA_Downloader (downloading and installing apps):
#### 1. Search for apps by name or ID and purchase (without downloading):
* Enter the app name or app IDs to search;
* Press Enter;
* If an app name is entered, a list of found apps will be displayed;
* Enter the index numbers (#) of the apps to purchase;
* Press Enter;
* The script will purchase the selected apps.

* If app IDs are entered, the script will purchase the specified apps.
#### 2. Search for apps by name or ID and download latest version:
* Enter the app name or app IDs to search;
* Press Enter;
* If an app name is entered, a list of found apps will be displayed;
* Enter the index numbers (#) of the apps to download;
* Press Enter;
* The script will download the selected apps.

* If app IDs are entered, the script will download the specified apps.
#### 3. Search for apps by name or ID and download (with version selection):
* Enter the app name or app IDs to search;
* Press Enter;
* If an app name is entered, a list of found apps will be displayed;
* Enter the index numbers (#) of the apps to display app version IDs;
* Press Enter;
* A list of app version IDs will be displayed (from the first to the latest);
* Enter index numbers (#) of version IDs or version IDs to display app versions;
* Press Enter;
* A list of app versions will be displayed;
* Enter the index numbers (#) of the app versions to download;
* Press Enter;
* The script will download the selected app versions.

* If app IDs are entered:
* A list of app version IDs will be displayed (from the first to the latest);
* Enter index numbers (#) of version IDs or version IDs to display app versions;
* Press Enter;
* A list of app versions will be displayed;
* Enter the index numbers (#) of the app versions to download;
* Press Enter;
* The script will download the selected app versions.
#### 4. Select an app list and purchase (without downloading):
* Select the app list to display:
1. Popular apps list (Files/AppsList.txt)
2. List of popular apps not purchased by the script
3. List of apps installed on the device
4. Custom apps list (Files/AppsListCustom.txt)
* Press Enter;
* The selected list will be displayed;
* Enter the index numbers (#) of the apps to purchase;
* Press Enter;
* The script will purchase the selected apps.
#### 5. Select an app list and download latest version:
* Select the app list to display:
1. Popular apps list (Files/AppsList.txt)
2. List of apps from the Apple account purchase history (Files/AppsListAccount_.txt)
3. List of apps installed on the device
4. Custom apps list (Files/AppsListCustom.txt)
* Press Enter;
* The selected list will be displayed;
* Enter the index numbers (#) of the apps to download;
* Press Enter;
* The script will download the selected apps.
#### 6. Select an app list and download (with version selection):
* Select the app list to display:
1. Popular apps list (Files/AppsList.txt)
2. List of apps from the Apple account purchase history (Files/AppsListAccount_.txt)
3. Custom apps list (Files/AppsListCustom.txt)
* Press Enter;
* The selected list will be displayed;
* Enter the index numbers (#) of the apps to download;
* Press Enter;
* A list of app version IDs will be displayed (from the first to the latest);
* Enter index numbers (#) of version IDs or version IDs to display app versions;
* Press Enter;
* A list of app versions will be displayed;
* Enter the index numbers (#) of the app versions to download;
* Press Enter;
* The script will download the selected app versions.
#### 7. Check the minimum iOS version for apps in the Apps folder:
* Apps must be located in the Apps folder;
* The script will check the minimum iOS version required to install the app.
#### 8. Install apps from Apps folder:
* Apps must be located in the Apps folder;
* Connect the device using a cable;
* Tap `Trust` when the `Trust This Computer?` prompt appears.  
* Enter the index numbers (#) of the the devices for installation;
* Press Enter;
* Enter the index numbers (#) of the apps to install on the devices;
* Press Enter;
* The script will install the selected apps on the devices.
#### 9. Clear data:
* Select the data to clear:
1. List of apps purchased by the script (Files/PurchasedAppsList.json)
2. Apps in Apps folder
* Press Enter;
* When choosing to clear the list of apps purchased by the script, select the Apple account to clear;
* Press Enter;
* The script will clear the selected data type.
#### 10. Apple Account operations:
* Enter the required action:
1. Add account;  
2. Switch account;  
3. Log out of Apple Account;  
* Press Enter.
#### 11. Tip Jar:
* The script will navigate to the CloudTips page.
#### 12. Change Language (Сменить язык):
* The script will change its interface language.
#### air
* Enabling/disabling connection to the device via Wi‑Fi.
#### debug
* Enable/disable debug mode.

### IPA_Installer (installing apps):
#### 1. Check the minimum iOS version for apps in the Apps folder:
* Apps must be located in the Apps folder;
* The script will check the minimum iOS version required to install the app.
#### 2. Install apps from Apps folder:
* Apps must be located in the Apps folder;
* Connect the device using a cable;
* Tap `Trust` when the `Trust This Computer?` prompt appears.  
* Enter the index numbers (#) of the the devices for installation;
* Press Enter;
* Enter the index numbers (#) of the apps to install on the devices;
* Press Enter;
* The script will install the selected apps on the devices.
#### 3. Tip Jar:
* The script will navigate to the CloudTips page.
#### 4. Change Language (Сменить язык):
* The script will change its interface language.
#### 5. Switch to IPA_Downloader:
* The script will switch the mode to IPA_Downloader (downloading and installing apps).
#### air
* Enabling/disabling connection to the device via Wi‑Fi.
#### debug
* Enable/disable debug mode.

## Possible errors and solution:
### Troubleshooting errors:
* `Processing -File ./IPA_Downloader.ps1 failed: Access to the path is denied (macOS)` - Allow Terminal access in `System Settings - Privacy & Security - Full Disk Access`.
* `Login error: failed to initialize SAP signer: curl: Timeout was reached.` - Failed to connect to SAP, check your internet connection.
* `Error: account is disabled` - Apple account is temporarily blocked by Apple (usually due to multiple attempts to enter incorrect password or 2FA code), account needs to be unblocked via the device or on the `icloud.com` website.
* `Download error: HTTP request failed: Couldn't resolve host name` - Failed to connect to Apple servers, check your internet connection.
* `Download error: HTTP request failed: Timeout was reached` - Failed to connect to Apple servers, check your internet connection.
* `Error: license is required` - The app was not previously purchased on this Apple account.
* `Error: This Apple Account is temporarily unable to be used in the iTunes Store because it could not be found. Try again later.` - You need to make any free purchase in the App Store.
* `Purchase error: app not found` - App purchase failed because the app has been removed from the App Store.
* `Purchase error: item is temporarily unavailable` - The app was not previously purchased on this Apple account, the purchase failed because the app has been removed from the App Store.
* `No device found` - Device not found. Make sure the AppleMobileDeviceSupport64 driver is installed (relevant for Windows).
* `WARNING: could not locate Payload/App.app/SC_Info/App.sinf in archive!` - App signature not found in the installed ipa file.
* `ERROR: Install failed. Got error "APIInternalError" with code 0x00000000: Error Domain=IXErrorDomain Code=46` - You need to remove the app from the device, restart the device, and try installing it again.
* `Could not connect to lockdownd: Invalid HostID. Exiting.` - Delete the folders listed below, then uninstall iTunes and AppleMobileDeviceSupport64, and reinstall iTunes or AppleMobileDeviceSupport64, connect the device and tap `Trust` when the `Trust This Computer?` prompt appears.
```
C:\ProgramData\Apple\
C:\ProgramData\Apple\Apple Computer\
C:\Users\%username%\AppData\Local\Apple Computer\
C:\Users\%username%\AppData\Local\Apple Inc\
C:\Users\%username%\AppData\Roaming\Apple Computer\
```
* If you encounter any issues with authorization, try logging in to your Apple account on the `icloud.com` website.
* If the app immediately closes when launched after installation, log in to the App Store using the account from which it was downloaded, and install any free/paid app. After that, launch the problematic app again.

### If you encounter an issue:
#### Please provide the following information:
* The operating system and version of IPA_Downloader being used;
* Enter the debug command in the script’s main menu, reproduce the action that leads to the error, and send the result;
* A screenshot of the error.

## Useful information:
### Finding an App ID:
#### Option 1:
Find the app link in the App Store and copy the value after `id` in the URL.  
<details>
 <summary>Screenshot (click to view)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

#### Option 2:
If the app is installed on your device, press and hold the app icon:  
* The Share App option will appear;
* Copy the link and paste it into a browser;
* Copy the value after `id` in the URL.

#### Option 3:
You can view the full list of purchased apps via the website [reportaproblem.apple.com](https://reportaproblem.apple.com)  
* Next, enter the app name in the search box on the [appmagic.rocks](https://appmagic.rocks/top-charts/apps) website and go to the app’s page;
* On the app page, select Select App with the App Store icon and copy the value in the end of URL.

### Tracking new app releases:
[The topic on the 4PDA](https://4pda.to/forum/index.php?showtopic=1046078)  
[AppBank Website](https://pwa.appbank.pw)

## Tip Jar:
IPA_Downloader is completely free, however, if you want to support the project voluntarily, you can do so via the link below or using the QR code:  
[Support via CloudTips](https://pay.cloudtips.ru/p/93c0b094)  

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
