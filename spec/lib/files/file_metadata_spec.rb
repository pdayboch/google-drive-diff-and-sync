# frozen_string_literal: true

require 'spec_helper'
require './lib/files/file_metadata'

RSpec.describe Files::FileMetadata do
  describe '#contains?' do
    context 'when file is not a directory' do
      it 'returns false' do
        file = Files::FileMetadata.new('doc/file.txt', false, Time.now)
        file2 = Files::FileMetadata.new('doc/file2.txt', false, Time.now)

        expect(file.contains?(file2)).to be_falsy
      end
    end

    context 'when file is directory' do
      context 'and contains the file' do
        it 'returns true' do
          folder = Files::FileMetadata.new('doc/subfolder', true, Time.now)
          file = Files::FileMetadata.new('doc/subfolder/file.txt', false, Time.now)

          expect(folder.contains?(file)).to be_truthy
        end
      end

      context 'and does not contain the file' do
        it 'returns false' do
          folder = Files::FileMetadata.new('doc/subfolder', true, Time.now)
          file = Files::FileMetadata.new('doc/subfolder2/file.txt', false, Time.now)

          expect(folder.contains?(file)).to be_falsy
        end
      end

      context 'and contains the folder' do
        it 'returns true' do
          folder = Files::FileMetadata.new('doc/subfolder', true, Time.now)
          folder2 = Files::FileMetadata.new('doc/subfolder/subfolder2', true, Time.now)

          expect(folder.contains?(folder2)).to be_truthy
        end
      end

      context 'and does not contain the folder' do
        it 'returns false' do
          folder = Files::FileMetadata.new('doc/subfolder', true, Time.now)
          folder2 = Files::FileMetadata.new('doc/subfolder2/subfolder3', true, Time.now)

          expect(folder.contains?(folder2)).to be_falsy
        end
      end

      context 'and checks against itself' do
        it 'returns false' do
          folder = Files::FileMetadata.new('doc/subfolder', true, Time.now)

          expect(folder.contains?(folder)).to be_falsy
        end
      end
    end
  end

  describe '#path_includes?' do
    context 'when file' do
      context 'is not in parent_path' do
        it 'returns correct value' do
          file = Files::FileMetadata.new('doc/subfolder2/file.txt', false, Time.now)
          expect(file.path_includes?('doc/subfolder')).to be_falsy
        end
      end

      context 'is inside parent_path' do
        it 'returns correct value' do
          file = Files::FileMetadata.new('doc/subfolder/subfolder2/file.txt', false, Time.now)
          expect(file.path_includes?('doc/subfolder')).to be_truthy
        end
      end
    end

    context 'when directory' do
      context 'is not in parent_path' do
        it 'returns correct value' do
          folder = Files::FileMetadata.new('doc/subfolder/subfolder2', true, Time.now)
          expect(folder.path_includes?('doc/subfolder/subfolder3')).to be_falsy
        end
      end

      context 'is inside parent_path' do
        it 'returns correct value' do
          folder = Files::FileMetadata.new('doc/subfolder/subfolder2/subfolder3', true, Time.now)
          expect(folder.path_includes?('doc/subfolder/subfolder2')).to be_truthy
        end
      end
    end
  end

  describe '#to_s' do
    it 'returns a string representation of the object with instance variables' do
      file_metadata = Files::FileMetadata.new('doc/file.txt', false, Time.now)

      output = file_metadata.to_s

      # Expect the output to include the instance variable names and their corresponding values
      expect(output).to include('path: doc/file.txt')
      expect(output).to include('is_directory: false')
      expect(output).to include('modified_at: ')
    end
  end
end
