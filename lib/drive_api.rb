# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'googleauth'

class DriveApi
  APPLICATION_NAME = 'Drive API Ruby Compare Directories'
  FOLDER_MIME_TYPE = 'application/vnd.google-apps.folder'
  OAUTH_SCOPES = [Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY].freeze

  def initialize(service_account_key_path)
    @service_account_key_path = service_account_key_path
    @drive_service = get_drive_service
  end

  def get_all_folders_and_files(top_folder_name)
    folder_metadata = get_folder_metadata_in_root(top_folder_name)
    fetch_objects_recursive(folder_metadata: folder_metadata)
  end

  private

  # Obtains the metadata of a folder given a name that is located in the root directory
  def get_folder_metadata_in_root(folder_name)
    query = "name = '#{folder_name}' and mimeType = '#{FOLDER_MIME_TYPE}' and trashed = false"
    response = @drive_service.list_files(
      q: query,
      spaces: 'drive',
      fields: 'files(id, name, parents)'
    )

    # Look for the folder with no parents (it's in the root)
    response.files.find { |file| file.parents.nil? }
  end

  def fetch_objects_recursive(
    folder_metadata:,
    path: '',
    files: [],
    folders: [],
    page_token: nil,
    count_fetches: { count: 0 }
  )
    begin
      query = "'#{folder_metadata.id}' in parents and trashed = false"

      count_fetches[:count] += 1
      print('.') if (count_fetches[:count] % 15).zero?

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
          folders << "#{full_path}/"

          fetch_objects_recursive(
            folder_metadata: file,
            path: "#{full_path}/",
            files: files,
            folders: folders,
            page_token: nil,
            count_fetches: count_fetches
          )
        else
          files << full_path
        end
      end

      # Recursive call to continue listing if there's another page of results
      if response.next_page_token
        puts('there is a next page')
        fetch_objects_recursive(
          folder_metadata: folder_metadata,
          path: path,
          files: files,
          folders: folders,
          page_token: response.next_page_token,
          count_fetches: count_fetches
        )
      end
    rescue Google::Apis::ClientError => e
      puts "An error occurred while fetching Google Drive objects: #{e.message}"
    end

    { files: files, folders: folders }
  end

  def get_drive_service
    drive_service = Google::Apis::DriveV3::DriveService.new
    drive_service.client_options.application_name = APPLICATION_NAME
    drive_service.authorization = authorize
    drive_service
  end

  def authorize
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(@service_account_key_path),
      scope: OAUTH_SCOPES
    )
  end
end
