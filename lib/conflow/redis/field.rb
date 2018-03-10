# frozen_string_literal: true

module Conflow
  module Redis
    # Base class for fields. All fields are assigned a Redis key.
    class Field
      attr_reader :key
      alias id key

      def initialize(key)
        @key = key
      end

      private

      def redis
        Conflow.redis
      end

      def command(command, args)
        redis.with { |conn| conn.send(command, *args) }
      end

      def transaction(max_retries: 5)
        result = redis.with do |conn|
          retryable(max_retries, conn) do
            conn.watch(key) do
              conn.multi { |multi| yield(multi) }
            end
          end
        end

        raise ::Redis::CommandError, "Transaction failed #{max_retries} times" unless result
        result
      end

      def retryable(max_retries, *args)
        loop do
          result = yield(*args)
          break result if result || max_retries.zero?
          max_retries -= 1
        end
      end
    end
  end
end
