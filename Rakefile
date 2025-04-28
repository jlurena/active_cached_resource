# frozen_string_literal: true

require "bundler"
require "bundler/gem_tasks"

if (Bundler.definition.groups - Bundler.settings[:without] + Bundler.settings[:with]).include?(:test)
  require "rake/testtask"
  require "rspec/core/rake_task"
  require "rubocop/rake_task"

  RSpec::Core::RakeTask.new(:spec) do |r|
    r.rspec_opts = ["--no-color"]
    r.verbose = false
  end

  RuboCop::RakeTask.new(:rubocop) do |r|
    r.options = ["--no-color", "--format", "simple"]
    r.verbose = false
  end

  # ActiveResource tests
  Rake::TestTask.new(:active_resource_test) do |t|
    t.libs = ["lib/activeresource/test"]
    t.pattern = "lib/activeresource/test/**/*_test.rb"
    t.warning = false
    t.verbose = false
  end

  desc "Type check"
  task :tc do
    sh "bundle exec srb tc"
  end

  task default: [:tc, :rubocop, :spec, :active_resource_test]
end
