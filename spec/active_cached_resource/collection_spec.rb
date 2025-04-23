# frozen_string_literal: true

class TestCollectionWithPersistedAttributes < ActiveCachedResource::Collection
  persisted_attribute :custom_attr, :another_attr

  def parse_response(elements)
    @elements = elements
    @custom_attr = "Foo"
    @another_attr = "Bar"
  end
end

class TestCollection < ActiveCachedResource::Collection; end

class TestResource < ActiveResource::Base
  self.site = "https://api.example.com"

  setup_cached_resource!(
    cache_store: ActiveSupport::Cache::MemoryStore.new,
    cache_strategy: :active_support_cache,
    ttl: 10.minutes,
    logger: Logger.new(IO::NULL)
  )
end

class TestResourceAttribute < ActiveResource::Base
  self.site = "https://api.example.com"
  self.collection_parser = TestCollectionWithPersistedAttributes

  setup_cached_resource!(
    cache_store: ActiveSupport::Cache::MemoryStore.new,
    cache_strategy: :active_support_cache,
    ttl: 10.minutes,
    logger: Logger.new(IO::NULL)
  )
end

# Helpers
def mock_http_get(path, response_body, status = 200)
  ActiveResource::HttpMock.respond_to do |mock|
    mock.get path, {}, response_body.to_json, status
  end
end

def fetch_and_validate_elements(expected_names)
  collection.to_a
  elements = collection.instance_variable_get(:@elements)
  expect(elements.map(&:name)).to eq(expected_names)
end

RSpec.describe ActiveCachedResource::Collection do
  it "has a version number" do
    expect(ActiveCachedResource::VERSION).not_to be nil
  end

  describe "#reload" do
    before do
      ActiveResource::HttpMock.reset!
      TestResource.clear_cache
    end

    it "fetches resources from the API even if they are cached" do
      mock_http_get("/test_resources.json", [{id: 1, name: "Reloaded Resource"}])

      collection = TestResource.all.call # First call
      collection.reload # Reload call, should fetch from API

      TestResource.all # Third call, should fetch from cache
      expect(ActiveResource::HttpMock.requests.size).to eq(2)
      expect(collection.to_a.map(&:name)).to eq(["Reloaded Resource"])
    end
  end

  describe "#request_resources!" do
    let(:collection) { TestResource.all }

    before do
      ActiveResource::HttpMock.reset!
      TestResource.clear_cache
    end

    context "when `from` is a Symbol" do
      it "calls resource_class.get with the Symbol" do
        collection.instance_variable_set(:@from, :all)
        mock_http_get("/test_resources/all.json", [{id: 1, name: "Symbol Resource"}])

        expect(TestResource).to receive(:get).with(:all, nil).and_call_original

        fetch_and_validate_elements(["Symbol Resource"])
      end
    end

    context "when `from` is a String" do
      it "calls resource_class.connection.get with the String path" do
        collection.instance_variable_set(:@from, "/custom_path")
        mock_http_get("/custom_path", [{id: 1, name: "String Resource"}])

        expect(TestResource.connection).to receive(:get).with("/custom_path", TestResource.headers).and_call_original

        fetch_and_validate_elements(["String Resource"])
      end
    end

    context "when `from` is nil" do
      it "calls resource_class.collection_path with default parameters" do
        collection.instance_variable_set(:@from, nil)
        mock_http_get("/test_resources.json", [{id: 1, name: "Default Resource"}])

        expect(TestResource).to receive(:collection_path).and_call_original

        fetch_and_validate_elements(["Default Resource"])
      end
    end

    context "when RELOAD_PARAM is passed" do
      it "removes the parameter from the HTTP request" do
        query_params = {ActiveCachedResource::Constants::RELOAD_PARAM => true, :param => "value"}
        collection.instance_variable_set(:@query_params, query_params)

        mock_http_get("/test_resources.json?param=value", [{id: 1, name: "Fetched Resource"}])
        collection.to_a

        query_params = collection.instance_variable_get(:@query_params)
        expect(query_params).not_to have_key(ActiveCachedResource::Constants::RELOAD_PARAM)
      end
    end

    context "when cache_read returns a result" do
      it "exits early without performing an HTTP call" do
        cached_result = ActiveCachedResource::Collection.new([TestResource.new(id: 1, name: "Cached Resource")])
        allow(TestResource).to receive(:cache_read).and_return(cached_result)

        expect(TestResource.connection).not_to receive(:get)

        fetch_and_validate_elements(["Cached Resource"])
      end
    end

    context "when cache_read does not return a result" do
      it "performs an HTTP call" do
        allow(TestResource).to receive(:cache_read).and_return(nil)
        mock_http_get("/test_resources.json", [{id: 1, name: "Fetched Resource"}])

        expected_request = ActiveResource::Request.new(:get, "/test_resources.json", nil, {"Accept" => "application/json"})
        collection.to_a
        expect(ActiveResource::HttpMock.requests).to include(expected_request)

        fetch_and_validate_elements(["Fetched Resource"])
      end
    end

    context "when API call is successful" do
      it "writes to the cache" do
        allow(TestResource).to receive(:cache_read).and_return(nil)
        allow(TestResource).to receive(:cache_write)
        mock_http_get("/test_resources.json", [{id: 1, name: "Fetched Resource"}])

        collection.to_a
        expect(TestResource).to have_received(:cache_write)
      end
    end

    context "when API call returns a 404" do
      it "returns an empty array" do
        mock_http_get("/test_resources.json", "", 404)

        expect(collection.to_a).to eq([])
      end
    end

    context "ensures `@requested` is set to true" do
      it "sets `@requested` to true after an error" do
        allow(TestResource.connection).to receive(:get).and_raise(ActiveResource::ConnectionError.new("Connection error"))

        expect { collection.to_a }.to raise_error(ActiveResource::ConnectionError)

        expect(collection.instance_variable_get(:@requested)).to be true
      end

      it "sets `@requested` to true after a successful call" do
        mock_http_get("/test_resources.json", [{id: 1, name: "Fetched Resource"}])

        collection.to_a
        expect(collection.instance_variable_get(:@requested)).to be true
      end
    end

    context "when collection has custom virtual attribtues" do
      it "updates the collection with the new attributes from cache" do
        mock_http_get("/test_resource_attributes.json", [{id: 1, name: "Symbol Resource"}])
        collection = TestResourceAttribute.all.call
        expect(collection.custom_attr).to eq("Foo")
        expect(collection.another_attr).to eq("Bar")

        collection = TestResourceAttribute.all.call # Second call to ensure cache is used
        expect(collection.custom_attr).to eq("Foo")
        expect(collection.another_attr).to eq("Bar")
        expect(ActiveResource::HttpMock.requests.size).to eq(1)
      end
    end
  end

  describe "#virtual_persistable_attributes" do
    let(:collection) { TestCollectionWithPersistedAttributes.new }

    it "returns a hash of virtual persisted attributes with their values" do
      collection.custom_attr = "Custom Value"
      collection.another_attr = "Another Value"

      expect(collection.virtual_persistable_attributes).to eq({
        custom_attr: "Custom Value",
        another_attr: "Another Value"
      })
    end

    it "returns an empty hash if no virtual persisted attributes are set" do
      expect(TestCollection.new.virtual_persistable_attributes).to eq({})
    end

    it "includes only the attributes defined as persisted" do
      collection.custom_attr = "Custom Value"
      collection.instance_variable_set(:@non_persisted_attr, "Non-Persisted Value")

      expect(collection.virtual_persistable_attributes).not_to have_key(:non_persisted_attr)
    end
  end
end
