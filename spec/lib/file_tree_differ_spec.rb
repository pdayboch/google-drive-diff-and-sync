require 'spec_helper'
require './lib/file_tree_differ'

RSpec.describe FileTreeDiffer do
  describe "#get_diffs" do
    context "without unsynced list" do
      context "missing only files" do
        context "missing local only" do
          it "returns correct diffs" do
            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: []
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }
            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              []
            ).get_diffs

            expect(diffs[:missing_local])
              .to include("docs/foo/bar.pdf")
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end

        context "missing drive only" do
          it "returns correct diffs" do
            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: []
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              []
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to include("docs/foo/bar.pdf")
          end
        end

        context "missing drive and local" do
          it "returns correct diffs" do
            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/biz.pdf"]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              []
            ).get_diffs

            expect(diffs[:missing_local])
              .to include("docs/foo/biz.pdf")
            expect(diffs[:missing_drive])
              .to include("docs/foo/bar.pdf")
          end
        end

        context "when file is google doc and converted locally" do
          it "does not return the file as missing" do
            google_doc_file = "docs/foo/google_doc"
            local_file = "#{google_doc_file}.docx"

            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: [local_file]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: [google_doc_file]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              []
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end
      end

      context "missing folders and files" do
        context "missing local only" do
          it "returns the directory only" do
            local_objects = {
              folders: ["docs/"],
              files: []
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              []
            ).get_diffs

            expect(diffs[:missing_local])
              .to include("docs/foo/")
            expect(diffs[:missing_local])
              .not_to include("docs/foo/bar.pdf")
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end

        context "missing drive only" do
          it "returns the directory only" do
            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }
            drive_objects = {
              folders: ["docs/"],
              files: []
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              []
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to include("docs/foo/")
            expect(diffs[:missing_drive])
              .not_to include("docs/foo/bar.pdf")
          end
        end

        context "missing drive and local" do
          it "returns the directory only" do
            local_objects = {
              folders: ["docs/", "docs/biz/"],
              files: ["docs/biz/baz.pdf"]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              []
            ).get_diffs

            expect(diffs[:missing_local])
              .to include("docs/foo/")
            expect(diffs[:missing_local])
              .not_to include("docs/foo/bar.pdf")
            expect(diffs[:missing_drive])
              .to include("docs/biz/")
            expect(diffs[:missing_drive])
              .not_to include("docs/biz/baz.pdf")
          end
        end
      end
    end

    context "with unsynced list" do
      context "missing only files" do
        context "missing local only" do
          it "returns correct diffs" do
            unsynced_file = "docs/foo/dont_sync.jpg"

            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: []
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf", unsynced_file]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              [unsynced_file]
            ).get_diffs

            expect(diffs[:missing_local])
              .to include("docs/foo/bar.pdf")
            expect(diffs[:missing_local])
              .not_to include(unsynced_file)
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end

        context "missing drive only" do
          it "returns correct diffs" do
            unsynced_file = "docs/foo/dont_sync.jpg"

            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf", unsynced_file]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: []
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              [unsynced_file]
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to include("docs/foo/bar.pdf")
            expect(diffs[:missing_drive])
              .not_to include(unsynced_file)
          end
        end

        context "missing drive and local" do
          it "returns correct diffs" do
            unsynced_local_file = "docs/foo/local_dont_sync.jpg"
            unsynced_drive_file = "docs/foo/drive_dont_sync.jpg"

            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf", unsynced_local_file]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/biz.pdf", unsynced_drive_file]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              [unsynced_drive_file, unsynced_local_file]
            ).get_diffs

            expect(diffs[:missing_local])
              .to include("docs/foo/biz.pdf")
            expect(diffs[:missing_local])
              .not_to include(unsynced_drive_file)
            expect(diffs[:missing_drive])
              .to include("docs/foo/bar.pdf")
            expect(diffs[:missing_drive])
              .not_to include(unsynced_local_file)
          end
        end

        context "when file is google doc and converted locally" do
          it "does not return the file as missing" do
            unsynced_drive_file = "docs/foo/google_doc"
            google_doc_file = "docs/foo/google_doc"
            local_file = "#{google_doc_file}.docx"

            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: [local_file]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: [google_doc_file]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              [unsynced_drive_file]
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end
      end

      context "missing folders and files" do
        context "missing local only" do
          it "returns the directory only" do
            unsynced_folder = "docs/dont_sync/"
            unsynced_file_in_folder = "docs/dont_sync/file.txt"
            drive_objects = {
              folders: ["docs/", "docs/foo/", unsynced_folder],
              files: ["docs/foo/bar.pdf", unsynced_file_in_folder]
            }
            local_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              [unsynced_folder]
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end

        context "missing drive only" do
          it "returns the directory only" do
            unsynced_folder = "docs/dont_sync/"
            unsynced_file_in_folder = "docs/dont_sync/file.txt"
            drive_objects = {
              folders: ["docs/", "docs/foo/"],
              files: ["docs/foo/bar.pdf"]
            }
            local_objects = {
              folders: ["docs/", "docs/foo/", unsynced_folder],
              files: ["docs/foo/bar.pdf", unsynced_file_in_folder]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              [unsynced_folder]
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end

        context "missing drive and local" do
          it "returns correct diffs" do
            unsynced_drive_folder = "docs/dont_sync_drive/"
            unsynced_drive_file = "docs/dont_sync_drive/drive.txt"
            unsynced_local_folder = "docs/dont_sync_local/"
            unsynced_local_file = "docs/dont_sync_local/local.txt"

            local_objects = {
              folders: ["docs/", "docs/foo/", unsynced_local_folder],
              files: ["docs/foo/bar.pdf", unsynced_local_file]
            }
            drive_objects = {
              folders: ["docs/", "docs/foo/", unsynced_drive_folder],
              files: ["docs/foo/bar.pdf", unsynced_drive_file]
            }

            diffs = FileTreeDiffer.new(
              local_objects,
              drive_objects,
              [unsynced_drive_folder, unsynced_local_folder]
            ).get_diffs

            expect(diffs[:missing_local])
              .to be_empty
            expect(diffs[:missing_drive])
              .to be_empty
          end
        end
      end
    end
  end
end
