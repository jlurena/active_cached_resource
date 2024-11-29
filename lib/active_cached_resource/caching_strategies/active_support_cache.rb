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
        @cache_store.write(key, compressed_value, options)
      end

      def clear_raw(pattern)
        if @cache_store.respond_to?(:delete_matched)
          @cache_store.delete_matched("#{pattern}*")
          true
        else
          false
        end
      end
    end
  end
end
