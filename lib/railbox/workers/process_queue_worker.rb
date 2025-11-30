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
              on_failure(e, record)
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
          SELECT t.*
          FROM transactional_outboxes t
          WHERE t.status = 'in_progress'
            AND (t.retry_at IS NULL OR t.retry_at <= NOW())
            AND NOT EXISTS (
              SELECT 1
              FROM transactional_outboxes f
              WHERE f.status = 'failed'
                AND (
                  (t.action_data ? 'group' AND (f.action_data->>'group') = (t.action_data->>'group'))
                  OR (
                    (NOT (t.action_data ? 'group') OR (t.action_data->>'group') IS NULL)
                    AND f.entity_type = t.entity_type
                    AND f.entity_id   = t.entity_id
                  )
                )
            )
          ORDER BY t.created_at
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
        end.compact_blank
      end

      def process_record(record)
        Rails.logger.info("Start process with transactional outbox ID #{record.id}")
        take_processor(record).process(record)

        TransactionalOutboxMutator.update(record, {status: 'completed'})

        Rails.logger.info("Finish process with transactional outbox ID #{record.id}")
      end

      def on_failure(error, record)
        record = TransactionalOutboxMutator.update(record, {failure_reasons: record.failure_reasons << {message: error.message, backtrace: error.backtrace&.take(3), at: DateTime.current}})
        take_processor(record).on_failure(record) if record.failed?

        raise error if record.in_group? || record.action_type == 'handler'

        Rails.logger.error("RailboxWorker error: #{error.message}\n #{error.backtrace&.take(3)&.join("\n")}")
      end

      def take_processor(record)
        processor = PROCESSORS[record.action_type]

        raise Railbox::QueueError, "Unknown action_type=#{record.action_type} for outbox #{record.id}" unless processor

        processor
      end
    end
  end
end
