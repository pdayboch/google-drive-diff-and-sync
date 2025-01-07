# Google Drive - Local file comparison app
### Author
Philip Dayboch - software@dayboch.com

## About
This application helps you check the synchronization state between a Google Drive root folder and a local folder on your hard disk. It identifies which folders or files are present in Google Drive but missing locally, and vice versa.

I developed this application to address limitations in the official Google Drive desktop application. The official app forces users to sync Drive files to a predefined directory on their computer, and synced files are stored in the "Computers" section of Google Drive rather than the main Drive folder.

This application provides flexibility by allowing users to:

Choose which files to back up.
Specify where to back them up.
Optionally report missing files without performing any automatic actions.
Future enhancements will include comparing the updated_at fields of files to detect out-of-sync files due to updates, not just missing files.

## Setup
1. Enable the Drive API in Google Cloud.
2. Create a Google Service Account with view permissions.
3. Create a Key for this service account and download the .json file. Store it in the project directory (make sure the name ends in `-key.json` so that it's ignored by git. Specify this credentials file using the -c flag. (Ex: `-c service-account-key.json`)

### Optional: Configure unsynced folders and files
1. Create an unsynced_list.yaml file in the root directory. This file allows you to customize which folders or files are purposefully not synced between the two storage volumes. The format is:
```
:unsynced_objects:
- 'folder1/folder2/'
- 'folder3/file3.ext'
```
Specify this list file using the -u flag (Ex: `-u unsynced_list.yaml`)

## Executing
Call `ruby main.rb -h` to see which options are avilable.

### Syncing files from Google Drive to Local
In addition to reporting unsynced files, there is an option to automatically download any unsynced files from Google Drive to the local volume. Enable this using the `ruby main.rb -l` flag. Without this flag, the app will only report which files are unsynced.

Automatic syncing from local to Google Drive is unavailable at this time.

---

## Contributions
Feel free to contribute to the Tincan project by submitting issues or pull requests to the respective repositories.

---

## License
This project is licensed under the MIT License. See the LICENSE file for details.
