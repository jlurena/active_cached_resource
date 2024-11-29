# frozen_string_literal: true

source "https://rubygems.org"

group :ci, :development, :test do
  gem "bump", "~> 0.10.0"
  gem "rake", "~> 13.2", ">= 13.2.1"
  gem "rubocop-md", "~> 1.2", ">= 1.2.4"
  gem "rubocop-minitest", "~> 0.36.0"
  gem "rubocop-packaging", "~> 0.5.2"
  gem "rubocop-rails", "~> 2.27"
  gem "standard", "~> 1.40"
end

group :development, :test do
  gem "pry-byebug", "~> 3.10", ">= 3.10.1"
  gem "sorbet-static-and-runtime", "~> 0.5.11609", require: false
  gem "tapioca", "~> 0.16.3", require: false
end

group :test do
  gem "rspec", "~> 3.13"
  gem "simplecov", "~> 0.22.0", require: false
end

gemspec
