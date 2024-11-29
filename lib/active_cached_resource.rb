# frozen_string_literal: true

require_relative "activeresource/lib/activeresource"

require_relative "active_cached_resource/model"
require_relative "active_cached_resource/version"

module ActiveCachedResource
end

module ActiveResource
  class Base
    include ActiveCachedResource::Model
  end

  class Collection
    private

    # Monkey patch ActiveResource::Collection to handle caching
    # @see lib/activeresource/lib/active_resource/collection.rb
    def request_resources!
      return @elements if requested?

      # MONKEY PATCH
      # Delete the reload param from query params.
      # This is drilled down via `params` option to determine if the collection should be reloaded
      should_reload = query_params.delete(ActiveCachedResource::Caching::RELOAD_PARAM)
      if !should_reload
        from_cache = resource_class.send(:cache_read, from, path_params, query_params, prefix_options)
        @elements = from_cache
        return @elements if @elements
      end
      # MONKEY PATCH

      response =
        case from
        when Symbol
          resource_class.get(from, path_params)
        when String
          path = "#{from}#{query_string(query_params)}"
          resource_class.format.decode(resource_class.connection.get(path, resource_class.headers).body)
        else
          path = resource_class.collection_path(prefix_options, query_params)
          resource_class.format.decode(resource_class.connection.get(path, resource_class.headers).body)
        end

      # Update the elements
      parse_response(response)
      @elements.map! { |e| resource_class.instantiate_record(e, prefix_options) }

      # MONKEY PATCH
      # Write cache
      resource_class.send(:cache_write, @elements, from, path_params, query_params, prefix_options)
      @elements
      # MONKEY PATCH
    rescue ActiveResource::ResourceNotFound
      # Swallowing ResourceNotFound exceptions and return nothing - as per ActiveRecord.
      # Needs to be empty array as Array methods are delegated
      []
    ensure
      @requested = true
    end
  end
end
