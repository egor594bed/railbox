module Railbox
  module Models
    # == Schema Information
    #
    # Table name: transactional_outboxes
    #
    #  id              :bigint           not null, primary key
    #  action_type     :string           not null    # Type of action/event (class_method/http)
    #  action_data     :jsonb            not null    # Action data or payload ({process_class: "MyService", process_method: "create"}/{method: "POST", url: "https://..."}) (default: {})
    #  status          :string           not null    # Processing status (e.g. in_progress, failed, completed)
    #  entity_type     :string                       # Polymorphic type for associated entity
    #  entity_id       :integer                      # Polymorphic ID for associated entity
    #  query           :jsonb                        # Url query (JSON)
    #  body            :jsonb                        # Main body/payload (default: {})
    #  headers         :jsonb                        # Headers (default: {})
    #  meta            :jsonb                        # Metadata or extra info (JSON)
    #  attempts        :integer          default(0)  # Number of processing attempts
    #  retry_at        :datetime                     # Next retry timestamp
    #  failure_reasons :jsonb, array                 # Array of failure reason objects
    #  created_at      :datetime         not null    # Record creation timestamp
    #  updated_at      :datetime         not null    # Last update timestamp
    #
    # Indexes
    #
    #  index_transactional_outboxes_on_entity_type_and_entity_id  (entity_type,entity_id)
    #
    # Purpose:
    #   - Queues reliable actions/events for external systems.
    #   - Tracks delivery status and retry logic.
    #   - Stores metadata and failure reasons for auditing/debugging.
    #
    class TransactionalOutbox < ::ActiveRecord::Base
      belongs_to :relative_entity, polymorphic: true, foreign_key: :entity_id, foreign_type: :entity_type

      def in_group?
        group.present? || entity_group.present?
      end

      def group
        action_data[:group]
      end

      def entity_group
        "#{entity_type}.#{entity_id}"
      end
    end
  end
end


