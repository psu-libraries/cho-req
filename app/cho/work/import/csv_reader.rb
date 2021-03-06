# frozen_string_literal: true

module Work
  module Import
    class CsvReader < Csv::Reader
      include ::CsvParsing

      delegate :each, :map, to: :work_hashes

      def work_hashes
        csv_hashes.reject { |hash| hash.fetch('home_collection_id').nil? }
      end

      def file_set_hashes
        csv_hashes.select { |hash| hash.fetch('home_collection_id').nil? }
      end
    end
  end
end
