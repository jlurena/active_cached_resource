require_relative "base"

module ActiveCachedResource
  module CachingStrategies
    class ActiveSupportCache < Base
      def initialize(cache_store)
        super()
        @cache_store = cache_store
      end

      protected

      def read_raw(key)
        @cache_store.read(key)
      end

      def write_raw(key, compressed_value, options)
        upsert_written_keys(key, options)
        @cache_store.write(key, compressed_value, options)
      end

      def delete_raw(key)
        @cache_store.delete(key)
      end

      def clear_raw(prefix)
        existing_keys = @cache_store.read(prefix)
        existing_keys&.each do |key|
          @cache_store.delete(key)
        end

        @cache_store.delete(prefix)
      end

      def upsert_written_keys(key, options)
        prefix, _ = split_key(key)

        existing_keys = @cache_store.read(prefix) || Set.new
        existing_keys.add(key)

        # Maintain the list of keys for twice the expiration time
        @cache_store.write(prefix, existing_keys, expires_in: options[:expires_in] * 2)
      end
    end
  end
end
