# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis sorted set. Closest Ruby representation is a Hash
    # where keys are elements of the set and values represent score.
    class SortedSetField < Field
      def add(hash)
        command :zadd, [key, hash_to_array(hash)]
      end

      def [](value)
        command :zscore, [key, value]
      end

      def []=(value, rank)
        command :zadd, [key, rank, value]
      end

      def size
        command :zcard, [key]
      end

      def delete(value)
        command :zrem, [key, value]
      end

      def where(score:)
        score =
          case score
          when Hash then { min: "-inf", max: "+inf" }.merge(score)
          when Numeric then { min: score, max: score }
          end

        command :zrangebyscore, [key, score[:min], score[:max]]
      end

      def first(num = 1)
        result = command :zrange, [key, 0, num - 1]
        num == 1 ? result[0] : result
      end

      def last(num = 1)
        result = command :zrevrange, [key, 0, num - 1]
        num == 1 ? result[0] : result
      end

      def to_h
        Hash[command :zrange, [key, 0, -1, with_scores: true]]
      end

      def overwrite(hash)
        redis.with do |conn|
          conn.pipelined do
            conn.del(key)
            conn.zadd(key, hash_to_array(hash))
          end
        end
      end

      private

      def hash_to_array(hash)
        ary = Array.new(hash.size * 2)

        hash.each_with_object(ary).with_index do |((value, score), result), index|
          result[index * 2] = score
          result[index * 2 + 1] = value
        end
      end
    end
  end
end
