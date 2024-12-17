# frozen_string_literal: true

module Files
  class FileMetadata
    attr_reader :name, :path, :is_directory, :modified_at

    def initialize(path, is_directory, modified_at)
      @path = path
      @is_directory = is_directory
      @modified_at = modified_at
    end

    def contains?(other_file)
      return false if is_directory == false

      other_file.path.start_with?("#{path}/")
    end

    def path_includes?(parent_path)
      !!%r{^#{Regexp.escape(parent_path)}(/|$)}.match(path)
    end

    def to_s
      vars = instance_variables.map do |var|
        "#{var.to_s.gsub('@', '')}: #{instance_variable_get(var)}"
      end.join("\n")
      "#{'-' * 15}\n#{vars}\n"
    end
  end
end
