# frozen_string_literal: true

module Transaction
  module Operations
    module File
      class Save
        include Dry::Transaction::Operation

        # @note If the change_set does not support files, it returns Success so that any other
        #   workflow steps may proceed.
        def call(change_set)
          return Success(change_set) unless change_set.respond_to?(:file) && change_set.file.present?
          saved_work_file_set = metadata_adapter.persister.save(resource: work_file_set(change_set))
          change_set.model.file_set_ids << saved_work_file_set.id
          Success(change_set)
        rescue StandardError => e
          Failure("Error persisting file: #{e.message}")
        end

        private

          def work_file_set(change_set)
            file = work_file(change_set)
            Work::FileSet.new(member_ids: [file.id], title: change_set.file.original_filename)
          end

          def work_file(change_set)
            file = Work::File.new(original_filename: change_set.file.original_filename)
            file_change_set = Work::FileChangeSet.new(file)
            response = Create.new.call(file_change_set, temp_file: change_set.file.tempfile)
            raise response.failure if response.failure?
            response.success.model
          end

          def metadata_adapter
            @metadata_adapter ||= Valkyrie::MetadataAdapter.find(:indexing_persister)
          end
      end
    end
  end
end
