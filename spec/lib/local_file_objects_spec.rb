# frozen_string_literal: true

require 'spec_helper'
require './lib/local_file_objects'

RSpec.describe LocalFileObjects do
  let(:root_path) { '/fake/root_path' }

  describe '.initialize' do
    context 'when root_path does not exist' do
      it 'raises an InvalidPathError' do
        allow(Dir).to receive(:exist?).with(root_path).and_return(false)

        expect { described_class.new(root_path) }
          .to raise_error(LocalFileObjects::InvalidPathError, "#{root_path} does not exist.")
      end
    end

    context 'when root_path exists' do
      it 'does not raise an error' do
        allow(Dir).to receive(:exist?).with(root_path).and_return(true)

        expect { described_class.new(root_path) }.not_to raise_error
      end
    end
  end

  describe '#all_files_metadata' do
    context 'when none of the parent folders exist' do
      it 'returns an empty array' do
        allow(Dir).to receive(:exist?).with(root_path).and_return(true)
        allow(Dir).to receive(:exist?).with("#{root_path}/parent1").and_return(false)
        allow(Dir).to receive(:exist?).with("#{root_path}/parent2").and_return(false)
        subject = described_class.new(root_path)

        expect(subject.all_files_metadata(%w[parent1 parent2])).to eq([])
      end
    end

    context 'when a parent folder exists' do
      it 'returns metadata for the parent folder and its files' do
        modified_time = Time.new(2024, 1, 1)
        folder = Files::FileMetadata.new('folder', true, modified_time)
        file = Files::FileMetadata.new("#{folder.path}/file.txt", false, modified_time)

        # root stubbing
        allow(Dir).to receive(:exist?).with(root_path).and_return(true)

        # folder stubbing
        allow(Dir).to receive(:exist?)
          .with("#{root_path}/#{folder.path}")
          .and_return(true)
        allow(File).to receive(:directory?)
          .with("#{root_path}/#{folder.path}")
          .and_return(true)
        allow(File).to receive(:mtime)
          .with("#{root_path}/#{folder.path}")
          .and_return(modified_time)
        allow(Dir).to receive(:glob)
          .with("#{root_path}/#{folder.path}/**/*")
          .and_return(["#{root_path}/#{file.path}"])

        # file stubbing
        allow(File).to receive(:directory?)
          .with("#{root_path}/#{file.path}")
          .and_return(false)
        allow(File).to receive(:mtime)
          .with("#{root_path}/#{file.path}")
          .and_return(modified_time)

        subject = described_class.new(root_path)
        metadata = subject.all_files_metadata([folder.path])

        expect(metadata).to match_array([
                                          have_attributes(
                                            path: folder.path,
                                            is_directory: true,
                                            modified_at: modified_time
                                          ),
                                          have_attributes(
                                            path: file.path,
                                            is_directory: false,
                                            modified_at: modified_time
                                          )
                                        ])
      end
    end
  end
end
