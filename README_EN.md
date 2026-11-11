[![GitHub release](https://img.shields.io/github/v/release/kda2495/IPA_Downloader.svg?label=Release)](https://github.com/kda2495/IPA_Downloader/releases)
[![License](https://img.shields.io/github/license/kda2495/IPA_Downloader.svg?label=License&color=blue)](https://github.com/kda2495/IPA_Downloader/blob/main/LICENSE)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/total?label=Downloads&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)
[![Downloads](https://img.shields.io/github/downloads/kda2495/IPA_Downloader/latest/total?label=Downloads%20(latest)&color=blue)](https://github.com/kda2495/IPA_Downloader/releases)  
[![CloudTips](https://img.shields.io/badge/Tip_Jar_on-CloudTips-blue?style=flat)](https://pay.cloudtips.ru/p/93c0b094)

# IPA_Downloader
[![Russian README](https://img.shields.io/badge/README-Russian-blue.svg)](README.md)  
A script for downloading apps previously purchased in the App Store, including deleted ones (powered by [ipatool-cpp](https://github.com/Sorvigolova/ipatool)).

## Information about the script:
### Important:
ipatool is an unofficial tool; therefore, using the script is only at your own risk.
### General requirements for use:
* Windows 7-11 (x64)
* macOS starting from 10.15 Catalina (both Apple Silicon and Intel are supported)
* Linux (x64 and ARM64: Arch Linux, Ubuntu, Debian, Fedora, etc.)
* PowerShell installed (included with Windows; must be installed separately on macOS and Linux)
* Stable internet connection
* An Apple account with previously downloaded apps
### Script Features:
#### IPA_Downloader (downloading and installing apps):
* Search for apps by name or ID and purchase (without downloading)
* Search for apps by name or ID and download latest version
* Search for apps by name or ID and download (with version selection)
* Select an app list and purchase (without downloading):
1. Popular apps list
2. List of popular apps not purchased by the script
3. Custom apps list
* Select an app list and download latest version:
1. Popular apps list
2. List of apps from the Apple account purchase history
3. List of apps installed on the device
4. List of offloaded apps installed on the device
5. Custom apps list
* Select an app list and download (with version selection):
1. Popular apps list
2. List of apps from the Apple account purchase history
3. List of apps installed on the device
4. List of offloaded apps installed on the device
5. Custom apps list
* Check the minimum iOS version for apps in the Apps folder
* Install apps from Apps folder

#### IPA_Installer (installing apps only):
* Check the minimum iOS version for apps in the Apps folder
* Install apps from Apps folder

#### Note:
* All actions after entering commands are confirmed by pressing the Enter key
* To download apps, they must be previously acquired in the App Store
* Apps are downloaded directly from the App Store
* It is recommended to disable security keys and switch to standard two-factor authentication (2FA)
* The script supports bulk purchasing/downloading/installing apps. Simply enter the index numbers (#) of the apps/versions from the tables, separated by commas or hyphens. For example, entering 1, 2, 3-5 will purchase/download/install the apps with index numbers (#) 1, 2, 3, 4, and 5
* It is possible to create a custom list of applications; you just need to add data in the format `App name: its ID`, for example: `Google: 284815942` to the file Files/AppsListCustom.txt
* The IPA_Installer mode (installing apps only) works without authorization

## Using on Windows:
### Windows requirements:
* To install downloaded apps via the script, the `AppleMobileDeviceSupport64` driver is required (included in iTunes and Apple Devices):
- [Download iTunes from the Apple website](https://www.apple.com/itunes/download/win64)
- [Download iTunes from the Microsoft Store](https://apps.microsoft.com/detail/9pb2mz1zmb1s)
- [Download Apple Devices from the Microsoft Store](https://apps.microsoft.com/detail/9np83lwlpz9k)
* Instead of a full iTunes installation, you can selectively install `AppleMobileDeviceSupport64.msi` by extracting the iTunes installer with any archiver (for example: [7-Zip](https://www.7-zip.org))
* The script works without this driver, but it is required to install downloaded apps on the device

### Requirements for Windows 7 and 8.1:
#### All steps must be performed strictly in the following order:
#### 1. Update system certificates via UpdRootsCert:
* Download UpdRootsCert.exe file via the link:
- [Download UpdRootsCert.exe](https://disk.yandex.ru/d/SdHMgwJ55MTQRg)
* Run the UpdRootsCert.exe file
* Check the boxes: System Root Certificates, Add a monthly task to the Task Scheduler
* Click the Install button
#### 2. Install .NET Framework 4.8:
* Download NDP48-x86-x64-AllOS-ENU.exe file via the link:
- [Download .NET Framework 4.8](https://go.microsoft.com/fwlink/?linkid=2088631)
* Run the NDP48-x86-x64-AllOS-ENU.exe file
* Install .NET Framework 4.8 following the installation wizard instructions
#### 3. Install the KB3191564/KB3191566 update (to add PowerShell 5.1 support):
* Download KB3191564/KB3191566 update via the link:
- [Download KB3191566 for Windows 7](https://download.microsoft.com/download/6/f/5/6f5ff66c-6775-42b0-86c4-47d41f2da187/Win7AndW2K8R2-KB3191566-x64.zip)
- [Download KB3191564 for Windows 8.1](https://download.microsoft.com/download/6/f/5/6f5ff66c-6775-42b0-86c4-47d41f2da187/Win8.1AndW2K12R2-KB3191564-x64.msu)
* After downloading KB3191566 for Windows 7, additionally unpack the Win7AndW2K8R2-KB3191566-x64.zip archive
* Run the files: Win7AndW2K8R2-KB3191566-x64.msu (for Windows 7) or Win8.1AndW2K12R2-KB3191564-x64.msu (for Windows 8.1)
* Install the KB3191564/KB3191566 update following the installation wizard instructions
#### 4. Install the KB2999226 update:
* Download KB2999226 update via the link:
- [Download KB2999226 for Windows 7](https://download.microsoft.com/download/1/1/5/11565a9a-ea09-4f0a-a57e-520d5d138140/Windows6.1-KB2999226-x64.msu)
- [Download KB2999226 for Windows 8.1](https://download.microsoft.com/download/9/6/f/96fd0525-3ddf-423d-8845-5f92f4a6883e/Windows8.1-KB2999226-x64.msu)
* Run the files: Windows6.1-KB2999226-x64.msu (for Windows 7) or Windows8.1-KB2999226-x64.msu (for Windows 8.1)
* Install the KB2999226 update following the installation wizard instructions
#### 5. Restart PC/Notebook

### How to use (Windows):
#### 1. Extract the IPA_Downloader.zip archive using any archiver (for example: [7-Zip](https://www.7-zip.org))
#### 2. Double-click the Start_IPA_Downloader_Windows.bat file
#### 3. On the first run, initial configuration is required:
* Select language
* Press Enter
* When an update is available, choose to either visit the repository to download new script version or continue with current version
* Press Enter
#### 4. By default, the script starts in IPA_Downloader mode (downloading and installing apps):
* To log in, enter the command: 1. Log in to Apple account
* Press Enter
* Enter Apple account (Enter email:)
* Press Enter
* Enter password (Enter password:)
* Press Enter
* Tap `Allow` on your device and remember the two-factor authentication (2FA) code
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to `Settings - Apple Account - Sign-In & Security - Get Verification Code` (this is the two-factor authentication (2FA) code)
* Enter the two-factor authentication code (Enter 2FA code:)
* Press Enter
* Enter the required command
* Press Enter

## Using on macOS:
### macOS requirements:
#### All steps must be performed strictly in the following order:
#### 1. Download PowerShell:
`powershell-xxx-osx-arm64.pkg` for Apple Silicon or `powershell-xxx-osx-x64.pkg` for Intel:
- [Download the latest version of PowerShell](https://github.com/PowerShell/PowerShell/releases)
- [Download PowerShell 7.4.22 for macOS 11 Big Sur](https://github.com/PowerShell/PowerShell/releases/tag/v7.4.22)
- [Download PowerShell 7.3.12 for macOS 10.15 Catalina](https://github.com/PowerShell/PowerShell/releases/download/v7.3.12/powershell-7.3.12-osx-x64.pkg)
#### 2. Install PowerShell

### How to use (macOS):
#### 1. Extract the IPA_Downloader.zip archive using any archiver (for example: [Keka](https://www.keka.io))
#### 2. Double-click the Start_IPA_Downloader_macOS.command file
* The first time you run it, macOS will block Start_IPA_Downloader_macOS.command from opening
* In the dialog that appears, `"Start_IPA_Downloader_macOS.command" was not opened` click `Done`
* Click the Apple menu in the top-left corner of the screen and select `System Settings`
* In the left sidebar, scroll down and select `Privacy & Security`
* Scroll down the right side of the screen to the `Security` section
* Next to `Start_IPA_Downloader_macOS.command was blocked to protect your Mac`, click `Open Anyway`
* In the pop-up window `Open "Start_IPA_Downloader_macOS.command"?`, click `Open Anyway`
* Enter Mac password or use Touch ID
#### 3. On the first run, initial configuration is required:
* Select language
* Press Enter
* When an update is available, choose to either visit the repository to download new script version or continue with current version
* Press Enter
#### 4. By default, the script starts in IPA_Downloader mode (downloading and installing apps):
* To log in, enter the command: 1. Log in to Apple account
* Press Enter
* Enter Apple account (Enter email:)
* Press Enter
* Enter password (Enter password:)
* Press Enter
* Tap `Allow` on your device and remember the two-factor authentication (2FA) code
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to `Settings - Apple Account - Sign-In & Security - Get Verification Code` (this is the two-factor authentication (2FA) code)
* Enter the two-factor authentication code (Enter 2FA code:)
* Press Enter
* Enter the required command
* Press Enter

#### Note:
* You can use AirDrop to install the app: simply transfer the file to your iPhone, and the app will be installed automatically

## Using on Linux:
### Linux requirements:
#### Install the required packages:
#### Arch Linux / Manjaro:
* Install PowerShell: `sudo pacman -S powershell-bin` (or via AUR: `yay -S powershell-bin`)
* Install usbmuxd: `sudo pacman -S usbmuxd`
* Enable usbmuxd service: `sudo systemctl enable --now usbmuxd`
#### Ubuntu / Debian:
* Install PowerShell: [Microsoft Instructions](https://learn.microsoft.com/powershell/scripting/install/install-ubuntu) or `sudo snap install powershell --classic`
* Install usbmuxd: `sudo apt install usbmuxd`
* Enable usbmuxd service: `sudo systemctl enable --now usbmuxd`
#### Fedora / RHEL:
* Install PowerShell: `sudo dnf install powershell`
* Install usbmuxd: `sudo dnf install usbmuxd`
* Enable usbmuxd service: `sudo systemctl enable --now usbmuxd`

### How to use (Linux):
#### 1. Extract the IPA_Downloader archive using any archiver
#### 2. Make the launcher script executable (if needed):
* Type in Terminal: `chmod +x Start_IPA_Downloader_Linux.sh`
* Press Enter
#### 3. Run the script:
* Type in Terminal: `./Start_IPA_Downloader_Linux.sh` (or double-click `Start_IPA_Downloader_Linux.sh` in your file manager)
* Press Enter
#### 4. On the first run, initial configuration is required:
* Select language
* Press Enter
* When an update is available, choose to either visit the repository to download new script version or continue with current version
* Press Enter
#### 5. By default, the script starts in IPA_Downloader mode (downloading and installing apps):
* To log in, enter the command: 1. Log in to Apple account
* Press Enter
* Enter Apple account (Enter email:)
* Press Enter
* Enter password (Enter password:)
* Press Enter
* Tap `Allow` on your device and remember the two-factor authentication (2FA) code
* If the two-factor authentication (2FA) code doesn't arrive automatically, turn on Airplane mode on your device, go to `Settings - Apple Account - Sign-In & Security - Get Verification Code` (this is the two-factor authentication (2FA) code)
* Enter the two-factor authentication code (Enter 2FA code:)
* Press Enter
* Enter the required command
* Press Enter

## Script commands description:
### IPA_Downloader (downloading and installing apps):
#### 1. Search for apps by name or ID and purchase (without downloading):
* Enter the app name or app IDs to search
* Press Enter
* If an app name is entered, a list of found apps will be displayed
* Enter the index numbers (#) of the apps to purchase
* Press Enter
* The script will purchase the selected apps

* If app IDs are entered, the script will purchase the specified apps
#### 2. Search for apps by name or ID and download latest version:
* Enter the app name or app IDs to search
* Press Enter
* If an app name is entered, a list of found apps will be displayed
* Enter the index numbers (#) of the apps to download
* Press Enter
* The script will download the selected apps

* If app IDs are entered, the script will download the specified apps
#### 3. Search for apps by name or ID and download (with version selection):
* Enter the app name or app IDs to search
* Press Enter
* If an app name is entered, a list of found apps will be displayed
* Enter the index numbers (#) of the apps to display app version IDs
* Press Enter
* A list of app version IDs will be displayed (from the first to the latest)
* Enter index numbers (#) of version IDs or version IDs to display app versions
* Press Enter
* A list of app versions will be displayed
* Enter the index numbers (#) of the app versions to download
* Press Enter
* The script will download the selected app versions

* If app IDs are entered:
* A list of app version IDs will be displayed (from the first to the latest)
* Enter index numbers (#) of version IDs or version IDs to display app versions
* Press Enter
* A list of app versions will be displayed
* Enter the index numbers (#) of the app versions to download
* Press Enter
* The script will download the selected app versions
#### 4. Select an app list and purchase (without downloading):
* Select the app list to display:
1. Popular apps list (Files/AppsList.txt)
2. List of popular apps not purchased by the script
3. Custom apps list (Files/AppsListCustom.txt)
* Press Enter
* The selected list will be displayed
* Enter the index numbers (#) of the apps to purchase
* Press Enter
* The script will purchase the selected apps
#### 5. Select an app list and download latest version:
* Select the app list to display:
1. Popular apps list (Files/AppsList.txt)
2. List of apps from the Apple account purchase history (Files/AppsListAccount_.txt)
3. List of apps installed on the device
4. List of offloaded apps installed on the device
5. Custom apps list (Files/AppsListCustom.txt)
* Press Enter
* The selected list will be displayed
* Enter the index numbers (#) of the apps to download
* Press Enter
* The script will download the selected apps
#### 6. Select an app list and download (with version selection):
* Select the app list to display:
1. Popular apps list (Files/AppsList.txt)
2. List of apps from the Apple account purchase history (Files/AppsListAccount_.txt)
3. List of apps installed on the device
4. List of offloaded apps installed on the device
5. Custom apps list (Files/AppsListCustom.txt)
* Press Enter
* The selected list will be displayed
* Enter the index numbers (#) of the apps to download
* Press Enter
* A list of app version IDs will be displayed (from the first to the latest)
* Enter index numbers (#) of version IDs or version IDs to display app versions
* Press Enter
* A list of app versions will be displayed
* Enter the index numbers (#) of the app versions to download
* Press Enter
* The script will download the selected app versions
#### 7. Check the minimum iOS version for apps in the Apps folder:
* Move the .ipa files to the Apps folder
* The script will check the minimum iOS version required to install the app
#### 8. Install apps from Apps folder:
* Move the .ipa files to the Apps folder
* Connect the device/devices using a cable
* Tap `Trust` when the `Trust This Computer?` prompt appears
* Enter the index numbers (#) of the devices for installation
* Press Enter
* Enter the index numbers (#) of the apps to install on the devices
* Press Enter
* The script will install the selected apps on the devices
#### 9. Clear data:
* Select the data to clear:
1. List of apps purchased by the script (Files/PurchasedAppsList.json)
2. Apps in Apps folder
* Press Enter
* When choosing to clear the list of apps purchased by the script, select the Apple account to clear
* Press Enter
* The script will clear the selected data type
#### 10. Apple Account operations:
* Enter the required action:
1. Add account
2. Switch account
3. Log out of Apple Account
* Press Enter
#### 11. Tip Jar:
* The script will navigate to the CloudTips page
#### 12. Change Language (Сменить язык):
* The script will change its interface language
#### air
* Enabling/disabling connection to the device via Wi-Fi
#### debug
* Enable/disable debug mode

### IPA_Installer (installing apps only):
#### 1. Check the minimum iOS version for apps in the Apps folder:
* Move the .ipa files to the Apps folder
* The script will check the minimum iOS version required to install the app
#### 2. Install apps from Apps folder:
* Move the .ipa files to the Apps folder
* Connect the device/devices using a cable
* Tap `Trust` when the `Trust This Computer?` prompt appears
* Enter the index numbers (#) of the devices for installation
* Press Enter
* Enter the index numbers (#) of the apps to install on the devices
* Press Enter
* The script will install the selected apps on the devices
#### 3. Tip Jar:
* The script will navigate to the CloudTips page
#### 4. Change Language (Сменить язык):
* The script will change its interface language
#### 5. Switch to IPA_Downloader (downloading and installing apps):
* The script will switch the mode to IPA_Downloader
#### air
* Enabling/disabling connection to the device via Wi-Fi
#### debug
* Enable/disable debug mode

## Possible errors and solutions:
### Troubleshooting errors:
**1. command not found: pwsh:**
* PowerShell (pwsh) is not installed.

**2. Processing -File ./IPA_Downloader.ps1 failed: Access to the path is denied (macOS):**
* Allow Terminal access in `System Settings - Privacy & Security - Full Disk Access`.

**3. Two-factor authentication (2FA) code not received or Login error: Did you forget your password?:**
* The password was entered incorrectly.
* Try signing in to `icloud.com` website using Apple account.

**4. Login error: failed to initialize SAP signer: curl: Timeout was reached:**
* Failed to connect to SAP, check your internet connection.

**5. Error: account is disabled:**
* Apple account is temporarily blocked by Apple (usually due to multiple attempts to enter incorrect password or 2FA code).
* Account needs to be unblocked via the device or on the `icloud.com` website.

**6. Download error: invalid response: empty songList:**
* Re-log in to the script using Apple account.

**7. Download error: HTTP request failed: Couldn't resolve host name:**
* Failed to connect to Apple servers, check your internet connection.

**8. Download error: HTTP request failed: Timeout was reached:**
* Failed to connect to Apple servers, check your internet connection.

**9. Download failed after retries: Failure when receiving data from the peer:**
* Failed to connect to Apple servers, check your internet connection.
* Or re-log in to the script using Apple account.

**10. Error: license is required:**
* The app was not previously purchased on this Apple account.

**11. Purchase error: app not found:**
* App purchase failed because the app has been removed from the App Store.

**12. Purchase error: item is temporarily unavailable:**
* The app was not previously purchased on this Apple account.
* The purchase failed because the app has been removed from the App Store.

**13. Error: This Apple Account is temporarily unable to be used in the iTunes Store because it could not be found. Try again later:**
* Make any free purchase in the App Store.

**14. Error: No connected devices found.`nConnect a device and trust this computer:**
* Connect the device and tap `Trust` when the `Trust This Computer?` prompt appears.
* Make sure the AppleMobileDeviceSupport64 driver is installed.
* Reinstall/install iTunes/Apple Devices or AppleMobileDeviceSupport64.

**15. Could not connect to lockdownd:**
* Issues with connecting to an Apple device.
* Uninstall iTunes/Apple Devices and AppleMobileDeviceSupport64, then delete the folders listed below and reinstall iTunes/Apple Devices or AppleMobileDeviceSupport64.
```
C:\ProgramData\Apple\
C:\ProgramData\Apple\Apple Computer\
C:\Users\%username%\AppData\Local\Apple Computer\
C:\Users\%username%\AppData\Local\Apple Inc\
C:\Users\%username%\AppData\Roaming\Apple Computer\
```
* Connect the device and tap `Trust` when the `Trust This Computer?` prompt appears.

**16. WARNING: could not locate Payload/App.app/SC_Info/App.sinf in archive:**
* App signature not found in the installed .ipa file.

**17. ERROR: Install failed. Got error "APIInternalError" with code 0x00000000: Error Domain=IXErrorDomain Code=46:**
* Remove the app from the device, restart the device, and try installing the app again.

**18. The app immediately closes when launched after installation:**
* Log in to the App Store using the account from which the app was downloaded, and install any free app.
* After that, launch the problematic app again.

### If you encounter an issue:
#### Please provide the following information:
* The operating system and version of IPA_Downloader being used
* Enter the debug command in the script's main menu, reproduce the action that leads to the error, and send the result
* A screenshot of the error

## Useful information:
### Finding an App ID:
#### Option 1:
* Find the app link in the App Store and copy the value after `id` in the URL.
<details>
 <summary>Screenshot (click to view)</summary>
<img width="389" height="36" alt="AppStore_Link" src="https://github.com/user-attachments/assets/e73fd860-ed11-4293-8600-aef61fe3dc7f" />
</details>

#### Option 2:
* If the app is installed on your device, press and hold the app icon:
* The Share App option will appear
* Copy the link and paste it into a browser
* Copy the value after `id` in the URL

#### Option 3:
* You can view the full list of purchased apps via the website [reportaproblem.apple.com](https://reportaproblem.apple.com)
* Next, enter the app name in the search box on the [appmagic.rocks](https://appmagic.rocks/top-charts/apps) website and go to the app's page
* On the app page, select Select App with the App Store icon and copy the value at the end of the URL

### Tracking new app releases:
- [The 4PDA thread](https://4pda.to/forum/index.php?showtopic=1046078)
- [AppBank Website](https://pwa.appbank.pw)

## Tip Jar:
* IPA_Downloader is completely free, however, if you want to support the project voluntarily, you can do so via the link below or using the QR code:
- [Support via CloudTips](https://pay.cloudtips.ru/p/93c0b094)

<img width="320" height="320" alt="qrCode" src="https://github.com/user-attachments/assets/1013fdce-2f18-4b5e-bd73-9237f691f51a" />
