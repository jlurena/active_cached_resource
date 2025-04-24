module ActiveCachedResource
  class Collection < ActiveResource::Collection
    class_attribute :virtual_persisted_attributes, default: []

    # This method dynamically creates accessor methods for the specified attributes
    # and adds them to a list of virtual persisted attributes to keep track of
    # attributes that should be persisted to cache.
    #
    # @param args [Array<Symbol>] A list of attribute names to be persisted.
    # @return [void]
    def self.persisted_attribute(*args)
      attr_accessor(*args)
      self.virtual_persisted_attributes += args
    end

    def virtual_persistable_attributes
      self.class.virtual_persisted_attributes.each_with_object({}) do |attribute, hash|
        hash[attribute] = public_send(attribute)
      end
    end

    # Reload the collection by re-fetching the resources from the API.
    #
    # @return Returns [Array<Object>] The collection of resources retrieved from the API.
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
        if from_cache
          update_self!(from_cache)
          return @elements if @elements
        end
      end

      super # This sets @elements

      if resource_class.send(:should_cache?, @elements)
        resource_class.send(:cache_write, self, from, path_params, query_params, prefix_options)
      end

      @elements
    ensure
      @requested = true
    end

    def update_self!(other_collection)
      # Ensure that the virtual persisted attributes are also updated
      self.class.virtual_persisted_attributes.each do |attribute|
        public_send(:"#{attribute}=", other_collection.public_send(attribute))
      end

      @elements = other_collection.instance_variable_get(:@elements)
      @from = other_collection.instance_variable_get(:@from)
      @query_params = other_collection.query_params
      @path_params = other_collection.path_params
      @prefix_options = other_collection.prefix_options
    end
  end
end
