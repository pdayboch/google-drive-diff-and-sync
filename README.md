# Google Drive - Local file comparison app

This app checks the sync state between a Google Drive root folder and a folder on the local hard disk. It will print out which folders or files are present in Drive but missing from the local hard disk, and vice versa. It's helpful when you have to manually keep these two drives in sync as it will tell you which files haven't been synced up or down yet.

## Setup
1. Enable the Drive API in Google Cloud.
2. Create a Google Service Account with view permissions.
3. Create a Key for this service account and download the .json file. Store it in a file called `service-account-key.json` in the root directory.

### Optional: Configure unsynced folders and files
1. Create an unsynced_list.yaml file in the root directory. This file allows you to customize which folders or files are purposefully not synced between the two storage volumes. The format is:
```
:unsynced_objects:
- 'folder1/folder2/'
- 'folder3/file3.ext'
```