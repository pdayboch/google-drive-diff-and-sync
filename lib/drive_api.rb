require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class DriveApi
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Drive API Ruby Compare Directories'
  TOKEN_PATH = 'token.yaml'
  FOLDER_MIME_TYPE = 'application/vnd.google-apps.folder'

  def initialize(creds_path)
    @drive_service = get_drive_service(creds_path)
  end

  def list_drive_files_recursive(
    folder_id,
    path = '',
    files = [],
    page_token = nil
  )
    query = "'#{folder_id}' in parents and trashed = false"

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
        puts("diving into #{full_path}")
        list_drive_files_recursive(
          file.id,
          full_path + '/',
          files
        )
      else
        files << full_path
      end
    end

    # Recursive call to continue listing if there's another page of results
    if response.next_page_token
      list_drive_files_recursive(
        folder_id,
        path,
        files,
        response.next_page_token
      )
    end

    files
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
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
