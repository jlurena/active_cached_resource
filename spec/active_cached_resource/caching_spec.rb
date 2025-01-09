require "active_record"
require "sqlite3"
require "spec_helper"

class TestResource < ActiveResource::Base
  self.site = "https://api.example.com"
end

class CacheModel < ActiveRecord::Base
  self.table_name = "active_cached_resources"
end

RSpec.describe ActiveCachedResource::Caching do
  let(:cache_store) { ActiveSupport::Cache::MemoryStore.new }
  let(:logger) { Logger.new(IO::NULL) }
  let(:custom_cache) do
    Class.new(ActiveCachedResource::CachingStrategies::Base) do
      attr_reader :store
      def initialize
        @store = {}
      end

      def read_raw(key)
        @store[key]
      end

      def write_raw(key, value, options)
        @store[key] = value
        true
      rescue
        false
      end

      def clear_raw(pattern)
        @store.delete_if { |k, _| k.match?(/^#{pattern}/) }
        true
      rescue
        false
      end
    end.new
  end

  let(:mock_single_resource) do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/test_resources/1.json", {}, {id: 1, name: "Resource 1"}.to_json
      mock.get "/test_resources/2.json", {}, {id: 1, name: "Resource 2"}.to_json
    end
  end

  let(:mock_collection) do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/test_resources.json", {}, [{id: 1, name: "Resource 1"}, {id: 2, name: "Resource 2"}].to_json
    end
  end

  before do
    TestResource.setup_cached_resource!(
      cache_store: cache_store,
      cache_strategy: :active_support_cache,
      logger: logger,
      ttl: 10.minutes
    )
  end

  # Expects a specific number of requests to a given path.
  #
  # @param path [String] the path of the request to be expected.
  # @param count [Integer] the number of times the request is expected to be made.
  # @return [void]
  def expect_request(path, count)
    expected_request = ActiveResource::Request.new(:get, path, nil, {"Accept" => "application/json"})
    expect(ActiveResource::HttpMock.requests.count { |req| req == expected_request }).to eq(count)
  end

  shared_examples "cache read failure" do
    before do
      allow(cache_store).to receive(:read).and_raise(StandardError, "Cache read failed")
      allow(logger).to receive(:error)
    end

    it "logs an error and does not raise an exception" do
      expect(logger).to receive(:error).with(/Failed to read from cache: Cache read failed/)
      expect { TestResource.find(1) }.not_to raise_error
    end
  end

  shared_examples "cache write failure" do
    before do
      allow(cache_store).to receive(:write).and_raise(StandardError, "Cache write failed")
      allow(logger).to receive(:error)
    end

    it "logs an error and does not raise an exception" do
      expect(logger).to receive(:error).with(/Failed to write to cache: Cache write failed/)
      expect { TestResource.find(1) }.not_to raise_error
    end
  end

  describe "#clear" do
    before { mock_single_resource }

    it "clears the cache" do
      TestResource.find(1) # Cache the resource
      expect_request("/test_resources/1.json", 1)

      TestResource.clear_cache
      TestResource.find(1) # Cache cleared, fetch again
      expect_request("/test_resources/1.json", 2)
    end

    context "with a cache key pattern" do
      it "clears the cache for matching keys" do
        TestResource.find(1) # Cache the resource
        expect_request("/test_resources/1.json", 1)

        TestResource.find(2) # Cache the resource
        expect_request("/test_resources/2.json", 1)

        TestResource.clear_cache("1*")

        TestResource.find(1) # Cache cleared, fetch again
        expect_request("/test_resources/1.json", 2)
        expect_request("/test_resources/2.json", 1)
      end
    end
  end

  describe "#find_with_cache" do
    context "when caching single resources" do
      before { mock_single_resource }

      context "without reload" do
        it "uses the cache for subsequent requests" do
          TestResource.find(1) # First request
          expect_request("/test_resources/1.json", 1)

          TestResource.find(1) # Cached
          expect_request("/test_resources/1.json", 1)
        end
      end

      context "with reload" do
        it "bypasses cache" do
          TestResource.find(1) # First request
          TestResource.find(1, reload: true) # Reload request
          expect_request("/test_resources/1.json", 2)
        end
      end
    end

    context "when caching collections" do
      before { mock_collection }

      context "without reload" do
        it "uses the cache for subsequent requests" do
          TestResource.all.to_a # First request
          expect_request("/test_resources.json", 1)

          TestResource.all.to_a # Cached
          expect_request("/test_resources.json", 1)
        end
      end

      context "with reload" do
        it "bypasses cache" do
          TestResource.all.to_a # First request
          TestResource.all(reload: true).to_a # Reload request
          expect_request("/test_resources.json", 2)
        end
      end
    end
  end

  describe "custom caching strategies" do
    before do
      TestResource.setup_cached_resource!(
        cache_store: custom_cache,
        cache_strategy: nil,
        ttl: 10.minutes,
        logger: logger
      )
      mock_single_resource
    end

    before do
      allow(custom_cache).to receive(:read_raw).and_call_original
      allow(custom_cache).to receive(:write_raw).and_call_original
      allow(custom_cache).to receive(:clear_raw).and_call_original
    end

    it "supports custom caching strategies" do
      expect(custom_cache).to receive(:read_raw).thrice
      expect(custom_cache).to receive(:write_raw).twice
      expect(custom_cache).to receive(:clear_raw).once
      TestResource.find(1) # First request
      expect_request("/test_resources/1.json", 1)

      TestResource.find(1) # Cached
      expect_request("/test_resources/1.json", 1)

      TestResource.clear_cache
      TestResource.find(1) # Cache cleared, fetch again
      expect_request("/test_resources/1.json", 2)
    end
  end

  describe "cache_key_prefix with callable proc" do
    let(:prefix_proc) { -> { "dynamic_prefix" } }

    before do
      TestResource.setup_cached_resource!(
        cache_store: custom_cache,
        cache_key_prefix: prefix_proc,
        ttl: 10.minutes,
        logger: logger
      )
      mock_single_resource
    end

    it "uses the callable proc to generate cache key prefix" do
      TestResource.find(1) # Cache the resource
      hashed_key = custom_cache.send(:hash_key, "acr/dynamic_prefix-testresource/1")
      expect(custom_cache.store.key?(hashed_key)).to be true
    end

    context "callable returns nil" do
      before do
        TestResource.setup_cached_resource!(
          cache_store: custom_cache,
          cache_key_prefix: -> {},
          ttl: 10.minutes,
          logger: logger
        )
      end

      it "raises an error" do
        expect { TestResource.find(1) }.to raise_error(ArgumentError, "cache_key_prefix must return a non-empty String")
      end
    end
  end

  describe "error handling" do
    context "cache read failure" do
      it_behaves_like "cache read failure"
    end

    context "cache write failure" do
      it_behaves_like "cache write failure"
    end
  end

  describe "SQLCache" do
    before(:context) do
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

      ActiveRecord::Schema.define do
        create_table :active_cached_resources, force: true do |t|
          t.binary :key, limit: 512, null: false
          t.binary :value, null: false
          t.datetime :expires_at, null: false

          t.index [:key, :expires_at], unique: true, name: "index_active_cached_resources_on_key_and_expires_at"
        end
      end
    end

    before do
      TestResource.setup_cached_resource!(
        cache_store: CacheModel,
        cache_strategy: :active_record_sql,
        ttl: 10.minutes,
        logger: logger
      )
    end

    context "Caching" do
      after { TestResource.clear_cache }
      context "single resource" do
        before do
          mock_single_resource
        end

        it "caches using ActiveRecord" do
          TestResource.find(1) # First request
          expect_request("/test_resources/1.json", 1)

          TestResource.find(1) # Cached
          expect_request("/test_resources/1.json", 1)
        end
      end

      context "collection" do
        before do
          mock_collection
        end

        it "caches using ActiveRecord" do
          TestResource.all.to_a # First collection request
          expect_request("/test_resources.json", 1)

          TestResource.all.to_a # Cached collection
          expect_request("/test_resources.json", 1)
        end
      end
    end

    context "clear_cache" do
      before do
        mock_single_resource
      end

      it "clears the cache" do
        TestResource.find(1) # Cache the resource
        expect_request("/test_resources/1.json", 1)

        TestResource.clear_cache
        TestResource.find(1) # Cache cleared, fetch again
        expect_request("/test_resources/1.json", 2)
      end
    end
  end
end
