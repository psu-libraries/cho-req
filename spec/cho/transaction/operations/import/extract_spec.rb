# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transaction::Operations::Import::Extract do
  let(:operation) { described_class.new }

  describe '#call' do
    context 'with the name of the zip file' do
      let(:bag_path) { Pathname.new(ENV['extraction_directory']).expand_path.join('sample_zip') }

      before do
        FileUtils.rm_rf(bag_path)
        @network_ingest_directory = ENV['network_ingest_directory']
        ENV['network_ingest_directory'] = fixture_path
      end

      after do
        ENV['network_ingest_directory'] = @network_ingest_directory
      end

      it 'successfully extracts the zip' do
        result = operation.call(zip_name: 'sample_zip')
        expect(result).to be_success
        expect(result.success).to eq(bag_path)
        expect(bag_path).to be_directory
        expect(bag_path.join('data')).to be_directory
        expect(bag_path.join('data', 'sample_object.txt')).to be_file
        expect(bag_path.join('sample_file.txt')).to be_file
      end
    end

    context 'with a full path to the zip file' do
      let(:bag_path) { Pathname.new(ENV['extraction_directory']).expand_path.join('sample_zip') }
      let(:zip_path) { Pathname.new(fixture_path).join('sample_zip.zip') }

      before { FileUtils.rm_rf(bag_path) }

      it 'successfully extracts the zip' do
        result = operation.call(zip_path: zip_path)
        expect(result).to be_success
        expect(result.success).to eq(bag_path)
        expect(bag_path).to be_directory
        expect(bag_path.join('data')).to be_directory
        expect(bag_path.join('data', 'sample_object.txt')).to be_file
        expect(bag_path.join('sample_file.txt')).to be_file
      end
    end

    context 'when the zip cannot be extracted' do
      let(:path) { Rails.root.join('tmp', 'ingest-test', 'non-existent zip.zip') }

      it 'returns Failure' do
        result = operation.call(zip_name: 'non-existent zip')
        expect(result).to be_failure
        expect(result.failure).to eq(
          "Error extracting the bag: No such file or directory @ rb_sysopen - #{path}"
        )
      end
    end
  end
end
