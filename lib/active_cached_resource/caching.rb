module ActiveCachedResource
  module Caching
    GLOBAL_PREFIX = "acr"
    RELOAD_PARAM = :_acr_reload

    extend ActiveSupport::Concern

    included do
      class << self
        alias_method :find_without_cache, :find
        alias_method :find, :find_with_cache
      end
    end

    module ClassMethods
      def find_with_cache(*orig_args)
        args = orig_args.deep_dup # Avoid mutating original arguments
        options = extract_options(*args)

        should_reload = options.delete(:reload) || !cached_resource.enabled

        # When bypassing cache, include the reload option as a query parameter for collection requests.
        # Hacky but this way ActiveResource::Collection#request_resources! can access it
        if should_reload && args.first == :all
          options[:params] = {} if options[:params].blank?
          options[:params][RELOAD_PARAM] = should_reload
          args << options
        end

        if args.first == :all
          # Let ActiveResource::Collection handle the caching so that lazy loading is more effective
          return find_via_reload(*args)
        end

        should_reload ? find_via_reload(*args) : find_via_cache(*args)
      end

      # Clear the cache.
      def clear
        cached_resource.cache.clear("#{cache_key_prefix}/")
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
      # @param object [Object, ActiveResource::Collection] The object to check for caching eligibility.
      # @return [Boolean] Returns true if the object should be cached, false otherwise.
      def should_cache?(object)
        return false unless cached_resource.enabled

        # Calling `present?` on the `collection_parser`, an instance or descendent of
        # `ActiveResource::Collection` will trigger a request.
        # Checking if `requested?` first, will prevent an unnecessary network request when calling `present?`.
        case object
        when ActiveResource::Collection
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
