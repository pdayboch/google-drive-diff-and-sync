# frozen_string_literal: true

require './lib/files/file_metadata'

class LocalFileObjects
  class InvalidPathError < StandardError; end

  attr_reader :root_path

  def initialize(root_path)
    @root_path = root_path.chomp('/')
    raise InvalidPathError, "#{root_path} does not exist." unless Dir.exist?(root_path)
  end

  def all_files_metadata(parent_folders = [])
    files_metadata = []
    parent_folders.each do |parent_folder|
      full_parent_path = "#{root_path}/#{parent_folder}"

      next unless Dir.exist?(full_parent_path)

      files_metadata << Files::FileMetadata.new(
        parent_folder,
        File.directory?(full_parent_path),
        File.mtime(full_parent_path)
      )

      files_metadata += Dir.glob("#{full_parent_path}/**/*").map do |f|
        relative_path = f.gsub("#{root_path}/", '')

        Files::FileMetadata.new(
          relative_path,
          File.directory?(f),
          File.mtime(f)
        )
      end
    end

    files_metadata
  end
end
