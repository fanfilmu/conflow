# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis list. It's methods mirror most used Array methods.
    # @api private
    class ArrayField < Field
      include Enumerable

      # @return [Integer] number of elements in list
      def size
        command :llen, [key]
      end

      # @return [Array] Ruby Array representation of Redis list
      def to_a
        command :lrange, [key, 0, -1]
      end; alias to_ary to_a

      # @param values [String...] one or more values to be added to the list
      # @return [String] Redis response
      def push(*values)
        command :rpush, [key, values]
      end; alias << push

      # Replace contents of Redis list
      # @param new_array [Array] array of new values
      def overwrite(new_array)
        redis.with do |conn|
          conn.pipelined do
            conn.del(key)
            conn.rpush(key, new_array)
          end
        end
      end

      # Iterates over list
      # @see to_a
      def each(&block)
        to_a.each(&block)
      end

      # @param other [Object] Object to compare value with. Handles Arrays and other {ArrayField} objects
      # @return [Boolean] true if equal
      def ==(other)
        case other
        when Array      then to_a == other
        when ArrayField then key == other.key || to_a == other.to_a
        else super
        end
      end

      # String representation of the list
      # @see to_a
      def to_s
        to_a.to_s
      end
    end
  end
end
