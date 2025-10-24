# IPA_Downloader
PowerShell script (for Windows) for downloading ipa files of previously downloaded applications (works in conjunction with [IPATool](https://github.com/majd/ipatool))  
## Description
The script allows you to download applications that were previously downloaded through your AppleID (similar to iMazing) for further installation on devices (for example, via [3uTools](https://www.3u.com/)).
## How to use
To work with the script, you need to log in with your AppleID.   
Double-click on !Start_IPA_Downloader.bat  
Next, the script will run and prompt you to log in with your AppleID account (if you haven't logged in before), and you must first enter your AppleID data, then your password (INF enter password) and the two-factor authentication code (INF enter 2FA code).  
<ins>**Please note that the password is not shown when you enter it for security reasons.**</ins>  
The script will then offer several commands to choose from.  

**Description of script commands:**  
1.Search for the app and download the latest version (if you have already logged in with your AppleID);  
2.Enter the application ID and download the latest version (if you know the application ID);  
3.Enter the application ID and download (with a choice of version) (if you know the application ID);  
4.Display the list of application IDs and download the latest version;  
5.Displaying the list of application IDs and downloading (with a choice of version);  
6.Revoke your AppleID data.

Application search does not search for everything, the easiest way to find the application ID is to know its link in the AppStore (for example, we search for an application in the search engine, find the link in the AppStore, and we need the numbers that come after the id from this link.  
<details>
 <summary>Screenshot 1</summary>
<img width="389" height="36" alt="1" src="https://github.com/user-attachments/assets/fefcabfe-ac65-4386-ba37-3b2fe3bd0f92" />  
</details>
  
Or we search through the website [Appmagic.rocks](https://appmagic.rocks/) (at the top right, enter the name of the application in the Search for app or publisher field...), then go to the application page and the ID number will be in the link.  

Also, some application IDs can be output using commands 4 and 5. (relevant for users from Russia)  

Next, we enter these numbers (Application ID) (or paste them with the right mouse button into the script window, if previously copied to the clipboard), when the script prompts "Enter the application ID to download" and press Enter.  
<details>
 <summary>Screenshot 2</summary>
<img width="976" height="513" alt="2" src="https://github.com/user-attachments/assets/a74893be-def6-487a-886e-a06d6a1722ee" />  
</details>

After downloading, the IPA_Downloader/Apps folder will contain a file with the name of the ID and the version of the application (for example, for Активы Онлайн (Сбербанк): 6742457200_16.13.0.ipa).  

Next, applications downloaded with this script can be installed via 3uTools (connect the device, open 3uTools, go to the Apps tab, select Import & Install ipa and find the application file).  

## Downloading earlier versions of the app
In the script, select commands 3 or 5, enter the application ID, then the script will give us a comma-separated list of versions (versions are sorted from first to last), enter the version we need, and after downloading, install it via 3uTools.  
<details>
 <summary>Screenshot 3</summary>
<img width="980" height="512" alt="3" src="https://github.com/user-attachments/assets/1a97ec5c-bdcb-415c-8073-0c96549a9a84" />
</details>

An important note. If the app is not available in your region or has been removed from the AppStore, then if there is an update in the AppStore, it will be displayed, but there will be an error when trying to update. To update, you need to delete the old version of the application, download the new version via IPA_Downloader and install via [3uTools](https://www.3u.com/)).
