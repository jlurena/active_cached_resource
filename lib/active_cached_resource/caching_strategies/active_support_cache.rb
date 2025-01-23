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
        successful_write = @cache_store.write(key, compressed_value, options)
        update_master_key(key, options) if successful_write

        successful_write
      end

      def delete_raw(key)
        @cache_store.delete(key)
      end

      def clear_raw(prefix)
        existing_keys = @cache_store.read(prefix)
        return if existing_keys.nil?

        existing_keys.add(prefix)
        @cache_store.delete_multi(existing_keys)
      end

      private

      # Updates the `master` key, which contains keys for a given prefix.
      def update_master_key(key, options)
        prefix, _ = split_key(key)

        existing_keys = @cache_store.read(prefix) || Set.new
        existing_keys.add(key)

        # Maintain the list of keys for twice the expiration time
        @cache_store.write(prefix, existing_keys, expires_in: options[:expires_in])
      end
    end
  end
end
