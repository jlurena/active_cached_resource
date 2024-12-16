RSpec.describe ActiveCachedResource::Configuration do
  let(:model) { double("Model", name: "TestResource") }
  let(:cache_store) { double("CacheStore") }
  let(:logger) { instance_double(ActiveCachedResource::Logger) }

  before do
    allow(ActiveCachedResource::Logger).to receive(:new).with("TestResource").and_return(logger)
  end

  describe "#initialize" do
    context "with a valid cache_store and cache_strategy" do
      it "initializes with the specified caching strategy" do
        config = described_class.new(model, cache_store: cache_store, cache_strategy: :active_support)

        expect(config.cache).to be_a(ActiveCachedResource::CachingStrategies::ActiveSupportCache)
        expect(config.cache.instance_variable_get(:@cache_store)).to eq(cache_store)
        expect(config.cache_key_prefix).to eq("test_resource")
        expect(config.logger).to eq(logger)
        expect(config.enabled).to be true
        expect(config.ttl).to eq(86400)
      end
    end

    context "with a custom cache_store inheriting from Base" do
      let(:custom_cache) { Class.new(ActiveCachedResource::CachingStrategies::Base).new }

      it "uses the custom cache store directly" do
        config = described_class.new(model, cache_store: custom_cache)

        expect(config.cache).to eq(custom_cache)
      end
    end

    context "with an invalid cache_store and cache_strategy" do
      it "raises an ArgumentError when neither cache_store nor cache_strategy is provided" do
        expect { described_class.new(model) }.to raise_error(ArgumentError, "cache_store must be a CachingStrategies::Base or cache_strategy must be provided")
      end

      it "raises an ArgumentError for an invalid cache_strategy" do
        expect {
          described_class.new(model, cache_store: cache_store, cache_strategy: :invalid_strategy)
        }.to raise_error(ArgumentError, "Invalid cache strategy: invalid_strategy")
      end
    end

    context "with custom options" do
      it "overrides default options with provided values" do
        config = described_class.new(
          model,
          cache_store: cache_store,
          cache_strategy: :active_support,
          cache_key_prefix: "custom_prefix",
          enabled: false,
          ttl: 3600
        )

        expect(config.cache_key_prefix).to eq("custom_prefix")
        expect(config.enabled).to be false
        expect(config.ttl).to eq(3600)
      end
    end
  end

  describe "#on!" do
    it "enables caching" do
      config = described_class.new(model, cache_store: cache_store, cache_strategy: :active_support)
      config.off!

      expect(config.enabled).to be false

      config.on!
      expect(config.enabled).to be true
    end
  end

  describe "#off!" do
    it "disables caching" do
      config = described_class.new(model, cache_store: cache_store, cache_strategy: :active_support)

      config.off!
      expect(config.enabled).to be false
    end
  end
end
