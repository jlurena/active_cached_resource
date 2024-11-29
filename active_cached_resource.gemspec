# frozen_string_literal: true

require_relative "lib/active_cached_resource/version"

Gem::Specification.new do |spec|
  spec.name = "active_cached_resource"
  spec.version = ActiveCachedResource::VERSION::STRING
  spec.authors = ["Jean Luis Urena"]
  spec.email = ["eljean@live.com"]

  spec.summary = "ActiveResource, but with a caching layer."
  spec.homepage = "https://github.com/jlurena/active_cached_resource"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "changelog_uri" => "https://github.com/jlurena/active_cached_resource/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/active_cached_resource/",
    "source_code_uri" => "https://github.com/jlurena/active_cached_resource",
    "homepage_uri" => spec.homepage,
    "wiki_uri" => "https://github.com/jlurena/active_cached_resource/wiki"
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel-serializers-xml", "~> 1.0"
  spec.add_dependency "activemodel", ">= 6.0"
  spec.add_dependency "activesupport", ">= 6.0"
  spec.add_dependency "msgpack", "~> 1.7", ">= 1.7.5"

  spec.add_development_dependency "activejob", ">= 6.0"
  spec.add_development_dependency "activerecord", ">= 6.0"
  spec.add_development_dependency "mocha", ">= 0.13.0"
  spec.add_development_dependency "rake", "~> 13.2", ">= 13.2.1"
  spec.add_development_dependency "rexml"
  spec.add_development_dependency "sqlite3", "~> 2.3", ">= 2.3.1"
end
