# frozen_string_literal: true

require_relative "lib/active_cached_resource/version"

Gem::Specification.new do |spec|
  spec.name = "active_cached_resource"
  spec.version = ActiveCachedResource::VERSION
  spec.authors = ["Jean Luis Urena"]
  spec.email = ["eljean@live.com"]

  spec.summary = "ActiveResource, but with a caching layer."
  spec.homepage = "https://github.com/jlurena/active_cached_resource"
  spec.required_ruby_version = ">= 3.2.0"
  spec.platform = Gem::Platform::RUBY

  spec.metadata = {
    "changelog_uri" => "https://github.com/jlurena/active_cached_resource/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/active_cached_resource/",
    "source_code_uri" => "https://github.com/jlurena/active_cached_resource",
    "homepage_uri" => spec.homepage,
    "wiki_uri" => "https://github.com/jlurena/active_cached_resource/wiki"
  }

  spec.files = [
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "lib/active_cached_resource.rb",
    *Dir.glob("lib/active_cached_resource/**/*"),
    *Dir.glob("lib/activeresource/lib/**/*"),
    "lib/activeresource/README.md",
    *Dir.glob("lib/generators/**/*")
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel-serializers-xml", "~> 1.0"
  spec.add_dependency "activemodel", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "ostruct", "~> 0.6.1"
end
