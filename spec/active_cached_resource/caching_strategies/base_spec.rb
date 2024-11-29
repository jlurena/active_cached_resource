RSpec.describe ActiveCachedResource::CachingStrategies::Base do
  let(:caching_strategy) { described_class.new }
  let(:key) { "test-key" }
  let(:value) { "test-value" }
  let(:options) { {expires_in: 60} }

  describe "#read" do
    it "will raise a NotImplementedError" do
      expect {
        caching_strategy.read("prefix-key")
      }.to raise_error(NotImplementedError, /must implement `read_raw`/)
    end
  end

  describe "#write" do
    it "will raise a NotImplementedError" do
      expect {
        caching_strategy.write("prefix-key", "", {expires_in: 3600})
      }.to raise_error(NotImplementedError, /must implement `write_raw`/)
    end
  end

  describe "#clear" do
    it "will raise a NotImplementedError" do
      expect { caching_strategy.clear("") }.to raise_error(NotImplementedError, /must implement `clear_raw`/)
    end
  end

  describe "#hash_key" do
    it "generates a hashed key with a prefix and SHA256 digest" do
      key = "prefix-mykey"
      hashed_key = caching_strategy.send(:hash_key, key)

      prefix, digest = hashed_key.split("/")
      expect(prefix).to eq("prefix")
      expect(digest).to eq(Digest::SHA256.hexdigest("mykey"))
    end

    it "handles keys with multiple dashes" do
      key = "prefix-part1-part2"
      hashed_key = caching_strategy.send(:hash_key, key)

      prefix, digest = hashed_key.split("/")
      expect(prefix).to eq("prefix")
      expect(digest).to eq(Digest::SHA256.hexdigest("part1-part2"))
    end

    context "Invalid keys" do
      it "handles keys without a prefix gracefully" do
        key = "mykey"

        expect {
          caching_strategy.send(:hash_key, key)
        }.to raise_error(ArgumentError, "Key must have a prefix and a key separated by a dash")
      end

      it "raises error on an empty key" do
        key = ""
        expect {
          caching_strategy.send(:hash_key, key)
        }.to raise_error(ArgumentError, "Key must have a prefix and a key separated by a dash")
      end
    end
  end

  describe "#compress" do
    it "compresses the value using MessagePack" do
      compressed_value = caching_strategy.send(:compress, value)
      expect(compressed_value).to eq(MessagePack.pack(value))
    end
  end

  describe "#decompress" do
    it "decompresses the value using MessagePack" do
      compressed_value = MessagePack.pack(value)
      decompressed_value = caching_strategy.send(:decompress, compressed_value)
      expect(decompressed_value).to eq(value)
    end

    context "When unpacking fails" do
      before do
        allow(MessagePack).to receive(:unpack).with("invalid").and_raise(MessagePack::UnpackError)
      end
      it "returns nil if decompression fails" do
        expect(caching_strategy.send(:decompress, "invalid")).to be_nil
      end
    end
  end
end
