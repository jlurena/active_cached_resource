require "active_support/concern"

require_relative "caching"
require_relative "configuration"

module ActiveCachedResource
  module Model
    extend ActiveSupport::Concern

    included do
      class << self
        attr_accessor :cached_resource

        def cached_resource(options = {})
          @cached_resource || setup_cached_resource!(options)
        end

        def setup_cached_resource!(options)
          @cached_resource = ActiveCachedResource::Configuration.new(self, options)
          include ActiveCachedResource::Caching
          @cached_resource
        end
      end
    end

    module ClassMethods
      def inherited(child)
        child.cached_resource = cached_resource if defined?(@cached_resource)
        super
      end
    end
  end
end
