require "active_support/concern"

require_relative "caching"
require_relative "configuration"

module ActiveCachedResource
  module Model
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :cached_resource

        # Sets up caching for an ActiveResource model.
        #
        # @param options [Hash] A hash of options to customize the configuration.
        # @option options [Symbol] :cache_store The cache store to be used. Must be a CachingStrategies::Base instance.
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
        def cached_resource(options = {})
          @cached_resource || setup_cached_resource!(options)
        end

        # :nodoc:
        def setup_cached_resource!(options)
          @cached_resource = ActiveCachedResource::Configuration.new(self, options)
          include ActiveCachedResource::Caching
          @cached_resource
        end
        # :nodoc:
      end
    end

    # :nodoc:
    module ClassMethods
      def inherited(child)
        child.cached_resource = cached_resource if defined?(@cached_resource)
        super
      end
    end
    # :nodoc:
  end
end
