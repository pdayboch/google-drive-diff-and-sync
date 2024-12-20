# frozen_string_literal: true

require 'yaml'
require 'optparse'
require './lib/drive_service_initializer'
require './lib/drive_api'
require './lib/local_file_objects'
require './lib/file_tree_differ'

DEFAULT_DRIVE_CREDS_PATH = 'service-account-key.json'
DEFAULT_ROOT_PATH = '/Volumes/Phil Backup'
DEFAULT_PARENT_FOLDERS = ['Documents'].freeze

options = {
  drive_creds_path: DEFAULT_DRIVE_CREDS_PATH,
  root_path: DEFAULT_ROOT_PATH,
  parent_folders: DEFAULT_PARENT_FOLDERS,
  unsynced_list_path: nil,
  summarize_printout: true,
  sync_to_local: false
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby main.rb [options]'

  opts.on('-c', '--creds PATH', "Path to Google Drive credentials (default: #{DEFAULT_DRIVE_CREDS_PATH})") do |c|
    options[:drive_creds_path] = c
  end

  opts.on('-r', '--root PATH', "Local root directory path (default: #{DEFAULT_ROOT_PATH})") do |r|
    options[:root_path] = r
  end

  opts.on('-p', '--parent FOLDER1,FOLDER2', Array,
          'Comma-separated list of local parent folders within the local root directory ' \
          "(default: #{DEFAULT_PARENT_FOLDERS.join(', ')})") do |p|
    options[:parent_folders] = p
  end

  opts.on('-u', '--unsynced-list PATH', 'Path to a yaml list of unsynced files (optional)') do |u|
    options[:unsynced_list_path] = u
  end

  opts.on('--no-summarize-printout',
          'When printing diffs, print missing dirctories and all files contained within each directory ' \
          '(default: false)') do
    options[:summarize_printout] = false
  end

  opts.on('-l', '--sync-to-local', 'Enable syncing missing files from drive to local (default: false)') do
    options[:sync_to_local] = true
  end

  opts.on('-h', '--help', 'Print this help message') do
    puts opts
    exit
  end
end.parse!

class Main
  def initialize(drive_creds_path:, root_path:, parent_folders:, opts: {})
    @drive_service = DriveServiceInitializer.new(drive_creds_path).drive_service
    @root_path = root_path
    @parent_folders = parent_folders
    @unsynced_list = opts[:unsynced_list_path] ? YAML.load_file(opts[:unsynced_list_path]) : []
    @summarize_printout = opts[:summarize_printout]
    @sync_to_local = opts[:sync_to_local]
  end

  def run
    local_files = LocalFileObjects.new(@root_path)
                                  .all_files_metadata(@parent_folders)

    drive_api = DriveApi.new(@drive_service)
    drive_files = drive_api.all_files_metadata

    diffs = FileTreeDiffer.new(
      local_files: local_files,
      drive_files: drive_files,
      unsynced_list: @unsynced_list,
      summarize_printout: @summarize_printout
    )

    puts(diffs)
    exit(0) unless @sync_to_local
    drive_api.download_files(diffs.drive_only_files, @root_path)
  rescue LocalFileObjects::InvalidPathError => e
    puts("Invalid file path: #{e.message}")
    exit(1)
  end
end

main = Main.new(
  drive_creds_path: options[:drive_creds_path],
  root_path: options[:root_path],
  parent_folders: options[:parent_folders],
  opts: {
    unsynced_list_path: options[:unsynced_list_path],
    summarize_printout: options[:summarize_printout],
    sync_to_local: options[:sync_to_local]
  }
)
main.run
