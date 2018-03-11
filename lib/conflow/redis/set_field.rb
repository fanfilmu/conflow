# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis list. It's methods mirror most used Set methods.
    class SetField < Field
      include Enumerable

      # Adds one or more elements to the set.
      # @param values [String] list of values to be added
      # @return [String] Redis response
      #
      # @example Adding multiple fields
      #   field.add(:last, :first, :other, :first)
      def add(*values)
        command :sadd, [key, values]
      end

      # Removes old values from the set and overrides them with new.
      # @param enumerable [Enumerable] new values of the set
      # @return [String] Redis response
      def overwrite(enumerable)
        redis.with do |conn|
          conn.pipelined do
            conn.del(key)
            conn.sadd(key, enumerable)
          end
        end
      end

      # Returns array with set values
      # @return [Array] values from the set
      def to_a
        command :smembers, [key]
      end; alias to_ary to_a
    end
  end
end
