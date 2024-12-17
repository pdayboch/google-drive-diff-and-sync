# frozen_string_literal: true

require './lib/files/drive_file_metadata'

class DriveApi
  FOLDER_MIME_TYPE = 'application/vnd.google-apps.folder'

  def initialize(drive_service)
    @drive_service = drive_service
  end

  def all_files_metadata
    files = fetch_metadata_from_drive
    build_full_paths(files)
  end

  def download_files(drive_file_metadatas, root_path)
    raise LocalFileObjects::InvalidPathError, "#{root_path} does not exist." unless Dir.exist?(root_path)

    drive_file_metadatas.each do |file|
      file_path = File.join(root_path, file.path)
      FileUtils.mkdir_p(File.dirname(file_path))

      begin
        @drive_service.get_file(file.drive_id, download_dest: file_path)
        puts "Downloaded file: #{file.path} to #{root_path}"
      rescue Google::Apis::ClientError => e
        puts "Failed to download file #{file.path}:"
        puts "Error message: #{e.message}"
        puts "Error status code: #{e.status_code}" if e.respond_to?(:status_code)
        puts "Error details: #{e.body}" if e.respond_to?(:body)
      rescue Google::Apis::ServerError => e
        puts "Server error while downloading file #{file.path}: #{e.message}"
      rescue StandardError => e
        puts "An unexpected error occurred for file #{file.path}: #{e.message}"
      end
    end
  end

  private

  def fetch_metadata_from_drive
    all_files = []
    page_token = nil

    loop do
      response = @drive_service.list_files(
        q: 'trashed = false',
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
end
