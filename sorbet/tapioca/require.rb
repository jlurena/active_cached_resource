# typed: true
# frozen_string_literal: true

require "active_job/serializers/object_serializer"
require "active_support/all"
require "active_support/concern"
require "active_support/log_subscriber/test_helper"
require "dotenv/load"
require "minitest/reporters"
require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/channel/channel_generator"
require "rails/generators/migration"
require "rake/testtask"
require "rspec/core/rake_task"
require "rubocop/rake_task"
