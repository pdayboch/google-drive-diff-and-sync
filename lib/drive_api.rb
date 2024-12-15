# frozen_string_literal: true

require 'google/apis/drive_v3'
require 'googleauth'
require './lib/files/drive_file_metadata'

class DriveApi
  APPLICATION_NAME = 'Drive API Ruby Compare Directories'
  FOLDER_MIME_TYPE = 'application/vnd.google-apps.folder'
  OAUTH_SCOPES = [Google::Apis::DriveV3::AUTH_DRIVE_METADATA_READONLY].freeze

  def initialize(service_account_key_path)
    @service_account_key_path = service_account_key_path
  end

  def all_files_metadata
    files = fetch_metadata_from_drive
    build_full_paths(files)
  end

  private

  def fetch_metadata_from_drive
    all_files = []
    page_token = nil

    loop do
      response = drive_service.list_files(
        q: 'trashed = false',
        spaces: 'drive',
        fields: 'nextPageToken, files(id, name, mimeType, parents, modifiedTime)',
        page_size: 1000,
        page_token: page_token
      )
      puts("fetched #{response.files.size} objects from Drive")
      all_files.concat(response.files)
      page_token = response.next_page_token
      break unless page_token
    end

    all_files
  end

  def build_full_paths(files)
    # Create a lookup hash for quick parent resolution
    files_by_id = files.map { |f| [f.id, f] }.to_h
    build_recursive_paths(files, files_by_id)
  end

  def build_recursive_paths(items, files_by_id)
    items.map do |item|
      full_path = trace_path(item, files_by_id)
      full_path_with_name = "#{full_path}#{item.name}"

      Files::DriveFileMetadata.new(
        full_path_with_name,
        item.mime_type == FOLDER_MIME_TYPE,
        item.modified_time,
        item.id
      )
    end
  end

  def trace_path(item, files_by_id, current_path = '')
    return current_path if item.parents.nil?

    parent_id = item.parents.first
    parent = files_by_id[parent_id]

    return current_path unless parent

    trace_path(parent, files_by_id, "#{parent.name}/#{current_path}")
  end

  def drive_service
    @drive_service ||= begin
      drive_service = Google::Apis::DriveV3::DriveService.new
      drive_service.client_options.application_name = APPLICATION_NAME
      drive_service.authorization = authorize
      drive_service
    end
  end

  def authorize
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(@service_account_key_path),
      scope: OAUTH_SCOPES
    )
  end
end
