class LocalFileObjects
  class VolumeNotConnectedError < StandardError;end

  def self.get_all_folders_and_files(volume, root_folder)
    raise VolumeNotConnectedError.new("#{volume} is not connected") if !volume_connected?(volume)

    files = []
    folders = []
    Dir.glob("#{volume}/#{root_folder}/**/*").each do |f|
      files << f.gsub('/Volumes/Phil Backup/Documents/', '') if File.file?(f)
      folders << f.gsub('/Volumes/Phil Backup/Documents/', '') + '/' if File.directory?(f)
    end

    {
      files: files,
      folders: folders
    }
  end

  def self.volume_connected?(volume)
    File.directory?(volume)
  end
end
