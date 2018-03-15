# frozen_string_literal: true

module Conflow
  module Redis
    # Base class for fields. All fields are assigned a Redis key.
    # @api private
    class Field
      # Redis key
      attr_reader :key
      alias id key

      # @param key [String] Redis key to store the field in
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
