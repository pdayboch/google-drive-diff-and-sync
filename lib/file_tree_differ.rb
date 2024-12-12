# frozen_string_literal: true

class FileTreeDiffer
  def initialize(local_objects, drive_objects, unsynced_list)
    @local_folders = local_objects[:folders]
    @local_files = local_objects[:files]
    @drive_folders = drive_objects[:folders]
    @drive_files = drive_objects[:files]
    @unsynced_objects = unsynced_list
  end

  def diffs
    missing_local_files = missing_local_files(missing_local_folders)
    missing_drive_files = missing_drive_files(missing_drive_folders)

    # Google Doc files get converted to office file types when downloaded,
    # so they will show up as missing since the extension isn't identical.
    # This identifies Google Doc files and removes them from the missing lists.
    google_docs = google_doc_files(missing_local_files, missing_drive_files)
    missing_drive_files -= google_docs[:local]
    missing_local_files -= google_docs[:drive]

    {
      missing_local: (missing_local_folders + missing_local_files).sort,
      missing_drive: (missing_drive_folders + missing_drive_files).sort
    }
  end

  def missing_local_folders
    @missing_local_folders ||= begin
      filtered_diffs = []
      (@drive_folders - @local_folders).sort.each do |folder|
        next if unsynced_object?(folder)

        # Ignore all diffs under a subfolder that's already missing and logged.
        filtered_diffs << folder if filtered_diffs.none? { |logged_diff| folder.include?(logged_diff) }
      end

      filtered_diffs
    end
  end

  def missing_drive_folders
    @missing_drive_folders ||= begin
      filtered_diffs = []
      (@local_folders - @drive_folders).sort.each do |folder|
        next if unsynced_object?(folder)

        # Ignore all diffs under a subfolder that's already missing and logged.
        # Ex: logged folder is 'Documents/Financial/Chase/'
        # and new missing folder is 'Documents/Financial/Chase/Statements',
        # we dont want to log the subfolder since the parent is already logged.
        filtered_diffs << folder if filtered_diffs.none? { |logged_diff| folder.include?(logged_diff) }
      end

      filtered_diffs
    end
  end

  def missing_local_files(missing_local_folders)
    filtered_diffs = []
    (@drive_files - @local_files).each do |file|
      next if unsynced_object?(file)

      filtered_diffs << file if missing_local_folders.none? { |logged_folder| file.include?(logged_folder) }
    end

    filtered_diffs
  end

  def missing_drive_files(missing_drive_folders)
    filtered_diffs = []
    (@local_files - @drive_files).each do |file|
      next if unsynced_object?(file)

      filtered_diffs << file if missing_drive_folders.none? { |logged_folder| file.include?(logged_folder) }
    end

    filtered_diffs
  end

  def google_doc_files(drive_only_files, local_only_files)
    local_google_doc_files = []
    drive_google_doc_files = []

    local_only_files.each do |local_file|
      potential_drive_doc_file = local_file.split('.')[0]
      if drive_only_files.include?(potential_drive_doc_file)
        local_google_doc_files << local_file
        drive_google_doc_files << potential_drive_doc_file
      end
    end

    {
      local: local_google_doc_files,
      drive: drive_google_doc_files
    }
  end

  def unsynced_object?(object)
    @unsynced_objects.any? { |uo| Regexp.new("^#{uo}").match(object) }
  end

  def self.empty_diffs?(diffs)
    diffs.all? { |_, v| v.empty? }
  end

  def self.print_diff_object(diff_object)
    puts('Synced!') if empty_diffs?(diff_object)

    if diff_object[:missing_local].any?
      puts('-' * 70)
      puts("\nThese are missing from local harddrive:")
      diff_object[:missing_local].each { |o| puts("- #{o}") }
      puts("\n#{'-' * 70}\n")
    end

    return unless diff_object[:missing_drive].any?

    puts("\nThese are missing from Google Drive:")
    diff_object[:missing_drive].each { |o| puts("- #{o}") }
    puts('-' * 70)
  end
end
