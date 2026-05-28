require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"

Bundler.require(*Rails.groups)

module BolaoAds
  class Application < Rails::Application
    config.load_defaults 8.0
    config.time_zone = "America/Bahia"
    config.active_record.default_timezone = :utc
    config.i18n.default_locale = :"pt-BR"
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
