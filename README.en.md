# IPA_Downloader
[![ru](https://img.shields.io/badge/lang-ru-red.svg)](https://github.com/kda2495/IPA_Downloader/blob/main/README.md)

PowerShell script (for Windows) for downloading ipa files of previously downloaded applications (works in conjunction with [IPATool](https://github.com/majd/ipatool))  
## Description
The script allows you to download apps that were previously downloaded with your AppleID (similar to iMazing) for further installation on devices (for example, via [3uTools](https://www.3u.com/)).
## How to use
To work with the script, you need to log in with your AppleID.   
Double-click on !Start_IPA_Downloader.bat  
Next, the script will run and prompt you to log in with your AppleID account (if you haven't logged in before), and you must first enter your AppleID data, then your password (INF enter password) and the two-factor authentication code (INF enter 2FA code).  
<ins>**Please note that the password is not shown when you enter it for security reasons.**</ins>  
The script will then offer several commands to choose from.  

**Description of script commands:**  
1.Search for the app and download the latest version  
2.Enter the app ID and download the latest version  
3.Enter the app ID and download (with a choice of version)  
4.Display the list of app IDs and download the latest version  
5.Display the list of app IDs and download (with a choice of version)  
6.Revoke your AppleID data from IPATool  

App search does not search for everything, the easiest way to find the app ID is to know its link in the AppStore (for example, we search for an app in the search engine, find the link in the AppStore, and we need the numbers that come after the id from this link.  
<details>
 <summary>Screenshot</summary>
<img width="389" height="36" alt="1" src="https://github.com/user-attachments/assets/fefcabfe-ac65-4386-ba37-3b2fe3bd0f92" />  
</details>
  
Or we search through the website [Appmagic.rocks](https://appmagic.rocks/) (at the top right, enter the name of the app in the Search for app or publisher field...), then go to the app page and the ID number will be in the link.  

Also, some application IDs can be output using commands 4 and 5. 

Next, we enter these numbers (App ID) (or paste them with the right mouse button into the script window, if previously copied to the clipboard), when the script prompts "Enter the app ID to download" and press Enter.  
<details>
  <summary>Screenshot</summary>
<img width="978" height="512" alt="2" src="https://github.com/user-attachments/assets/22e22f5c-7927-4c82-b53f-bb34058d6c36" />
</details>

After downloading, the IPA_Downloader/Apps folder will contain a file with the name of the app ID and the version of the app (for example, for Активы Онлайн (Сбербанк): 6742457200_16.13.0.ipa).  

Next, apps downloaded with this script can be installed via 3uTools (connect the device, open 3uTools, go to the Apps tab, select Import & Install ipa and find the app file).  

## Downloading earlier versions of the app
In the script, select commands 3 or 5, enter the app ID, then the script will give us a comma-separated list of versions (versions are sorted from first to last), enter the version we need, and after downloading, install it via 3uTools.  
<details>
 <summary>Screenshot</summary>
<img width="977" height="509" alt="3" src="https://github.com/user-attachments/assets/1180476b-4ee3-40d2-9b83-43b29fe45b51" />
</details>

An important note. If the app is not available in your region or has been removed from the AppStore, then if there is an update in the AppStore, it will be displayed, but there will be an error when trying to update. To update, you need to delete the old version of the application, download the new version via IPA_Downloader and install via 3uTools.

## Windows 7 support
Windows 7 has 2 limitations:  
1\. To add IPATool support, you need to patch ipatool.exe with this patch:  
[GoWin7Fixer](https://github.com/stunndard/golangwin7patch/releases/tag/v0.2)  
Launch GoWin7Fixer.exe and either transfer ipatool.exe directly on the program window, or click Open and specify ipatool.exe.  
<details>
<summary>Screenshot</summary>
<img width="878" height="595" alt="5" src="https://github.com/user-attachments/assets/64d4086b-4f96-4f56-a2b3-be308f8b34bf" />
</details>

2\. To add PowerShell 3.0 support, you need to install the KB2506143 update:  
[Download link](https://www.microsoft.com/en-us/download/details.aspx?id=34595)  
For Windows 7 x64: Windows6.1-KB2506143-x64.msu  
For Windows 7 x86: Windows6.1-KB2506143-x86.msu  
<details>
<summary>Screenshot</summary>
<img width="972" height="617" alt="4" src="https://github.com/user-attachments/assets/586ad840-6f3f-4d6d-9f73-fda18b838642" />
</details>
Without this update, the download of the list of apps with commands 4-5 will not be available.
