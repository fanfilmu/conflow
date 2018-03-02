# frozen_string_literal: true

module Conflow
  module Redis
    # Wraps Redis connection to behave like connection pool
    class ConnectionWrapper
      def initialize(redis)
        @redis = redis
      end

      def with
        yield @redis
      end
    end
  end
end
