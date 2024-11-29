RSpec.describe ActiveCachedResource::CachingStrategies::ActiveSupportCache do
  let(:constructor_args) { [ActiveSupport::Cache::MemoryStore.new] }

  it_behaves_like "a caching strategy"

  context "When the cache does not support the `delete_matched` method" do
    let(:cache_store) { double("cache_store") }
    let(:cache_instance) { described_class.new(cache_store) }

    it "always returns false for clear" do
      expect(cache_instance.clear("pattern")).to be false
      expect(cache_instance.clear("bar")).to be false
    end
  end
end
