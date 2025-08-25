require "spec_helper"
require File.expand_path("../config/environment", __dir__)
require "rspec/rails"

Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each do |f| # rubocop:disable Rails/FilePath
  require f
end

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.fixture_path = Rails.root.join("spec/fixtures")

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
end
