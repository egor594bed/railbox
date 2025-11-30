# Railbox

**Railbox** is a Ruby gem for implementing the Transactional Outbox pattern in Rails applications. It reliably queues and processes actions or HTTP requests using a dedicated database table, ensuring consistency and delivery guarantees even in distributed systems or during failures.

---

## Features

- **Async Actions:** Queue service class method calls or HTTP requests as atomic, auditable outbox entries.
- **Grouping:** Sequential, exclusive processing per logical group or entity.
- **Error Handling & Retries:** Automatic status, attempts, and failure reason tracking with support for retries.
- **Background Worker:** Idempotent, safe background processing with advisory locking.
- **Flexible Payload:** Support for custom headers, query parameters, meta, grouping, etc.

---

## Installation

Add to your Gemfile:
```ruby
gem "railbox"
```
Then install and set up the database table:
```
bundle install
rails generate railbox:install:migration
rails db:migrate
```
---

## Usage

### Enqueue a Service Class Method (Handler)
```ruby
MyApiHandler.enqueue(
    method:          "perform_action",  # Defaults to 'create'
    body:            { foo: "bar" },
    headers:         { "key" => "value" },
    query:           { page: 2 },
    relative_entity: User.last, # Active record entity
    meta:            { request_id: "uuid" }
)
```
All attributes are optional.

- **Validation:** Raises `ValidationError` for unknown class/method or bad arguments.

---

### Enqueue an HTTP Request
```ruby
Railbox::HttpQueue.enqueue(
    url:     "https://example.com/api",
    method:  :post,  # :get, :put, :patch, :delete also supported
    body:    { data: 1 },
    headers: { "Authorization" => "Bearer ..." },
    query:   { foo: "bar" },
    meta:    { correlation_id: "123" }
)
```
- **Validation:** Raises `ValidationError` for invalid URL, method, or body.

---

### Processing the Queue

Run the background worker to process pending outbox entries:
```ruby
Railbox::Workers::ProcessQueueWorker.perform_later
```
- Safely processes queued actions.
- Updates status, attempts, and failure reasons.
- Groups items for atomic and conflict-free execution.

> **Tip:**  
> For production, it is recommended to use a job scheduler such as [Solid Queue](https://github.com/basecamp/solid_queue) or [Sidekiq](https://sidekiq.org/) scheduling (e.g., with [sidekiq-scheduler](https://github.com/sidekiq-scheduler/sidekiq-scheduler)) to run `ProcessQueueWorker` regularly and ensure timely processing of outbox items.


---

### Handler (Service Class for Outbox)

A **Handler** is your service class that Railbox will invoke from an outbox record for asynchronous execution. The Handler class must inherit from `Railbox::BaseHandler` and implement public class methods corresponding to possible queue actions.

#### Custom Handler Example

You can create your own handler class and specify it when enqueuing a task. For example, the handler can make an HTTP request and save part of the response to an associated entity:
```ruby
class MyApiHandler
    require 'net/http'
    require 'json'
    
    include Railbox::Handler

    def self.create
        # Get the associated record, e.g., a user
        record = outbox_entity.relative_entity
    
        # Make a request to an external API
        MyRequestManager.fetch(body: outbox_entity.body, headers: outbox_entity.headers)
    
        # Save a part of the response to the related entity
        record.update_column(:external_code, data["external_code"])
    end
end
```

### Handling failed transactions

You can add an `on_failure` class method to your handler:

```ruby
class MyApiHandler
  include Railbox::Handler

  def self.create
    ...
  end

  def self.on_failure
    MyTelegramNotifier.send(outbox_entity.failure_reasons)
  end
end
```

---

## How It Works

1. **Transactional Save:** Actions are queued transactionally with your business changes.
2. **Deferred Processing:** Background workers reliably process and deliver these actions.
3. **Auditable:** Every attempt, error, and retry reason is stored in the table for later inspection.
4. **Resilient:** Guaranteed exactly-once or at-least-once processing.

---

## Requirements

- Ruby >= 3.0
- Rails 7+
- PostgreSQL (recommended for advisory locking)

---

## License

MIT

---
