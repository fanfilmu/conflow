# frozen_string_literal: true

module Conflow
  module Redis
    # Wraps Redis connection to behave like connection pool
    class ConnectionWrapper
      # @param redis [Redis] Redis connection to be wrapped
      def initialize(redis)
        @redis = redis
      end

      # Allows accessing Redis connection
      # @yieldparam [Redis] redis connection
      def with
        yield @redis
      end
    end
  end
end
