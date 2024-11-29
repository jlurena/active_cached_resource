# frozen_string_literal: true

require "rake/testtask"
require "bundler"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# ActiveCachedResource tests
RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

# ActiveResource tests
Rake::TestTask.new(:ar_tests) do |t|
  t.libs = ["lib/activeresource/test"]
  t.pattern = "lib/activeresource/test/**/*_test.rb"
  t.warning = true
  t.verbose = true
end

task default: [:rubocop, :spec, :ar_tests]
