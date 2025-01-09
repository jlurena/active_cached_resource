require "spec_helper"

class TestResource < ActiveResource::Base
  self.site = "https://api.example.com"
end

RSpec.describe ActiveCachedResource::Model do
  # Expects a specific number of requests to a given path.
  #
  # @param path [String] the path of the request to be expected.
  # @param count [Integer] the number of times the request is expected to be made.
  # @return [void]
  def expect_request(path, count)
    expected_request = ActiveResource::Request.new(:get, path, nil, {"Accept" => "application/json"})
    expect(ActiveResource::HttpMock.requests.count { |req| req == expected_request }).to eq(count)
  end

  describe "callbacks" do
    before do
      TestResource.setup_cached_resource!(
        cache_store: ActiveSupport::Cache::MemoryStore.new,
        cache_strategy: :active_support_cache,
        ttl: 600
      )
    end

    context "save callback" do
      let(:instance) { TestResource.new({name: "Resource 1"}) }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.post "/test_resources.json", {"Content-Type" => "application/json"}, {id: 1, name: "Resource 1"}.to_json, 201, "Location" => "/test_resource/1.json"
          mock.get "/test_resources/1.json", {}, {id: 1, name: "Resource 1"}.to_json
        end
      end

      it "invalidates cache before save and caches after POST" do
        expect(instance).to receive(:invalidate_cache).once.and_call_original
        instance.save
        expect(instance.id).to eq(1)
        expect(TestResource.find(1).name).to eq("Resource 1")
        expect_request("/test_resources/1.json", 0) # Cached after POST, so no request is made
      end
    end

    context "update callback" do
      let(:instance) { TestResource.find(1) }

      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.put "/test_resources/1.json", {"Content-Type" => "application/json"}, {}.to_json, 204
          mock.get "/test_resources/1.json", {}, {id: 1, name: "Resource 1"}.to_json
        end
      end

      it "invalidates cache before update and caches after PUT" do
        expect(instance).to receive(:invalidate_cache).once.and_call_original
        instance.name = "Updated Resource 1"
        instance.save
        expect(TestResource.find(1).name).to eq("Updated Resource 1")
        expect_request("/test_resources/1.json", 1) # Cached only on first GET
      end
    end

    context "destroy callback" do
      let(:instance) { TestResource.find(1) }
      before do
        ActiveResource::HttpMock.respond_to do |mock|
          mock.delete "/test_resources/1.json", {"Accept" => "application/json"}, nil, 200
          mock.get "/test_resources/1.json", {}, {id: 1, name: "Resource 1"}.to_json
        end
      end

      it "invalidates cache AFTER destroy and caches after POST" do
        expect(instance).to receive(:invalidate_cache).once.and_call_original
        instance.destroy # Should cache and not trigger another http request
        TestResource.find(1) # Should be deleted from cache but request still mocked
        expect_request("/test_resources/1.json", 2)
      end
    end
  end
end
