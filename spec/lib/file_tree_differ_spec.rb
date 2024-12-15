# frozen_string_literal: true

require 'spec_helper'
require './lib/file_tree_differ'
require './lib/files/file_metadata'
require './lib/files/drive_file_metadata'

RSpec.describe FileTreeDiffer do
  describe '#diff' do
    context 'fully synced' do
      it 'returns correct empty diff' do
        root = Files::FileMetadata.new('Docs', true, Time.now)
        folder1 = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
        synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
        d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
        d_folder1 = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
        d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
        local_files = [root, folder1, synced_file]
        drive_files = [d_root, d_folder1, d_synced_file]
        diffs = FileTreeDiffer.new(
          local_files,
          drive_files,
          []
        ).diff

        expect(diffs).to eq(local_only: [], drive_only: [])
      end
    end

    context 'unsynced files' do
      context 'from local' do # missing on Drive
        it 'returns correct diffs' do
          root = Files::FileMetadata.new('Docs', true, Time.now)
          folder1 = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
          synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
          unsynced_file = Files::FileMetadata.new('Docs/subfolder1/unsynced_file.txt', false, Time.now)
          d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
          d_folder1 = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
          d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
          local_files = [root, folder1, synced_file, unsynced_file]
          drive_files = [d_root, d_folder1, d_synced_file]
          diffs = FileTreeDiffer.new(
            local_files,
            drive_files,
            []
          ).diff

          expect(diffs[:local_only].map(&:path)).to eq([unsynced_file.path])
          expect(diffs[:drive_only]).to eq([])
        end
      end

      context 'from drive' do # missing on local
        it 'returns correct diffs' do
          root = Files::FileMetadata.new('Docs', true, Time.now)
          folder1 = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
          synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
          d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
          d_folder1 = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
          d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
          d_unsynced_file = Files::DriveFileMetadata.new('Docs/subfolder1/missing_file.txt', false, Time.now, 4)
          local_files = [root, folder1, synced_file]
          drive_files = [d_root, d_folder1, d_synced_file, d_unsynced_file]
          diffs = FileTreeDiffer.new(
            local_files,
            drive_files,
            []
          ).diff

          expect(diffs[:local_only]).to eq([])
          expect(diffs[:drive_only].map(&:path)).to eq([d_unsynced_file.path])
        end
      end

      context 'from each local and drive' do
        it 'returns correct diffs' do
          root = Files::FileMetadata.new('Docs', true, Time.now)
          folder1 = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
          synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
          unsynced_file = Files::FileMetadata.new('Docs/subfolder1/unsynced_file.txt', false, Time.now)
          d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
          d_folder1 = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
          d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
          d_unsynced_file = Files::DriveFileMetadata.new('Docs/subfolder1/d_unsynced_file.txt', false, Time.now, 4)
          local_files = [root, folder1, synced_file, unsynced_file]
          drive_files = [d_root, d_folder1, d_synced_file, d_unsynced_file]
          diffs = FileTreeDiffer.new(
            local_files,
            drive_files,
            []
          ).diff

          expect(diffs[:local_only].map(&:path)).to eq([unsynced_file.path])
          expect(diffs[:drive_only].map(&:path)).to eq([d_unsynced_file.path])
        end
      end

      context 'with unsynced_list' do
        context 'from local' do # missing on Drive
          it 'returns correct empty diff' do
            root = Files::FileMetadata.new('Docs', true, Time.now)
            folder1 = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
            synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
            unsynced_file = Files::FileMetadata.new('Docs/subfolder1/unsynced_file.txt', false, Time.now)
            d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
            d_folder1 = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
            d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
            local_files = [root, folder1, synced_file, unsynced_file]
            drive_files = [d_root, d_folder1, d_synced_file]
            diffs = FileTreeDiffer.new(
              local_files,
              drive_files,
              [unsynced_file.path]
            ).diff

            expect(diffs[:local_only]).to eq([])
            expect(diffs[:drive_only]).to eq([])
          end
        end

        context 'from drive' do # missing on local
          it 'returns correct diffs' do
            root = Files::FileMetadata.new('Docs', true, Time.now)
            folder1 = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
            synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
            d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
            d_folder1 = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
            d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
            d_unsynced_file = Files::DriveFileMetadata.new('Docs/subfolder1/missing_file.txt', false, Time.now, 4)
            local_files = [root, folder1, synced_file]
            drive_files = [d_root, d_folder1, d_synced_file, d_unsynced_file]
            diffs = FileTreeDiffer.new(
              local_files,
              drive_files,
              [d_unsynced_file.path]
            ).diff

            expect(diffs[:local_only]).to eq([])
            expect(diffs[:drive_only]).to eq([])
          end
        end
      end
    end

    context 'unsynced folders' do
      context 'from local' do # missing on Drive
        it 'returns correct diffs' do
          root = Files::FileMetadata.new('Docs', true, Time.now)
          folder = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
          synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
          unsynced_folder = Files::FileMetadata.new('Docs/subfolder2', true, Time.now)
          unsynced_file = Files::FileMetadata.new('Docs/subfolder2/unsynced_file.txt', false, Time.now)
          d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
          d_folder = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
          d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
          local_files = [root, folder, synced_file, unsynced_folder, unsynced_file]
          drive_files = [d_root, d_folder, d_synced_file]
          diffs = FileTreeDiffer.new(
            local_files,
            drive_files,
            []
          ).diff

          expect(diffs[:local_only].map(&:path)).to eq([unsynced_folder.path])
          expect(diffs[:drive_only]).to eq([])
        end
      end

      context 'from drive' do # missing on local
        it 'returns correct diffs' do
          root = Files::FileMetadata.new('Docs', true, Time.now)
          folder = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
          synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
          d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
          d_folder = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
          d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
          d_unsynced_folder = Files::DriveFileMetadata.new('Docs/subfolder2', true, Time.now, 4)
          d_unsynced_file = Files::DriveFileMetadata.new('Docs/subfolder2/unsynced_file.txt', false, Time.now, 5)
          local_files = [root, folder, synced_file]
          drive_files = [d_root, d_folder, d_synced_file, d_unsynced_folder, d_unsynced_file]
          diffs = FileTreeDiffer.new(
            local_files,
            drive_files,
            []
          ).diff

          expect(diffs[:local_only]).to eq([])
          expect(diffs[:drive_only].map(&:path)).to eq([d_unsynced_folder.path])
        end
      end

      context 'from each local and drive' do
        it 'returns correct diffs' do
          root = Files::FileMetadata.new('Docs', true, Time.now)
          folder = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
          synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
          unsynced_folder = Files::FileMetadata.new('Docs/subfolder2', true, Time.now)
          unsynced_file = Files::FileMetadata.new('Docs/subfolder2/unsynced_file.txt', false, Time.now)
          d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
          d_folder = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
          d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
          d_unsynced_folder = Files::DriveFileMetadata.new('Docs/d_subfolder2', true, Time.now, 4)
          d_unsynced_file = Files::DriveFileMetadata.new('Docs/d_subfolder2/d_unsynced_file.txt', false, Time.now, 5)
          local_files = [root, folder, synced_file, unsynced_folder, unsynced_file]
          drive_files = [d_root, d_folder, d_synced_file, d_unsynced_folder, d_unsynced_file]
          diffs = FileTreeDiffer.new(
            local_files,
            drive_files,
            []
          ).diff

          expect(diffs[:local_only].map(&:path)).to eq([unsynced_folder.path])
          expect(diffs[:drive_only].map(&:path)).to eq([d_unsynced_folder.path])
        end
      end

      context 'with unsynced_list' do
        context 'from local' do # missing on Drive
          it 'returns correct empty diff' do
            root = Files::FileMetadata.new('Docs', true, Time.now)
            folder = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
            synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
            unsynced_folder = Files::FileMetadata.new('Docs/subfolder2', true, Time.now)
            unsynced_file = Files::FileMetadata.new('Docs/subfolder2/unsynced_file.txt', false, Time.now)
            d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
            d_folder = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
            d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
            local_files = [root, folder, synced_file, unsynced_folder, unsynced_file]
            drive_files = [d_root, d_folder, d_synced_file]
            diffs = FileTreeDiffer.new(
              local_files,
              drive_files,
              [unsynced_folder.path]
            ).diff

            expect(diffs[:local_only]).to eq([])
            expect(diffs[:drive_only]).to eq([])
          end
        end

        context 'from drive' do # missing on local
          it 'returns correct empty diff' do
            root = Files::FileMetadata.new('Docs', true, Time.now)
            folder = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
            synced_file = Files::FileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now)
            d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
            d_folder = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
            d_synced_file = Files::DriveFileMetadata.new('Docs/subfolder1/synced_file.txt', false, Time.now, 3)
            d_unsynced_folder = Files::DriveFileMetadata.new('Docs/subfolder2', true, Time.now, 4)
            d_unsynced_file = Files::DriveFileMetadata.new('Docs/subfolder2/unsynced_file.txt', false, Time.now, 5)
            local_files = [root, folder, synced_file]
            drive_files = [d_root, d_folder, d_synced_file, d_unsynced_folder, d_unsynced_file]
            diffs = FileTreeDiffer.new(
              local_files,
              drive_files,
              [d_unsynced_folder.path]
            ).diff

            expect(diffs[:local_only]).to eq([])
            expect(diffs[:drive_only]).to eq([])
          end
        end
      end
    end

    context 'google drive docs' do
      it 'returns correct empty diff' do
        root = Files::FileMetadata.new('Docs', true, Time.now)
        folder1 = Files::FileMetadata.new('Docs/subfolder1', true, Time.now)
        doc_file = Files::FileMetadata.new('Docs/subfolder1/some_sheet.csv', false, Time.now)
        d_root = Files::DriveFileMetadata.new('Docs', true, Time.now, 1)
        d_folder1 = Files::DriveFileMetadata.new('Docs/subfolder1', true, Time.now, 2)
        d_doc_file = Files::DriveFileMetadata.new('Docs/subfolder1/some_sheet', false, Time.now, 3)
        local_files = [root, folder1, doc_file]
        drive_files = [d_root, d_folder1, d_doc_file]
        diffs = FileTreeDiffer.new(
          local_files,
          drive_files,
          []
        ).diff

        expect(diffs).to eq(local_only: [], drive_only: [])
      end
    end
  end

  describe '.print_diff' do
    context 'with local_only' do
      it 'prints correctly' do
        local_only_file = Files::FileMetadata.new('Docs/folder1/file.txt', false, Time.now)
        diffs = { local_only: [local_only_file], drive_only: [] }
        expected_output = <<~OUTPUT
          ----------------------------------------------------------------------
          These are missing from Google Drive:
          - Docs/folder1/file.txt
          ----------------------------------------------------------------------
        OUTPUT

        expect { described_class.print_diff(diffs) }.to output(expected_output).to_stdout
      end
    end

    context 'with drive_only' do
      it 'prints correctly' do
        drive_only_file = Files::DriveFileMetadata.new('Docs/folder1/file.txt', false, Time.now, 1)
        diffs = { local_only: [], drive_only: [drive_only_file] }
        expected_output = <<~OUTPUT
          ----------------------------------------------------------------------
          These are missing locally:
          - Docs/folder1/file.txt
          ----------------------------------------------------------------------
        OUTPUT

        expect { described_class.print_diff(diffs) }.to output(expected_output).to_stdout
      end
    end

    context 'with local_only and drive_only' do
      it 'prints correctly' do
        local_only_file = Files::FileMetadata.new('Docs/folder1/file.txt', false, Time.now)
        drive_only_file = Files::DriveFileMetadata.new('Docs/folder1/drive_file.txt', false, Time.now, 1)
        diffs = { local_only: [local_only_file], drive_only: [drive_only_file] }
        expected_output = <<~OUTPUT
          ----------------------------------------------------------------------
          These are missing from Google Drive:
          - Docs/folder1/file.txt
          ----------------------------------------------------------------------
          These are missing locally:
          - Docs/folder1/drive_file.txt
          ----------------------------------------------------------------------
        OUTPUT

        expect { described_class.print_diff(diffs) }.to output(expected_output).to_stdout
      end
    end

    context 'without diffs' do
      it 'prints synced' do
        diffs = { local_only: [], drive_only: [] }
        expected_output = "Synced!\n"

        expect { described_class.print_diff(diffs) }.to output(expected_output).to_stdout
      end
    end
  end
end
