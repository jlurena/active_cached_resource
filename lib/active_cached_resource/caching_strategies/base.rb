module ActiveCachedResource
  module CachingStrategies
    class Base
      # Reads the value associated with the given key from the cache.
      #
      # @param key [String, Symbol] the key to read from the cache.
      #
      # @return [Object, nil] the decompressed value associated with the key, or nil if the key is not found.
      def read(key)
        raise ArgumentError, "key must be a String or Symbol" unless key.is_a?(String) || key.is_a?(Symbol)
        raw_value = read_raw(hash_key(key))
        raw_value && decompress(raw_value)
      end

      # Writes an object to the cache with the specified key and options.
      #
      # @param key [String, Symbol] The key used to store the object in the cache.
      # @param value [String] The value to be stored in the cache.
      # @param options [Hash] Options for the cache write operation. Must include `:expires_in`.
      # @option options [Integer] :expires_in The expiration time in seconds for the cached object. (required)
      #
      # @raise [ArgumentError] If the `:expires_in` option is missing.
      #
      # @return [Boolean] `true` if the object was successfully written to the cache, `false` otherwise.
      def write(key, value, options)
        raise ArgumentError, "`expires_in` option is required" unless options[:expires_in]

        write_raw(hash_key(key), compress(value), options)
      end

      # Deletes the cached value associated with the given key.
      #
      # @param key [Object] the key whose associated cached value is to be deleted.
      # @return [void]
      def delete(key)
        delete_raw(hash_key(key))
      end

      # Clears the cache based on the given pattern.
      #
      # @param pattern [String] the pattern to match cache keys that need to be cleared.
      #
      # @return [Boolean] `true` if the cache was successfully cleared, `false` otherwise.
      def clear(pattern)
        clear_raw(pattern)
      end

      protected

      # Reads the value associated with the given key from the cache.
      #
      # @param key [Object] the key to read from the cache.
      #
      # @note This method must be implemented by the subclass.
      #
      # @return [Object, nil] the decompressed value associated with the key, or nil if the key is not found.
      def read_raw(key)
        raise NotImplementedError, "#{self.class} must implement `read_raw`"
      end

      # Writes an object to the cache with the specified key and options.
      #
      # @param key [String, Symbol] The key used to store the object in the cache.
      # @param value [String] The value to be stored in the cache.
      # @param options [Hash] Options for the cache write operation. Must include `:expires_in`.
      # @option options [Integer] :expires_in The expiration time in seconds for the cached object. (required)
      #
      # @note This method must be implemented by the subclass.
      #
      # @return [Boolean] `true` if the object was successfully written to the cache, `false` otherwise.
      def write_raw(key, value, options)
        raise NotImplementedError, "#{self.class} must implement `write_raw`"
      end

      # Clears cache entry for the given pattern.
      #
      # @param pattern [String, nil] The pattern representing the cache entry to be cleared.
      #
      # @note This method must be implemented by the subclass.
      #
      # @return [Boolean] `true` if the cache was successfully cleared, `false` otherwise.
      def clear_raw(pattern)
        raise NotImplementedError, "#{self.class} must implement `clear_raw`"
      end

      protected

      # Splits the provided key into a prefix and the remaining part
      #
      # @param key [String] the key to be split
      #
      # @example Splitting a key
      #  split_key("prefix-key") #=> "acr/prefix/keyvalue"
      #
      # @return [Array<String>] an array containing two elements: the part before the first "-", and the rest of the string
      def split_key(key)
        # Prefix of keys are expected to be the first part of key separated by a dash.
        prefix, k = key.split(ActiveCachedResource::Constants::PREFIX_SEPARATOR, 2)
        [prefix, k]
      end

      private

      # Generates a hashed key for caching purposes.
      #
      # The method splits the provided key into a prefix and the remaining part,
      # then combines the prefix with a SHA256 hash of the remaining part.
      # The resulting key is prefixed with a global prefix defined in the
      # ActiveCachedResource::Caching module.
      #
      # @example Hashing a key
      #  hash_key("prefix-key") #=> "acr/prefix/Digest::SHA256.hexdigest(key)"
      #
      # @raise [ArgumentError] If the key does not contain a prefix and a key separated by a dash.
      #
      # @param key [String] the original key to be hashed. It is expected to have a prefix and the key separated by a dash.
      # @return [String] the generated hashed key with the global prefix and the prefix from the original key.
      def hash_key(key)
        prefix, k = split_key(key)
        if prefix.nil? || k.nil?
          raise ArgumentError, "Key must have a prefix and a key separated by a dash"
        end
        "#{prefix}#{ActiveCachedResource::Constants::PREFIX_SEPARATOR}#{Digest::MD5.hexdigest(k)}"
      end

      def compress(value)
        value.to_json
      end

      def decompress(value)
        JSON.parse(value)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
