require "active_record"
require "sqlite3"

class CacheModel < ActiveRecord::Base
  self.table_name = "active_cached_resources"
end

RSpec.describe ActiveCachedResource::CachingStrategies::SQLCache do
  before(:context) do
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

  let(:constructor_args) { [CacheModel] }

  it_behaves_like "a caching strategy"
end
