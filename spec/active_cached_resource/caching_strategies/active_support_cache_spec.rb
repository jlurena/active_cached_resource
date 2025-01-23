RSpec.describe ActiveCachedResource::CachingStrategies::ActiveSupportCache do
  let(:constructor_args) { [ActiveSupport::Cache::MemoryStore.new] }

  it_behaves_like "a caching strategy"
end
