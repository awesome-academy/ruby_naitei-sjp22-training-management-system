require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "faker"
require "shoulda/matchers"
require "devise"
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  config.before(:each) do
    Rails.application.routes.default_url_options[:host] = 'test.host'
    Rails.application.routes.default_url_options[:locale] = 'vi'
  end
  config.include FactoryBot::Syntax::Methods
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ActiveSupport::Testing::TimeHelpers
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    ActiveStorage::Attachment.delete_all
    ActiveStorage::Blob.delete_all
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :truncation 
  end

  config.after(:suite) do
    FileUtils.rm_rf(Dir["#{Rails.root}/tmp/storage"])
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
