require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsTutorial
  class Application < Rails::Application
    config.load_defaults 7.0
    config.time_zone = "Asia/Ho_Chi_Minh"
    config.i18n.default_locale = Settings.i18n.default_locale.to_sym
    config.i18n.available_locales = Settings.i18n.available_locales.map(&:to_sym)
    config.i18n.fallbacks = [Settings.i18n.fallback_locale.to_sym]
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
  end
end
