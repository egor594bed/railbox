require 'rails/generators'
require 'rails/generators/migration'

module Railbox
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('templates', __dir__)

      def create_migration_file
        migration_template 'migration.rb.tt', "db/migrate/create_transactional_outbox.rb"
      end

      def self.next_migration_number(dirname)
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    end
  end
end
