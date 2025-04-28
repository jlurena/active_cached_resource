class CacheModel < ActiveRecord::Base
  self.table_name = "active_cached_resources"
end

RSpec.describe ActiveCachedResource::CachingStrategies::SQLCache do
  let(:constructor_args) { [CacheModel] }

  it_behaves_like "a caching strategy"
end
