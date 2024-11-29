# frozen_string_literal: true

module ActiveResource
  module Formats
    autoload :XmlFormat, "#{__dir__}/formats/xml_format.rb"
    autoload :JsonFormat, "#{__dir__}/formats/json_format.rb"

    # Lookup the format class from a mime type reference symbol. Example:
    #
    #   ActiveResource::Formats[:xml]  # => ActiveResource::Formats::XmlFormat
    #   ActiveResource::Formats[:json] # => ActiveResource::Formats::JsonFormat
    def self.[](mime_type_reference)
      ActiveResource::Formats.const_get(ActiveSupport::Inflector.camelize(mime_type_reference.to_s) + "Format")
    end

    def self.remove_root(data)
      if data.is_a?(Hash) && data.keys.size == 1 && data.values.first.is_a?(Enumerable)
        data.values.first
      else
        data
      end
    end
  end
end
