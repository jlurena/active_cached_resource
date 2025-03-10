RSpec.shared_examples "a caching strategy" do
  let(:cache_instance) { described_class.new(*constructor_args) }

  describe "#read" do
    context "when the key exists in the cache" do
      it "compresses when writing and decompresses when retrieving" do
        value = {"name" => "test"}
        key = "test#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key"

        cache_instance.write(key, value, expires_in: 3600)
        expect(cache_instance.read(key)).to eq(value)
      end
    end

    context "when the key does not exist in the cache" do
      it "returns nil" do
        expect(cache_instance.read("missing#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key")).to be_nil
      end
    end

    context "when decompression fails" do
      before do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end

      it "returns nil" do
        raw_key = cache_instance.send(:hash_key, "invalid#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key")
        cache_instance.send(:write_raw, raw_key, "invalid data", {expires_in: 3600})

        expect(cache_instance.read("invalid#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key")).to be_nil
      end
    end
  end

  describe "#write" do
    context "when expires_in option is missing" do
      it "raises an ArgumentError" do
        expect {
          cache_instance.write("test#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key", "value", {})
        }.to raise_error(ArgumentError, "`expires_in` option is required")
      end
    end

    context "when write succeeds" do
      it "stores the compressed value in the cache" do
        value = {"name" => "test"}
        key = "test#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key"
        expect(cache_instance.write(key, value, expires_in: 3600)).to be_truthy
      end
    end

    context "when write fails" do
      it "returns false" do
        allow(cache_instance).to receive(:write_raw).and_return(false)
        expect(
          cache_instance.write("test#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key", "value", expires_in: 3600)
        ).to be false
      end
    end
  end

  describe "#clear" do
    before do
      cache_instance.write("test#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key", "value", expires_in: 3600)
      cache_instance.write("another#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}key", "value", expires_in: 3600)
    end

    it "removes matching keys from the cache" do
      expect { cache_instance.clear("test") }.to_not raise_error
    end
  end
end
