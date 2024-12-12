# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require './lib/drive_api'
require './lib/local_file_objects'
require './lib/file_tree_differ'

GOOGLE_DRIVE_CREDS_PATH = 'service-account-key.json'
UNSYNCED_LIST_PATH = 'unsynced_list.yaml'

class Main
  attr_reader :unsynced_list, :drive_api

  def initialize
    @unsynced_list = YAML.load_file(UNSYNCED_LIST_PATH)[:unsynced_objects]
    @drive_api = DriveApi.new(GOOGLE_DRIVE_CREDS_PATH)
  end

  def run
    local_folders_and_files = LocalFileObjects
                              .get_all_folders_and_files('/Volumes/Phil Backup', 'Documents')

    drive_folders_and_files = drive_api.fetch_all_folders_and_files

    diffs = FileTreeDiffer.new(
      local_folders_and_files,
      drive_folders_and_files,
      unsynced_list
    ).diffs

    FileTreeDiffer.print_diff_object(diffs)
  rescue LocalFileObjects::VolumeNotConnectedError => e
    puts(e.message)
  end
end

main = Main.new
main.run
