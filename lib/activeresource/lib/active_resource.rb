# frozen_string_literal: true

#--
# Copyright (c) 2006-2012 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require "uri"

require "active_support"
require "active_model"
require_relative "active_resource/exceptions"

module ActiveResource

  URI_PARSER = defined?(URI::RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::RFC2396_Parser.new

  autoload :Base, "#{__dir__}/active_resource/base.rb"
  autoload :Callbacks, "#{__dir__}/active_resource/callbacks.rb"
  autoload :Collection, "#{__dir__}/active_resource/collection.rb"
  autoload :Connection, "#{__dir__}/active_resource/connection.rb"
  autoload :CustomMethods, "#{__dir__}/active_resource/custom_methods.rb"
  autoload :Formats, "#{__dir__}/active_resource/formats.rb"
  autoload :HttpMock, "#{__dir__}/active_resource/http_mock.rb"
  autoload :InheritingHash, "#{__dir__}/active_resource/inheriting_hash.rb"
  autoload :Schema, "#{__dir__}/active_resource/schema.rb"
  autoload :Singleton, "#{__dir__}/active_resource/singleton.rb"
  autoload :Validations, "#{__dir__}/active_resource/validations.rb"
end

require "active_resource/railtie" if defined?(Rails.application)
