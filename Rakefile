# frozen_string_literal: true

require "bundler"
require "bundler/gem_tasks"

unless ENV["CI"]
  require "rake/testtask"
  require "rspec/core/rake_task"
  require "rubocop/rake_task"

  # ActiveCachedResource tests
  RSpec::Core::RakeTask.new(:spec)
  RuboCop::RakeTask.new(:rubocop)

  # ActiveResource tests
  Rake::TestTask.new(:active_resource_test) do |t|
    t.libs = ["lib/activeresource/test"]
    t.pattern = "lib/activeresource/test/**/*_test.rb"
    t.warning = true
    t.verbose = true
  end

  desc "Type check"
  task :tc do
    sh "srb tc"
  end

  task default: [:tc, :rubocop, :spec, :active_resource_test]
end
