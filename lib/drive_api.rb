require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class DriveApi
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Drive API Ruby Compare Directories'
  TOKEN_PATH = 'token.yaml'
  FOLDER_MIME_TYPE = 'application/vnd.google-apps.folder'

  def initialize(creds_path, update_drive=false)
    @update_drive = update_drive
    @drive_service = get_drive_service(creds_path) if update_drive
  end

  def get_all_folders_and_files(root_folder_name)
    if @update_drive
      folder_id = get_root_folder_id(root_folder_name)
      objects = fetch_objects_recursive(folder_id)
      File.write('./drive_folder_list.csv', "#{objects[:folders].join("\n")}\n")
      File.write('./drive_file_list.csv', "#{objects[:files].join("\n")}\n")
      objects
    else
      {
        files: File.read('./drive_file_list.csv').split("\n"),
        folders: File.read('./drive_folder_list.csv').split("\n")
      }
    end
  end

  def fetch_objects_recursive(
    folder_id,
    path = '',
    files = [],
    folders = [],
    page_token = nil,
    count_fetches = { count: 0 }
  )
    query = "'#{folder_id}' in parents and trashed = false"

    count_fetches[:count] += 1
    print('.') if count_fetches[:count] % 15 == 0

    response = @drive_service.list_files(
      q: query,
      spaces: 'drive',
      fields: 'nextPageToken, files(id, name, mime_type)',
      page_size: 1000,
      page_token: page_token
    )

    response.files.each do |file|
      full_path = path + file.name

      if file.mime_type == FOLDER_MIME_TYPE
        folders << full_path + '/'

        fetch_objects_recursive(
          file.id,
          full_path + '/',
          files,
          folders,
          nil,
          count_fetches
        )
      else
        files << full_path
      end
    end

    # Recursive call to continue listing if there's another page of results
    if response.next_page_token
      puts("there is a next page")
      fetch_objects_recursive(
        folder_id,
        path,
        files,
        folders,
        response.next_page_token,
        count_fetches
      )
    end

    {
      files: files,
      folders: folders
    }
  end

  def get_root_folder_id(root_folder_name)
    query = "name = '#{root_folder_name}' and mimeType = 'application/vnd.google-apps.folder' and 'root' in parents and trashed = false"

    response = @drive_service
      .list_files(
        q: query,
        spaces: 'drive',
        fields: 'files(id, name)'
    )
    response.files.first.id
  end

  private
  def get_drive_service(creds_path)
    drive_service = Google::Apis::DriveV3::DriveService.new
    drive_service.client_options.application_name = APPLICATION_NAME
    drive_service.authorization = authorize(creds_path)
    drive_service
  end

  def authorize(creds_path)
    client_id = Google::Auth::ClientId.from_file(creds_path)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id,
      Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY,
      token_store
    )
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil? || credentials.needs_access_token?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "TOKEN REFRESH NEEDED.\n"
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
