require "rails/generators/active_record"

module ActiveCachedResource
  module Generators
    class ActiveRecordGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration
      desc "Generates migration for cache tables"

      source_paths << File.join(File.dirname(__FILE__), "templates")

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def self.migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end

      def create_migration_file
        options = {
          migration_version: migration_version
        }
        migration_template "migration.erb", "db/migrate/create_active_cached_resource_table.rb", options
      end

      def migration_version
        self.class.migration_version
      end
    end
  end
end
