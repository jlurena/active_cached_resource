# frozen_string_literal: true

class TestResource < ActiveResource::Base
  self.site = "https://api.example.com"

  setup_cached_resource!(
    cache_store: ActiveSupport::Cache::MemoryStore.new,
    cache_strategy: :active_support_cache,
    ttl: 10.minutes,
    logger: Logger.new(IO::NULL)
  )
end

RSpec.describe ActiveCachedResource::Collection do
  it "has a version number" do
    expect(ActiveCachedResource::VERSION).be nil
  end

  describe "#request_resources!" do
    let(:collection) { TestResource.all }

    before do
      ActiveResource::HttpMock.reset!
      TestResource.clear
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
        query_params = {ActiveCachedResource::Caching::RELOAD_PARAM => true, :param => "value"}
        collection.instance_variable_set(:@query_params, query_params)

        mock_http_get("/test_resources.json?param=value", [{id: 1, name: "Fetched Resource"}])
        collection.to_a

        query_params = collection.instance_variable_get(:@query_params)
        expect(query_params).not_to have_key(ActiveCachedResource::Caching::RELOAD_PARAM)
      end
    end

    context "when cache_read returns a result" do
      it "exits early without performing an HTTP call" do
        cached_result = [TestResource.new(id: 1, name: "Cached Resource")]
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
  end
end
