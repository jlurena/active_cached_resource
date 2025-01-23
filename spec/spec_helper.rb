# frozen_string_literal: true

require "dotenv/load"

require "simplecov"

Dir.glob(File.join(__dir__, "support", "**", "*.rb")).each { |f| require_relative f }

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/example/"
  add_filter "/lib/active_resource/"
end
require "active_cached_resource"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
