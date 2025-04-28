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
require "active_record"
require "sqlite3"

ActiveRecord::Schema.verbose = false

RSpec.configure do |config|
  include ActiveSupport::LoggerSilence
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    ActiveSupport::LoggerSilence.silence do
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

      ActiveRecord::Schema.define do
        create_table :active_cached_resources, force: true do |t|
          t.string :key, null: false
          t.binary :value, null: false
          t.datetime :expires_at, null: false

          t.index [:key, :expires_at], unique: true, name: "index_active_cached_resources_on_key_and_expires_at"
        end
      end
    end
  end
end
