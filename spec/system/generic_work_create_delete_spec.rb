# frozen_string_literal: true

# # Comment this method out to see screenshots on failures in tmp/screenshots
# def take_failed_screenshot
#   false
# end

def create_generic_work(title, creator, file)
  visit new_hyrax_generic_work_path
  expect(page).to have_content('Add New Generic Work')

  fill_in 'Title', with: title
  fill_in 'Creator', with: creator
  fill_in 'Keyword', with: 'keyword'
  select 'Rights', from: 'Rights statement'

  click_on 'Files'
  within '#addfiles' do
    attach_file('files[]', File.absolute_path('./spec/fixtures/' + file), multiple: true, make_visible: true)
  end

  choose 'generic_work_visibility_open'
  check 'I have read'
  click_on 'Save'
  expect(page).to have_content 'Your files are being processed by Hyrax in the background.'
end

def delete_generic_work(generic_work)
  visit hyrax_generic_work_path(generic_work)
  expect(page).to have_content(generic_work.title.first)

  click_on 'Delete'
  page.driver.browser.switch_to.alert.accept

  expect(page).to have_content "Deleted #{generic_work.title.first}"
end

RSpec.describe "Generic Work Create Delete", type: :system do
  let(:user) { create(:user) }

  before do
    ActiveFedora::Cleaner.clean!
  end

  it "creates and deletes a generic work" do
    expect(ActiveFedora::Base.count).to be_zero

    signup('user@exmaple.com', 'password')
    expect(ActiveFedora::Base.count).to be_zero

    create_generic_work('One', 'Creator', 'image.jpg')
    puts "One Created"
    ActiveFedora::Base.all.each do |thing|
      puts thing.inspect
    end
    expect(ActiveFedora::Base.count).to eq(8)
    puts ''

    create_generic_work('Two', 'Creator', 'image.jpg')
    puts "Two Created"
    ActiveFedora::Base.all.each do |thing|
      puts thing.inspect
    end
    expect(ActiveFedora::Base.count).to eq(13)
    puts ''

    GenericWork.all.each do |generic_work|
      puts "#{generic_work.title.first} Deleted"
      delete_generic_work(generic_work)
      ActiveFedora::Base.all.each do |thing|
        puts thing.inspect
      end
      puts ''
    end

    ActiveFedora::Base.all.each do |thing|
      puts thing.inspect
    end
    expect(ActiveFedora::Base.count).to eq(3) # AdminSet, AccessControl, and Permission
  end
end
