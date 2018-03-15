# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis sorted set. Closest Ruby representation is a Hash
    # where keys are elements of the set and values represent score.
    # @api private
    class SortedSetField < Field
      # Adds one or more keys to the set.
      # @param hash [Hash] hash of values and scores to be added
      # @return [String] Redis response
      #
      # @example Adding multiple fields
      #   field.add(last: 10, tied: 2, second: 4, first: 2)
      def add(hash)
        command :zadd, [key, hash_to_array(hash)]
      end

      # Access score of given element.
      # @param value [String, Symbol] element of the set
      # @return [String] Score of the element (nil if element not present in set)
      #
      # @example
      #   field[:last] #=> 10
      def [](value)
        command :zscore, [key, value]
      end

      # Number of elements in the set
      # @return [Integer] Size of the set
      #
      # @example
      #   field.size #=> 4
      def size
        command :zcard, [key]
      end

      # Remove element from the set.
      # @param value [String, Symbol] element of the set
      # @return [Integer] Number of removed elements (1 if key existed, 0 otherwise)
      #
      # @example
      #   field.delete(:last) #=> 1
      def delete(value)
        command :zrem, [key, value]
      end

      # Creates regular Ruby Hash based on Redis values.
      # @return [Hash] Hash representing this Sorted set
      def to_h
        Hash[command :zrange, [key, 0, -1, with_scores: true]]
      end

      # Removes old values from the set and overrides them with new.
      # @param hash [Hash] new values of the set
      # @return [String] Redis response
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
