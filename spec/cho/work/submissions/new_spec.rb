# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work::Submission, type: :feature do
  context 'when no work type is provided' do
    it 'redirects to the home page with an error' do
      visit(new_work_path)
      expect(page).to have_content('You must specify a work type')
    end
  end

  context 'when filling in all the fields' do
    let!(:archival_collection) { create(:archival_collection, title: 'Sample Collection') }

    it 'creates a new work object without a file' do
      visit(root_path)
      click_link('Create Work')
      click_link('Generic')
      expect(page).to have_content('New Generic Work')
      fill_in('work_submission[title]', with: 'New Title')
      fill_in('work_submission[subtitle]', with: 'New subtitle')
      fill_in('work_submission[description]', with: 'Description of new generic work.')
      fill_in('work_submission[alternate_ids]', with: 'asdf_1234')
      fill_in('work_submission[generic_field]', with: 'Sample generic field value')
      fill_in('work_submission[created]', with: '2018-10-22')
      fill_in('work_submission[member_of_collection_ids]', with: archival_collection.id)
      click_button('Create Work')
      expect(page).to have_selector('h1', text: 'New Title')
      within('#document') do
        expect(page).to have_blacklight_label(:title_tesim, 'Object Title')
        expect(page).to have_blacklight_field(:title_tesim, 'New Title')
        expect(page).to have_blacklight_label(:subtitle_tesim, 'Subtitle')
        expect(page).to have_blacklight_field(:subtitle_tesim, 'New subtitle')
        expect(page).to have_blacklight_label(:description_tesim, 'Description')
        expect(page).to have_blacklight_field(:description_tesim, 'Description of new generic work')
        expect(page).to have_blacklight_label(:created_tesim, 'Created')
        expect(page).to have_blacklight_field(:created_tesim, 'datetime-2018-10-22T00:00:00.000Z')
        expect(page).to have_blacklight_label(:generic_field_tesim, 'Generic Field')
        expect(page).to have_blacklight_field(:generic_field_tesim, 'Sample generic field value')
        expect(page).to have_blacklight_label(:alternate_ids_tesim, 'Identifier')
        expect(page).to have_blacklight_field(:alternate_ids_tesim, 'id-asdf_1234')
        expect(page).to have_blacklight_label(:work_type_ssim, 'Work Type')
        expect(page).to have_blacklight_field(:work_type_ssim, 'Generic')
        expect(page).to have_blacklight_label(:member_of_collection_ids_ssim, 'Member of Collection')
        expect(page).to have_blacklight_field(:member_of_collection_ids_ssim, 'Sample Collection')
        expect(page).to have_blacklight_field(:member_of_collection_ids_ssim, archival_collection.id)
        expect(page).to have_link('Sample Collection')
      end
      expect(page).to have_link('Edit')
    end
  end

  context 'without providing a title' do
    let!(:archival_collection) { create(:archival_collection, title: 'Sample Collection') }

    it 'reports the errors' do
      visit(root_path)
      click_link('Create Work')
      click_link('Document')
      expect(page).to have_content('New Document Work')
      click_button('Create Work')
      within('.error-explanation') do
        expect(page).to have_selector('h2', text: '2 errors prohibited this work from being saved:')
        expect(page).to have_content("Title can't be blank")
        expect(page).to have_content("Member of collection ids can't be blank")
      end
      fill_in('work_submission[title]', with: 'Required Title')
      fill_in('work_submission[member_of_collection_ids]', with: archival_collection.id)
      click_button('Create Work')
      expect(page).to have_content('Required Title')
      expect(page).to have_content('Document')
      expect(page).to have_link('Edit')
    end
  end

  context 'with a non-existent work type' do
    it 'reports the error in the form' do
      visit(new_work_path(work_type_id: 'bogus-work-type-id'))
      expect(page).to have_content('Unable to find work type')
    end
  end

  context 'when attaching a file' do
    let!(:archival_collection) { create(:archival_collection, title: 'Sample Collection with Files') }

    it 'creates a new work object with a file' do
      visit(root_path)
      click_link('Create Work')
      click_link('Generic')
      expect(page).to have_content('New Generic Work')
      fill_in('work_submission[title]', with: 'New Title')
      fill_in('work_submission[member_of_collection_ids]', with: archival_collection.id)
      attach_file('File Selection', Pathname.new(fixture_path).join('hello_world.txt'))
      click_button('Create Work')
      expect(page).to have_content('New Title')
      expect(page).to have_content('Generic')
      expect(page).to have_link('Edit')
      expect(page).to have_selector('h2', text: 'Files')
      expect(page).to have_content('hello_world.txt')
    end
  end

  context 'when attaching a simple zip file to the work' do
    let!(:archival_collection) { create(:archival_collection, title: 'Collection with zipped work') }

    let(:bag) do
      ImportFactory::Bag.create(
        batch_id: 'batch1_2018-09-10',
        data: {
          work1: ['work1_preservation.tif']
        }
      )
    end

    let(:zip_file) { ImportFactory::Zip.create(bag) }

    it 'creates a new work object with files from zip' do
      visit(root_path)
      click_link('Create Work')
      click_link('Generic')
      expect(page).to have_content('New Generic Work')
      fill_in('work_submission[title]', with: 'Work with attached zip')
      fill_in('work_submission[member_of_collection_ids]', with: archival_collection.id)
      attach_file('File Selection', zip_file)
      click_button('Create Work')
      expect(page).to have_content('Work with attached zip')
      expect(page).to have_content('Generic')
      expect(page).to have_link('Edit')
      expect(page).to have_selector('h2', text: 'Files')
      expect(page).to have_content('work1_preservation.tif')
    end
  end

  context 'when attaching a zip file with file sets to the work' do
    let!(:archival_collection) { create(:archival_collection, title: 'Collection with zipped work') }

    let(:bag) do
      ImportFactory::Bag.create(
        batch_id: 'batch1_2018-09-17',
        data: {
          work1: [
            'work1_00001_01_preservation.tif',
            'work1_00001_01_preservation-redacted.tif',
            'work1_00001_01_service.jp2',
            'work1_00001_02_preservation.tif',
            'work1_00001_02_service.jp2',
            'work1_00002_01_preservation.tif',
            'work1_00002_01_service.jp2',
            'work1_00002_02_preservation.tif',
            'work1_00002_02_service.jp2',
            'work1_service.pdf',
            'work1_text.txt',
            'work1_thumb.jpg'
          ]
        }
      )
    end

    let(:zip_file) { ImportFactory::Zip.create(bag) }

    it 'creates a new work object with file sets, files, and a thumbnail from the zip' do
      visit(root_path)
      click_link('Create Work')
      click_link('Generic')
      expect(page).to have_content('New Generic Work')
      fill_in('work_submission[title]', with: 'Work and file sets with attached zip')
      fill_in('work_submission[member_of_collection_ids]', with: archival_collection.id)
      attach_file('File Selection', zip_file)
      click_button('Create Work')
      expect(page).to have_content('Work and file sets with attached zip')
      expect(page).to have_content('Generic')
      expect(page).to have_xpath("//img[@src='/files/work1_thumb.jpg']")
      expect(page).to have_xpath("//img[@alt='Work1 thumb']")
      expect(page).to have_link('Edit')
      expect(page).to have_selector('h2', text: 'Files')
      expect(page).to have_content('work1_00001_01_preservation.tif')
      expect(page).to have_content('work1_00001_02_preservation.tif')
      expect(page).to have_content('work1_00002_01_preservation.tif')
      expect(page).to have_content('work1_00002_02_preservation.tif')

      # Check thumbnail display on the file set
      click_link('work1_service.pdf')
      expect(page).to have_selector('h1', text: 'work1_service.pdf')
      expect(page).to have_xpath("//img[@src='/files/work1_thumb.jpg']")
      expect(page).to have_xpath("//img[@alt='Work1 thumb']")
    end
  end
end
