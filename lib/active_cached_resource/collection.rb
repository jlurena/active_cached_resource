module ActiveCachedResource
  class Collection < ActiveResource::Collection
    # Reload the collection by re-fetching the resources from the API.
    #
    # ==== Returns
    #
    # [Array<Object>] The collection of resources retrieved from the API.
    def reload
      query_params[Constants::RELOAD_PARAM] = true
      super
    end

    private

    def request_resources!
      return @elements if requested? || resource_class.nil?

      # Delete the reload param from query params.
      # This is drilled down via `params` option to determine if the collection should be reloaded
      should_reload = query_params.delete(Constants::RELOAD_PARAM)
      if !should_reload
        from_cache = resource_class.send(:cache_read, from, path_params, query_params, prefix_options)
        @elements = from_cache
        return @elements if @elements
      end

      super # This sets @elements

      if resource_class.send(:should_cache?, @elements)
        resource_class.send(:cache_write, @elements, from, path_params, query_params, prefix_options)
      end

      @elements
    ensure
      @requested = true
    end
  end
end
