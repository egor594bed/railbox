require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: ':memory:'
)

ActiveRecord::Schema.define do
  create_table :transactional_outboxes, force: true do |t|
    t.string :action_type, null: false
    t.text :action_data, null: false, default: '{}'
    t.string :status, null: false
    t.string :entity_type
    t.integer :entity_id
    t.text :query
    t.text :body, default: '{}'
    t.text :headers, default: '{}'
    t.text :meta
    t.integer :attempts, default: 0
    t.datetime :retry_at
    t.text :failure_reasons
    t.timestamps null: false
  end

  add_index :transactional_outboxes, [:entity_type, :entity_id]
end

require 'logger'

unless defined?(Rails)
  module Rails; end
  Rails.singleton_class.attr_accessor :logger
  Rails.logger = Logger.new(nil)
end

require_relative '../lib/railbox'
require 'factory_bot'
FactoryBot.find_definitions

RSpec.configure do |config|
  config.before(:suite) do
    Railbox::Models::TransactionalOutbox.class_eval do
      serialize :action_data, coder: JSON
      serialize :query, coder: JSON
      serialize :body, coder: JSON
      serialize :headers, coder: JSON
      serialize :meta, coder: JSON
      serialize :failure_reasons, coder: JSON
    end
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.include FactoryBot::Syntax::Methods
end
