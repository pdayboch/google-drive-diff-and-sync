# frozen_string_literal: true

# FileTreeDiffer is a utility class for comparing and analyzing differences between
# a local file system and a remote Google Drive file system. It helps identify which
# files or directories are present only locally, only on the drive, or synced between both.
#
# Key Features:
# - Identifies files present only locally (`local_only`) or only on Google Drive (`drive_only`).
# - Supports filtering of intentionally unsynced files.
# - Summarizes missing directories into a single entry when enabled.
# - Provides a string representation of differences for easy reporting.
#
# @example Basic Usage:
#   differ = FileTreeDiffer.new(
#     local_files: local_file_list,
#     drive_files: drive_file_list,
#     unsynced_list: unsynced_filepaths,
#     summarize_printout: true
#   )
#
#   puts differ.to_s # Outputs differences in a human-readable format.
#
class FileTreeDiffer
  # @param local_files [Array<FileMetadata>] list of local files and directories.
  # @param drive_files [Array<DriveFileMetadata>] list of remote Drive files and directories.
  # @param unsynced_list [Array<String>] file paths intentionally excluded from syncing.
  # @param summarize_printout [Boolean] summarizes missing directories instead of listing files.
  #   This is only applicable when generating the string representation of the diff (via `to_s`)
  def initialize(local_files:, drive_files:, unsynced_list: [], summarize_printout: true)
    @local_files = local_files
    @drive_files = drive_files
    @unsynced_list = unsynced_list
    @summarize_printout = summarize_printout
    @diff_result = compute_diff
  end

  # Returns the files that are present locally but missing on Google Drive.
  #
  # @return [Array<FileMetadata>] List of local files missing from Google Drive.
  def local_only
    @diff_result[:local_only]
  end

  # Returns the files that are present on Google Drive but missing locally.
  #
  # @return [Array<DriveFileMetadata>] List of Drive files missing locally.
  def drive_only
    @diff_result[:drive_only]
  end

  # Returns only the files (not directories) that are present on Google Drive but missing locally.
  #
  # @return [Array<DriveFileMetadata>] List of Drive files (excluding directories) missing locally.
  def drive_only_files
    @diff_result[:drive_only].reject(&:is_directory)
  end

  # Checks whether the local and Google Drive files are completely synced.
  #
  # @return [Boolean] True if both local and Drive files are fully synced, otherwise false.
  def synced?
    local_only.empty? && drive_only.empty?
  end

  # Generates a human-readable string representation of the file differences.
  #
  # @return [String] A string summarizing the differences between local and Drive files.
  #   If files are synced, returns "Synced!".
  def to_s
    return 'Synced!' if synced?

    str = "#{'-' * 70}\n"

    if local_only.any?
      str += "These are missing from Google Drive:\n"
      missing_files_to_display(local_only).each do |f|
        str += "- #{f.path}\n"
      end
      str += "#{'-' * 70}\n"
    end

    if drive_only.any?
      str += "These are missing locally:\n"
      missing_files_to_display(drive_only).each do |f|
        str += "- #{f.path}\n"
      end
      str += "#{'-' * 70}\n"
    end

    str
  end

  private

  def compute_diff
    local_only_files = local_files_missing_from_drive
    drive_only_files = drive_files_missing_from_local
    files = filter_google_docs(local_only_files, drive_only_files)
    filter_unsynced(files[:local_only], files[:drive_only])
  end

  def local_files_missing_from_drive
    @local_files.reject { |local_file| @drive_files.any? { |drive_file| local_file.path == drive_file.path } }
  end

  def drive_files_missing_from_local
    @drive_files.reject { |drive_file| @local_files.any? { |local_file| drive_file.path == local_file.path } }
  end

  # Google Doc files get converted to office file types when downloaded,
  # so they will show up as missing since the extension isn't identical.
  # This identifies Google Doc files and removes them from the missing lists.
  # Ex: Google Doc -> .docx, Google Sheets -> .xlsx, Google Slides -> .ppt
  def filter_google_docs(local_only_files, drive_only_files)
    local_google_doc_files = []
    drive_google_doc_files = []
    drive_only_filepaths = drive_only_files.reject(&:is_directory).map(&:path)

    local_only_files.reject(&:is_directory).each do |local_file|
      potential_drive_doc_filepath = local_file.path.split('.')[0]

      next unless drive_only_filepaths.include?(potential_drive_doc_filepath)

      drive_file = drive_only_files.find { |df| df.path == potential_drive_doc_filepath }
      local_google_doc_files << local_file
      drive_google_doc_files << drive_file
    end

    # filter out Google doc files from the missing list
    {
      local_only: local_only_files - local_google_doc_files,
      drive_only: drive_only_files - drive_google_doc_files
    }
  end

  def filter_unsynced(local_only_files, drive_only_files)
    {
      local_only: local_only_files.reject { |f| @unsynced_list.any? { |uf| f.path_includes?(uf) } },
      drive_only: drive_only_files.reject { |f| @unsynced_list.any? { |uf| f.path_includes?(uf) } }
    }
  end

  def missing_files_to_display(files)
    @summarize_printout ? filter_within_missing_folder(files) : files
  end

  def filter_within_missing_folder(missing_files)
    missing_folders = missing_files.select(&:is_directory)
    missing_files.reject { |f| missing_folders.any? { |missing_folder| missing_folder.contains?(f) } }
  end
end
