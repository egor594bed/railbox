module Railbox
  module Mutators
    class TransactionalOutboxMutator
      class << self

        def create(attributes)
          TransactionalOutbox.create!(attributes)
        end

        def update(record, attributes)
          record.assign_attributes(attributes)

          if record.status == 'in_progress'
            record.attempts += 1

            if record.attempts > Railbox.configuration.max_attempts
              record.status = 'failed'
            else
              record.retry_at = Railbox.configuration.retry_strategy[record.attempts - 1].from_now
            end
          end

          record.save!
          record
        end
      end
    end
  end
end
