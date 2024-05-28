require 'yaml'
require 'fileutils'
require 'optparse'
require './lib/drive_api'
require './lib/local_file_objects'
require './lib/file_tree_differ'

GOOGLE_DRIVE_CREDS_PATH = 'google_drive_config.json'
UNSYNCED_LIST_PATH = 'unsynced_list.yaml'

class Main
  attr_reader :unsynced_list, :drive_api

  # Options:
  # -update_drive: If set to true, it will use the Google Drive API to reach out
  #                to Google Drive. If set to false, it will use the cached list
  #                of files for the Google Drive file list. Reaching out to Google
  #                Drive takes around 1 to 2 minutes to recurse all folders.
  def initialize(options)
    @unsynced_list = YAML.load_file(UNSYNCED_LIST_PATH)[:unsynced_objects]
    @drive_api = DriveApi.new(GOOGLE_DRIVE_CREDS_PATH, options[:update_drive])
  end

  def run
    local_folders_and_files = LocalFileObjects
      .get_all_folders_and_files("/Volumes/Phil Backup", "Documents")

    drive_folders_and_files = drive_api
      .get_all_folders_and_files("Documents")

    diffs = FileTreeDiffer.new(
      local_folders_and_files,
      drive_folders_and_files,
      unsynced_list
    ).get_diffs

    FileTreeDiffer.print_diff_object(diffs)
  rescue LocalFileObjects::VolumeNotConnectedError => e
    puts(e.message)
  end
end



options = {
  update_drive: false
}
OptionParser.new do |opt|
  opt.on('-u', '--update', "Pull latest files from Google Drive.") { |o| options[:update_drive] = o }
  opt.on("-h", "--help", "Prints the help") do
    puts opt
    exit
  end
end.parse!

main = Main.new(options)
main.run
