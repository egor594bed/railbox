module Railbox
  module Exceptions
    # Raised when provided options or arguments are invalid for outbox creation.
    class ValidationError < StandardError; end
  end
end
