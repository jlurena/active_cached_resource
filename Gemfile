# frozen_string_literal: true

source "https://rubygems.org"

gem "dotenv", "~> 3.1", ">= 3.1.7"
gem "rake", "~> 13.2", ">= 13.2.1"

group :versioning do
  gem "bump", "~> 0.10.0"
end

group :development, :test do
  gem "activejob", ">= 6.0"
  gem "activerecord", ">= 6.0"
  gem "pry-byebug", "~> 3.10", ">= 3.10.1"
  gem "rails", ">= 6.0"
  gem "rexml", "~> 3.4"
  gem "rubocop-md", "~> 1.2", ">= 1.2.4"
  gem "rubocop-minitest", "~> 0.36.0"
  gem "rubocop-packaging", "~> 0.5.2"
  gem "rubocop-rails", "~> 2.27"
  gem "sorbet-static-and-runtime", "~> 0.5.11609", require: false
  gem "sqlite3", "~> 2.3", ">= 2.3.1"
  gem "standard", "~> 1.40"
  gem "tapioca", "~> 0.16.3", require: false
end

group :test do
  gem "minitest-reporters", "~> 1.7", ">= 1.7.1"
  gem "mocha", ">= 0.13.0"
  gem "rspec_junit_formatter", "~> 0.6.0"
  gem "rspec", "~> 3.13"
  gem "simplecov", "~> 0.22.0", require: false
end

gemspec
