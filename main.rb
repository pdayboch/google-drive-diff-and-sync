require 'fileutils'
require './lib/drive_api'

GOOGLE_DRIVE_CREDS_PATH = 'google_drive_config.json'

class Main
  def initialize
    @drive_api = DriveApi.new(GOOGLE_DRIVE_CREDS_PATH)
  end

  def run
    documents_folder_id = @drive_api
      .get_root_folder_id("Documents")
    files = @drive_api
      .list_drive_files_recursive(documents_folder_id)
    File.write('drive_file_list.csv', "#{files.join("\n")}\n")
  end
end

main = Main.new
main.run
