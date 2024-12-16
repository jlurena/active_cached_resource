# typed: true
# frozen_string_literal: true

require "active_support/all"
require "active_support/concern"
require "active_support/log_subscriber/test_helper"
require "active_job/serializers/object_serializer"
require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/channel/channel_generator"
require "rails/generators/migration"
require "rspec/core/rake_task"
require "rubocop/rake_task"
