# frozen_string_literal: true

class FileTreeDiffer
  def self.print_diff(diff)
    if diff[:local_only].empty? && diff[:drive_only].empty?
      puts 'Synced!'
      return
    end

    puts('-' * 70)
    if diff[:local_only].any?
      puts('These are missing from Google Drive:')
      diff[:local_only].each { |f| puts("- #{f.path}") }
      puts(('-' * 70))
    end

    return unless diff[:drive_only].any?

    puts('These are missing locally:')
    diff[:drive_only].each { |f| puts("- #{f.path}") }
    puts('-' * 70)
  end

  # local_files - array of FileMetadata objects representing the list of local files and directories.
  # drive_files - array of DriveFileMetadata objects representing the list of remote Drive files and directories.
  # unsynced files - array of strings representing filepaths of files that are not synced between local and Drive.
  def initialize(local_files, drive_files, unsynced_list)
    @local_files = local_files
    @drive_files = drive_files
    @unsynced_files = unsynced_list
  end

  def diff
    local_only_files = local_files_missing_from_drive
    drive_only_files = drive_files_missing_from_local

    local_only_files = filter_within_unsynced_folder(local_only_files)
    drive_only_files = filter_within_unsynced_folder(drive_only_files)

    filtered_files = filter_google_docs(local_only_files, drive_only_files)
    filtered_files = filter_unsynced(filtered_files[:local_only], filtered_files[:drive_only])

    {
      local_only: filtered_files[:local_only],
      drive_only: filtered_files[:drive_only]
    }
  end

  private

  def local_files_missing_from_drive
    @local_files.reject { |local_file| @drive_files.any? { |drive_file| local_file.path == drive_file.path } }
  end

  def drive_files_missing_from_local
    @drive_files.reject { |drive_file| @local_files.any? { |local_file| drive_file.path == local_file.path } }
  end

  def filter_within_unsynced_folder(unsynced_list)
    unsynced_folders = unsynced_list.select(&:is_directory)
    unsynced_list.reject { |f| unsynced_folders.any? { |unsynced_folder| unsynced_folder.contains?(f) } }
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
      local_only: local_only_files.reject { |f| @unsynced_files.include?(f.path) },
      drive_only: drive_only_files.reject { |f| @unsynced_files.include?(f.path) }
    }
  end
end
