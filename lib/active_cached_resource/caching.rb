require_relative "collection"

module ActiveCachedResource
  module Caching
    GLOBAL_PREFIX = "acr"
    RELOAD_PARAM = :_acr_reload

    extend ActiveSupport::Concern

    included do
      class << self
        alias_method :find_without_cache, :find
        alias_method :find, :find_with_cache

        def collection_parser
          _collection_parser || ActiveCachedResource::Collection
        end
      end
    end

    module ClassMethods
      # Finds resources similarly to ActiveRecord's +find+ method, with caching support.
      #
      # This method is also called internally by the `where` method. When you use `where` to filter results,
      # it translates the query conditions into parameters and delegates to this method.
      #
      # Depending on the first argument provided, this method retrieves:
      #
      # * `:one`  - A single resource.
      # * `:first` - The first resource in the result set.
      # * `:last`  - The last resource in the result set.
      # * `:all`   - An array of all matching resources.
      #
      # If an Integer or String ID is provided instead of a symbol, it attempts to find a single resource by that ID.
      #
      # @overload find_with_cache(scope, options = {})
      #   @param scope [Symbol, Integer, String]
      #     The scope of the query or the ID of the resource to find.
      #     Can be `:one`, `:first`, `:last`, `:all`, or a specific ID.
      #   @param options [Hash] Additional query options.
      #   @option options [String, Symbol] :from
      #     The path or custom endpoint from which to fetch resources.
      #   @option options [Hash] :params
      #     Query and prefix (nested URL) parameters.
      #
      # @return [Object, Array<Object>, nil]
      #   * Returns a single resource object if `:one`, `:first`, `:last`, or an ID is given.
      #   * Returns an array of resources if `:all` is given.
      #   * Returns `nil` if no data is found for `:one`, `:first`, `:last`, or `:all` queries.
      #
      # @raise [ResourceNotFound]
      #   Raises if the requested resource by ID cannot be found.
      #
      # @note
      #   If the `:reload` option is passed (e.g. `:reload => true`), the cache will be bypassed, and
      #   the resource(s) will be fetched directly from the server.
      #
      # @example Find a single resource by ID
      #   Person.find(1)
      #   # GET /people/1.json
      #
      # @example Find all resources
      #   Person.find(:all)
      #   # GET /people.json
      #
      # @example Find all resources with query parameters
      #   Person.find(:all, params: { title: "CEO" })
      #   # GET /people.json?title=CEO
      #
      # @example Find the first resource from a custom endpoint
      #   Person.find(:first, from: :managers)
      #   # GET /people/managers.json
      #
      # @example Find the last resource from a custom endpoint
      #   Person.find(:last, from: :managers)
      #   # GET /people/managers.json
      #
      # @example Find all resources from a nested URL
      #   Person.find(:all, from: "/companies/1/people.json")
      #   # GET /companies/1/people.json
      #
      # @example Find a single resource from a custom endpoint
      #   Person.find(:one, from: :leader)
      #   # GET /people/leader.json
      #
      # @example Find all developers speaking Ruby
      #   Person.find(:all, from: :developers, params: { language: 'ruby' })
      #   # GET /people/developers.json?language=ruby
      #
      # @example Find a single resource from a nested URL
      #   Person.find(:one, from: "/companies/1/manager.json")
      #   # GET /companies/1/manager.json
      #
      # @example Find a resource with nested prefix parameters
      #   StreetAddress.find(1, params: { person_id: 1 })
      #   # GET /people/1/street_addresses/1.json
      #
      # When `where` is used, it automatically builds the query parameters and calls `find_with_cache(:all, ...)`:
      #
      # @example Using `where` with parameters
      #   Person.where(title: "CEO")
      #   # Under the hood: Person.find_with_cache(:all, params: { title: "CEO" })
      #   # => GET /people.json?title=CEO
      #
      #   Person.where(language: 'ruby').where(from: :developers)
      #   # Under the hood: Person.find_with_cache(:all, from: :developers, params: { language: 'ruby' })
      #   # => GET /people/developers.json?language=ruby
      #
      # == Failure or missing data
      # A failure to find the requested object by ID raises a ResourceNotFound exception.
      # With any other scope, find returns nil when no data is returned.
      #
      #   Person.find(1)
      #   # => raises ResourceNotFound
      #
      #   Person.find(:all)
      #   Person.find(:first)
      #   Person.find(:last)
      #   # => nil
      #
      def find_with_cache(*orig_args)
        args = orig_args.deep_dup # Avoid mutating original arguments
        options = extract_options(*args)

        should_reload = options.delete(:reload) || !cached_resource.enabled

        # When bypassing cache, include the reload option as a query parameter for collection requests.
        # Hacky but this way ActiveCachedResource::Collection#request_resources! can access it
        if should_reload && args.first == :all
          options[:params] = {} if options[:params].blank?
          options[:params][RELOAD_PARAM] = should_reload
          args << options
        end

        if args.first == :all
          # Let ActiveCachedResource::Collection handle the caching so that lazy loading is more effective
          return find_via_reload(*args)
        end

        should_reload ? find_via_reload(*args) : find_via_cache(*args)
      end

      # Clears the cache for the specified pattern.
      #
      # @param pattern [String, nil] The pattern to match cache keys against.
      #  If nil, all cache keys with this models prefix will be cleared.
      # @return [void]
      def clear_cache(pattern = nil)
        cached_resource.cache.clear("#{cache_key_prefix}/#{pattern}")
      end

      private

      def cache_read(*)
        key = cache_key(*)
        json_string = nil
        begin
          json_string = cached_resource.cache.read(key)
        rescue => e
          cached_resource.logger.error("[KEY:#{key}] Failed to read from cache: #{e.message} #{e.backtrace.join(" | ")}")
          json_string = nil
        end

        return nil if json_string.nil?

        cached_resource.logger.debug("[KEY:#{key}] Cache hit")
        json_to_object(json_string)
      end

      def cache_write(object, *)
        cache_options = {expires_in: cached_resource.ttl}
        cache_value = object_to_json(object, *)
        key = cache_key(*)

        begin
          cached_resource.cache.write(key, cache_value, cache_options)
          true
        rescue => e
          cached_resource.logger.error("[KEY:#{key}] Failed to write to cache: #{e.message} #{e.backtrace.join(" | ")}")
          false
        end
      end

      def find_via_cache(*)
        cache_read(*) || find_via_reload(*)
      end

      def find_via_reload(*)
        object = find_without_cache(*)
        return object unless should_cache?(object)

        cache_write(object, *)
        object
      end

      # Determines if the given object should be cached.
      #
      # @param object [Object, ActiveCachedResource::Collection] The object to check for caching eligibility.
      # @return [Boolean] Returns true if the object should be cached, false otherwise.
      def should_cache?(object)
        return false unless cached_resource.enabled

        # Calling `present?` on the `collection_parser`, an instance or descendent of
        # `ActiveCachedResource::Collection` will trigger a request.
        # Checking if `requested?` first, will prevent an unnecessary network request when calling `present?`.
        case object
        when ActiveCachedResource::Collection
          object.requested? && object.present?
        else
          object.present?
        end
      end

      def cache_key(*args)
        "#{name_key}/#{args.join("/")}".downcase.delete(" ")
      end

      def name_key
        # `cache_key_prefix` is separated from key parts with a dash to easily distinguish the prefix
        "#{cache_key_prefix}-" + name.parameterize.tr("-", "/")
      end

      def cache_key_prefix
        prefix = cached_resource.cache_key_prefix

        if prefix.respond_to?(:call)
          result = prefix.call
          if !result.is_a?(String) || result.empty?
            raise ArgumentError, "cache_key_prefix must return a non-empty String"
          end
          "#{GLOBAL_PREFIX}/#{result}"
        else
          "#{GLOBAL_PREFIX}/#{prefix}"
        end
      end

      def json_to_object(json_string)
        object = ActiveSupport::JSON.decode(json_string)
        resource = object["resource"]

        case resource
        when Array
          resource.map do |attrs|
            new(attrs["object"], attrs["persistence"]).tap do |r|
              r.prefix_options = object["prefix_options"]
            end
          end
        else
          new(resource["object"], resource["persistence"]).tap do |r|
            r.prefix_options = object["prefix_options"]
          end
        end
      end

      def object_to_json(object, *)
        options = extract_options(*)
        params = options.fetch(:params, {})
        prefix_options, query_options = split_options(params)
        json_object = if object.is_a? Enumerable
          {
            resource: object.map { |o| {object: o, persistence: o.persisted?} },
            prefix_options: prefix_options,
            path_params: params,
            query_params: query_options
          }
        else
          {
            resource: {object: object, persistence: object.persisted?},
            prefix_options: prefix_options
          }
        end
        ActiveSupport::JSON.encode(json_object)
      end

      # Extract options without mutating the original arguments.
      def extract_options(*args)
        if (last = args.last) && last.try(:extractable_options?)
          last
        else
          {}
        end
      end
    end
  end
end
