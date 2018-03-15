# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis list. It's methods mirror most used Array methods.
    class ArrayField < Field
      include Enumerable

      def size
        command :llen, [key]
      end

      def to_a
        command :lrange, [key, 0, -1]
      end; alias to_ary to_a

      def push(*values)
        command :rpush, [key, values]
      end; alias << push

      def overwrite(new_array)
        redis.with do |conn|
          conn.pipelined do
            conn.del(key)
            conn.rpush(key, new_array)
          end
        end
      end

      def each(&block)
        to_a.each(&block)
      end

      def ==(other)
        case other
        when Array      then to_a == other
        when ArrayField then key == other.key || to_a == other.to_a
        else super
        end
      end

      def to_s
        to_a.to_s
      end
    end
  end
end
