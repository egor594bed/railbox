require 'active_record'
require 'active_job'

require 'faraday'
require 'faraday/httpclient'

require_relative 'railbox/exceptions/validation_error'
require_relative 'railbox/exceptions/queue_error'

require_relative 'railbox/models/transactional_outbox'
require_relative 'railbox/mutators/transactional_outbox_mutator'

require_relative 'railbox/interfaces/transactional_outbox_interface'

require_relative 'railbox/queue/base_queue'
require_relative 'railbox/queue/http_queue'
require_relative 'railbox/queue/handling_queue'

require_relative 'railbox/handler/handler'

require_relative 'railbox/processors/handler_processor'
require_relative 'railbox/processors/http_processor'

require_relative 'railbox/workers/base_worker'
require_relative 'railbox/workers/process_queue_worker'

require_relative 'railbox/http_client/faraday'

module Railbox
  class << self
    attr_writer :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end


  class Configuration
    attr_accessor :max_attempts, :retry_strategy

    def initialize
      @max_attempts   = 5
      @retry_strategy = [1.minute, 10.minutes, 1.hour, 3.hours, 1.day]
    end
  end
end

Railbox::HttpQueue                  = Railbox::Queue::HttpQueue
Railbox::HandlingQueue              = Railbox::Queue::HandlingQueue
Railbox::TransactionalOutbox        = Railbox::Models::TransactionalOutbox
Railbox::TransactionalOutboxMutator = Railbox::Mutators::TransactionalOutboxMutator
Railbox::QueueError                 = Railbox::Exceptions::QueueError
Railbox::ValidationError            = Railbox::Exceptions::ValidationError