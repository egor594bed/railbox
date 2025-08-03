module Railbox
  module Workers
    class BaseWorker < ::ActiveJob::Base
      queue_as :default

      def with_lock
        lock_id  = Zlib.crc32(self.class.name, 0)
        lock_sql = "SELECT pg_try_advisory_lock(#{lock_id}) AS locked"

        result = ActiveRecord::Base.connection.execute(lock_sql)
        locked = result.first['locked'] unless result.nil?

        unless locked
          Rails.logger.info "Another #{self.class.name} work now."
          return
        end

        yield

      ensure
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_unlock(#{lock_id})")
      end
    end
  end
end
