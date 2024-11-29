require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
Bundler.require(*Rails.groups)

module Consumer
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true

    config.cache_store = :file_store, Rails.root.join("tmp", "storage"), { expires_in: 1.day }
  end
end
