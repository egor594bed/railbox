FactoryBot.define do
  factory :transactional_outbox, class: 'Railbox::TransactionalOutbox' do
    action_type { 'handler' }
    action_data { {class_name: 'MyService', method_name: 'create'} }
    status      { 'in_progress' }
    entity_type { nil }
    entity_id   { nil }
    failure_reasons { [] }
    attempts { 0 }
  end
end
