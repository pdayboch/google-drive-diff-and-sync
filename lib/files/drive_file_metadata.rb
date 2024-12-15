# frozen_string_literal: true

require './lib/files/file_metadata'

module Files
  class DriveFileMetadata < FileMetadata
    attr_reader :drive_id

    def initialize(path, is_directory, modified_at, drive_id)
      super(path, is_directory, modified_at)
      @drive_id = drive_id
    end
  end
end
