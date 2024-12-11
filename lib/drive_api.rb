# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'googleauth'
require 'concurrent-ruby'

class DriveApi
  APPLICATION_NAME = 'Drive API Ruby Compare Directories'
  FOLDER_MIME_TYPE = 'application/vnd.google-apps.folder'
  OAUTH_SCOPES = [Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY].freeze

  def initialize(service_account_key_path, max_concurrent_requests: 10)
    @service_account_key_path = service_account_key_path
    @drive_service = get_drive_service
    @max_concurrent_requests = max_concurrent_requests
    @semaphore = Mutex.new
    @files = Concurrent::Array.new
    @folders = Concurrent::Array.new
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
    page_token: nil
  )
    pool = Concurrent::FixedThreadPool.new(@max_concurrent_requests)

    begin
      query = "'#{folder_metadata.id}' in parents and trashed = false"
      response = @drive_service.list_files(
        q: query,
        spaces: 'drive',
        fields: 'nextPageToken, files(id, name, mime_type)',
        page_size: 1000,
        page_token: page_token
      )

      # Process files and folders concurrently
      response.files.each do |file|
        pool.post do
          full_path = path + file.name

          if file.mime_type == FOLDER_MIME_TYPE
            @semaphore.synchronize do
              @folders << "#{full_path}/"
            end

            # Recursively fetch this folder's contents
            subfolder_result = fetch_objects_recursive(
              folder_metadata: file,
              path: "#{full_path}/"
            )

            # Merge results from subfolder
            @semaphore.synchronize do
              @files.concat(subfolder_result[:files])
              @folders.concat(subfolder_result[:folders])
            end
          else
            @semaphore.synchronize do
              @files << full_path
            end
          end
        end
      end

      # Handle pagination if needed concurrently
      if response.next_page_token
        pool.post do
          next_page_result = fetch_objects_recursive(
            folder_metadata: folder_metadata,
            path: path,
            page_token: response.next_page_token
          )

          @semaphore.synchronize do
            @files.concat(next_page_result[:files])
            @folders.concat(next_page_result[:folders])
          end
        end
      end

      # Wait for all tasks to complete
      pool.shutdown
      pool.wait_for_termination
    rescue Google::Apis::ClientError => e
      puts "An error occurred while fetching Google Drive objects: #{e.message}"
    end

    { files: @files.uniq, folders: @folders.uniq }
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
