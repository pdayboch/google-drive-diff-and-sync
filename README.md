## Google Drive - Local file comparison app

This app checks the sync state between a Google Drive root folder and a folder on the local hard disk. It will print out which folders or files are present in Drive but missing from the local hard disk, and vice versa. It's helpful when you have to manually keep these two drives in sync as it will tell you which files haven't been synced up or down yet.

### Setup
- Create a Google OAuth app with the scope `Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY`. This scope doesn't allow modifying files nor does it allow seeing file contents. The scope is very minimal in that it only allows viewing the File's metadata such as name, id, size, etc.. Download the Google OAuth config json and store it in a file called `google_drive_config.json` in the root directory.
- Create an unsynced_list.yaml file in the root directory. This file allows you to customize which folders or files are purposefully not synced between the two storage volumes. The format is:
```
:unsynced_objects:
- 'folder1/folder2/'
- 'folder3/file3.ext'
```