require "ostruct"
require_relative "logger"
require_relative "caching_strategies/sql_cache"
require_relative "caching_strategies/active_support_cache"
require_relative "caching_strategies/base"

module ActiveCachedResource
  class Configuration < OpenStruct
    CACHING_STRATEGIES = {
      active_record_sql: ActiveCachedResource::CachingStrategies::SQLCache,
      active_support_cache: ActiveCachedResource::CachingStrategies::ActiveSupportCache
    }

    OPTIONS = %i[cache_key_prefix logger enabled ttl]

    # Initializes a new configuration for the given model with the specified options.
    #
    # @param model [Class] The model class for which the configuration is being set.
    # @param options [Hash] A hash of options to customize the configuration.
    # @option options [Symbol] :cache_store The cache store to be used.
    # @option options [Symbol] :cache_strategy The cache strategy to be used. One of :active_record_sql or :active_support_cache.
    # @option options [String] :cache_key_prefix The prefix for cache keys (default: model name underscored).
    # @option options [Logger] :logger The logger instance to be used (default: ActiveCachedResource::Logger).
    # @option options [Boolean] :enabled Whether caching is enabled (default: true).
    # @option options [Integer] :ttl The time-to-live for cache entries in seconds (default: 86400).
    #
    # @return [ActiveCachedResource::Configuration] The configuration instance.
    #
    # @note If `cache_store` is provided and is a CachingStrategies::Base instance, it will be used as the cache strategy.
    #  Otherwise, `cache_strategy` must be provided to determine the cache strategy.
    def initialize(model, options = {})
      super(
        {
          cache: determine_cache_strategy(options[:cache_store], options[:cache_strategy]),
          cache_key_prefix: model.name.underscore,
          logger: ActiveCachedResource::Logger.new(model.name),
          enabled: true,
          ttl: 86400
        }.merge(options.slice(*OPTIONS))
      )
    end

    # Enables caching.
    #
    # @return [void]
    def on!
      self.enabled = true
    end

    # Disables caching.
    #
    # @return [void]
    def off!
      self.enabled = false
    end

    private

    def determine_cache_strategy(cache_store, cache_strategy)
      if cache_store.is_a?(CachingStrategies::Base)
        cache_store
      elsif cache_strategy
        CACHING_STRATEGIES.fetch(cache_strategy).new(cache_store)
      else
        raise ArgumentError, "cache_store must be a CachingStrategies::Base or cache_strategy must be provided"
      end
    rescue KeyError
      raise ArgumentError, "Invalid cache strategy: #{cache_strategy}"
    end
  end
end
