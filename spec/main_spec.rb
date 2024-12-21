# frozen_string_literal: true

require 'spec_helper'
require './main'
require './lib/files/drive_file_metadata'

RSpec.describe Main do
  describe '#parse_options' do
    it 'sets the default options when no arguments are provided' do
      options = parse_options([])
      expect(options[:drive_creds_path]).to eq('service-account-key.json')
      expect(options[:root_path]).to eq('/Volumes/Phil Backup')
      expect(options[:parent_folders]).to eq(['Documents'])
      expect(options[:unsynced_list_path]).to be_nil
      expect(options[:summarize_printout]).to be(true)
      expect(options[:sync_to_local]).to be(false)
    end

    it 'sets the custom drive credentials path' do
      options = parse_options(['-c', '/custom/creds-key.json'])
      expect(options[:drive_creds_path]).to eq('/custom/creds-key.json')
    end

    it 'sets the custom root path' do
      options = parse_options(['-r', '/custom/root'])
      expect(options[:root_path]).to eq('/custom/root')
    end

    it 'parses parent folders as an array' do
      options = parse_options(['-p', 'folder1,folder2'])
      expect(options[:parent_folders]).to eq(%w[folder1 folder2])
    end

    it 'sets unused list path' do
      options = parse_options(['-u', '/path/to/unsynced.yaml'])
      expect(options[:unsynced_list_path]).to eq('/path/to/unsynced.yaml')
    end

    it 'disables summarize printout' do
      options = parse_options(['--no-summarize-printout'])
      expect(options[:summarize_printout]).to be_falsy
    end

    it 'enables sync to local' do
      options = parse_options(['-l'])
      expect(options[:sync_to_local]).to be_truthy
    end

    it 'prints help message' do
      expect do
        expect { parse_options(['-h']) }.to output('/Usage: ruby main.rb \[options\]/').to_stdout
      end.to raise_error(SystemExit)
    end
  end

  describe '#run' do
    let(:drive_service) { double('Google::Apis::DriveV3::DriveService') }
    let(:drive_service_initializer) { double('DriveServiceInitializer') }
    let(:local_file_objects) { double('LocalFileObjects') }
    let(:drive_api) { double('DriveApi') }
    let(:file_tree_differ) { double('FileTreeDiffer') }

    context 'when unsynced_list_path is unset' do
      it 'sends the correct args to FileTreeDiffer' do
        opts = {
          drive_creds_path: 'account-key.json',
          root_path: '/root/path',
          parent_folders: ['Documents'],
          unsynced_list_path: nil,
          summarize_printout: true,
          sync_to_local: false
        }

        allow(DriveServiceInitializer).to receive(:new).with('account-key.json').and_return(drive_service_initializer)
        allow(drive_service_initializer).to receive(:drive_service).and_return(drive_service)

        allow(LocalFileObjects).to receive(:new).with('/root/path').and_return(local_file_objects)
        allow(local_file_objects).to receive(:all_files_metadata).with(['Documents']).and_return([])

        allow(DriveApi).to receive(:new).with(drive_service).and_return(drive_api)
        allow(drive_api).to receive(:all_files_metadata).and_return([])

        expect(YAML).not_to receive(:load_file)
        expect(FileTreeDiffer).to receive(:new).with(
          local_files: [],
          drive_files: [],
          unsynced_list: [],
          summarize_printout: true
        ).and_return(file_tree_differ)
        expect(file_tree_differ).to receive(:to_s).and_return('diff result')
        expect { described_class.new(opts: opts).run }.to output("diff result\n").to_stdout
      end
    end

    context 'when unsynced_list_path is set' do
      it 'sends the correct args to FileTreeDiffer' do
        opts = {
          drive_creds_path: 'account-key.json',
          root_path: '/root/path',
          parent_folders: ['Documents'],
          unsynced_list_path: 'path/to/unsynced.yaml',
          summarize_printout: true,
          sync_to_local: false
        }

        allow(DriveServiceInitializer).to receive(:new).with('account-key.json').and_return(drive_service_initializer)
        allow(drive_service_initializer).to receive(:drive_service).and_return(drive_service)

        allow(LocalFileObjects).to receive(:new).with('/root/path').and_return(local_file_objects)
        allow(local_file_objects).to receive(:all_files_metadata).with(['Documents']).and_return([])

        allow(DriveApi).to receive(:new).with(drive_service).and_return(drive_api)
        allow(drive_api).to receive(:all_files_metadata).and_return([])

        unsynced_files = ['folder/file1.txt', 'folder/file2.pdf']
        expect(YAML).to receive(:load_file).with('path/to/unsynced.yaml').and_return(unsynced_files)
        expect(FileTreeDiffer).to receive(:new).with(
          local_files: [],
          drive_files: [],
          unsynced_list: unsynced_files,
          summarize_printout: true
        ).and_return(file_tree_differ)
        expect(file_tree_differ).to receive(:to_s).and_return('diff result')
        expect { described_class.new(opts: opts).run }.to output("diff result\n").to_stdout
      end
    end

    context 'when sync_to_local is false' do
      it 'prints the diff and exits without syncing' do
        opts = {
          drive_creds_path: 'account-key.json',
          root_path: '/root/path',
          parent_folders: ['Documents'],
          unsynced_list_path: nil,
          summarize_printout: true,
          sync_to_local: false
        }

        allow(DriveServiceInitializer).to receive(:new).with('account-key.json').and_return(drive_service_initializer)
        allow(drive_service_initializer).to receive(:drive_service).and_return(drive_service)

        allow(LocalFileObjects).to receive(:new).with('/root/path').and_return(local_file_objects)
        allow(local_file_objects).to receive(:all_files_metadata).with(['Documents']).and_return([])

        allow(DriveApi).to receive(:new).with(drive_service).and_return(drive_api)
        allow(drive_api).to receive(:all_files_metadata).and_return([])

        expect(FileTreeDiffer).to receive(:new).with(
          local_files: [],
          drive_files: [],
          unsynced_list: [],
          summarize_printout: true
        ).and_return(file_tree_differ)
        expect(file_tree_differ).to receive(:to_s).and_return('diff result')
        expect(drive_api).not_to receive(:download_files)
        expect { described_class.new(opts: opts).run }.to output("diff result\n").to_stdout
      end
    end

    context 'when sync_to_local is true' do
      it 'prints the diff and syncs the missing files' do
        opts = {
          drive_creds_path: 'account-key.json',
          root_path: '/root/path',
          parent_folders: ['Documents'],
          unsynced_list_path: nil,
          summarize_printout: true,
          sync_to_local: true
        }

        allow(DriveServiceInitializer).to receive(:new).with('account-key.json').and_return(drive_service_initializer)
        allow(drive_service_initializer).to receive(:drive_service).and_return(drive_service)

        allow(LocalFileObjects).to receive(:new).with('/root/path').and_return(local_file_objects)
        allow(local_file_objects).to receive(:all_files_metadata).with(['Documents']).and_return([])

        allow(DriveApi).to receive(:new).with(drive_service).and_return(drive_api)
        allow(drive_api).to receive(:all_files_metadata).and_return([])

        missing_file = Files::DriveFileMetadata.new('folder/file.txt', false, Time.now, 1)
        file_tree_differ = double('FileTreeDiffer')
        expect(FileTreeDiffer).to receive(:new).with(
          local_files: [],
          drive_files: [],
          unsynced_list: [],
          summarize_printout: true
        ).and_return(file_tree_differ)

        expect(file_tree_differ).to receive(:to_s).and_return('diff result')
        expect(file_tree_differ).to receive(:drive_only_files).and_return([missing_file])
        expect(drive_api).to receive(:download_files).with([missing_file], '/root/path')
        expect { described_class.new(opts: opts).run }.to output("diff result\n").to_stdout
      end
    end

    context 'when there is an InvalidPathError' do
      let(:opts) do
        {
          drive_creds_path: 'account-key.json',
          root_path: '/root/path',
          parent_folders: ['Documents'],
          unsynced_list_path: nil,
          summarize_printout: true,
          sync_to_local: true
        }
      end

      it 'prints the error message and exists with status 1' do
        opts = {
          drive_creds_path: 'account-key.json',
          root_path: '/root/path',
          parent_folders: ['Documents'],
          unsynced_list_path: nil,
          summarize_printout: true,
          sync_to_local: false
        }

        allow(DriveServiceInitializer).to receive(:new).with('account-key.json').and_return(drive_service_initializer)
        allow(drive_service_initializer).to receive(:drive_service).and_return(drive_service)

        allow(LocalFileObjects).to receive(:new).with('/root/path').and_return(local_file_objects)
        allow(local_file_objects).to receive(:all_files_metadata)
          .and_raise(LocalFileObjects::InvalidPathError, 'Invalid path')

        result = true
        expect { result = described_class.new(opts: opts).run }.to output("Invalid file path: Invalid path\n").to_stdout
        expect(result).to be(false)
      end
    end
  end
end
