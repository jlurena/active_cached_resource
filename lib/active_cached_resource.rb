# frozen_string_literal: true

require_relative "activeresource/lib/activeresource"

require_relative "active_cached_resource/constants"
require_relative "active_cached_resource/model"
require_relative "active_cached_resource/version"

module ActiveCachedResource
end

module ActiveResource
  class Base
    include ActiveCachedResource::Model
  end
end
