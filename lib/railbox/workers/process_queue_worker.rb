module Railbox
  module Workers
    class ProcessQueueWorker < BaseWorker
      PROCESSORS = {
        'handler'      => Processors::HandlerProcessor,
        'http_request' => Processors::HttpProcessor
      }.freeze

      def perform
        with_lock do
          grouped_records.each_value do |group|
            group.each do |record|
              process_record(record)
            rescue => e
              TransactionalOutboxMutator.update(record, {failure_reasons: record.failure_reasons << { message: e.message, backtrace: e.backtrace&.take(3), at: DateTime.current}})
              raise e if record.in_group? || record.action_type == 'handler'

              Rails.logger.error("RailboxWorker error: #{e.message}\n #{e.backtrace&.take(3)&.join("\n")}")

              next
            end
          rescue => e
            Rails.logger.error("RailboxWorker error: #{e.message}\n #{e.backtrace&.take(3)&.join("\n")}")
            next
          end
        rescue => e
          Rails.logger.error("RailboxWorker error: #{e.message}\n #{e.backtrace&.take(3)&.join("\n")}")
        end
      end

      private

      def grouped_records
        sql = <<-SQL.squish
          SELECT *
          FROM transactional_outboxes
          WHERE status = 'in_progress'
            AND (retry_at IS NULL OR retry_at <= NOW())
          ORDER BY created_at
        SQL

        records = Railbox::TransactionalOutbox.find_by_sql(sql)

        grouped = records.group_by do |record|
          record.group.present? ? [:group, record.group] : [:entity, record.entity_group]
        end

        grouped.transform_values do |group_records|
          key_record = group_records.first
          scope      = Railbox::TransactionalOutbox.where(status: 'in_progress')

          if key_record.group.present?
            scope = scope.where("action_data ->> 'group' = ?", key_record.group)
          else
            scope = scope.where(entity_type: key_record.entity_type, entity_id: key_record.entity_id)
          end

          all_group_records = scope.order(:created_at).to_a

          group_records if all_group_records.first&.id.in?(group_records.map(&:id))
        end.compact.reject { |_k, v| v.blank? }
      end

      def process_record(record)
        Rails.logger.info("Start process with transactional outbox ID #{record.id}")
        processor = PROCESSORS[record.action_type]

        if processor
          processor.process(record)
        else
          raise Railbox::QueueError, "Unknown action_type=#{record.action_type} for outbox #{record.id}"
        end

        TransactionalOutboxMutator.update(record, {status: 'completed'})

        Rails.logger.info("Finish process with transactional outbox ID #{record.id}")
      end
    end
  end
end
