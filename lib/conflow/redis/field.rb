# frozen_string_literal: true

module Conflow
  module Redis
    # Base class for fields. All fields are assigned a Redis key.
    class Field
      attr_reader :key

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
    end
  end
end
