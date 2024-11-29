require "ostruct"
require_relative "logger"
require_relative "caching_strategies/sql_cache"
require_relative "caching_strategies/active_support_cache"
require_relative "caching_strategies/base"

module ActiveCachedResource
  class Configuration < OpenStruct
    CACHING_STRATEGIES = {
      active_record: ActiveCachedResource::CachingStrategies::SQLCache,
      active_support: ActiveCachedResource::CachingStrategies::ActiveSupportCache
    }

    OPTIONS = %i[cache_key_prefix logger enabled ttl]

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

    def on!
      self.enabled = true
    end

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
