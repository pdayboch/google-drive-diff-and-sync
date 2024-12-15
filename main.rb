# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require './lib/drive_api'
require './lib/local_file_objects'
require './lib/file_tree_differ'

GOOGLE_DRIVE_CREDS_PATH = 'service-account-key.json'
UNSYNCED_LIST_PATH = 'unsynced_list.yaml'

class Main
  def initialize
    @unsynced_list = YAML.load_file(UNSYNCED_LIST_PATH)[:unsynced_objects]
    @drive_api = DriveApi.new(GOOGLE_DRIVE_CREDS_PATH)
  end

  def run
    local_files = LocalFileObjects.new('/Volumes/Phil Backup')
                                  .all_files_metadata(['Documents'])

    drive_files = @drive_api.all_files_metadata

    diffs = FileTreeDiffer.new(
      local_files,
      drive_files,
      @unsynced_list
    ).diff

    FileTreeDiffer.print_diff(diffs)
  rescue LocalFileObjects::InvalidPathError => e
    puts(e.message)
  end
end

main = Main.new
main.run
