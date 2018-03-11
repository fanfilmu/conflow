# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis sorted set. Closest Ruby representation is a Hash
    # where keys are elements of the set and values represent score.
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

      # Set score of given element.
      # @param value [String, Symbol] element of the set
      # @param rank [Numeric] score to be assigned
      # @return [Integer] Number of added elements (1 if key didn't exist, 0 otherwise)
      #
      # @example
      #   field[:last] = 24 #=> 0
      def []=(value, rank)
        command :zadd, [key, rank, value]
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

      # Return elements with given score
      # @param score [Numeric, Hash]
      #   - when Numeric, only elements with that exact score will be returned
      #   - when Hash, elements within min..max range will be returned. See {https://redis.io/commands/zrange Redis docs}
      # @option score [String, Numeric] :min minimal score
      # @option score [String, Numeric] :max maximal score
      # @return [Array<String>] Elements with given score
      #
      # @example with specific score
      #   field.where(score: 2) #=> ["first", "tie"]
      # @example with only min set
      #   field.where(score: { min: 3 }) #=> ["last", "second"]
      # @example with both min and max set
      #   field.where(score: { min: 3, max: "(10" }) #=> ["last"]
      def where(score:)
        command :zrangebyscore, [key, *prepare_score_bounds(score)]
      end

      # Removes elements of the set with given score and returns them.
      # See {where} for details on how to choose score.
      # @return [Array<String>] Elements with given score
      def delete_if(score:)
        score_bounds = prepare_score_bounds(score)

        transaction do |conn|
          conn.zrangebyscore key, *score_bounds
          conn.zremrangebyscore key, *score_bounds
        end[0]
      end

      # Returns first *n* elements of the sorted set
      # @param num [Integer] amount of elements to be returned. Defaults to 1.
      # @return [String, Array<String>] first *num* elements from the set
      def first(num = 1)
        result = command :zrange, [key, 0, num - 1]
        num == 1 ? result[0] : result
      end

      # Returns last *n* elements of the sorted set
      # @param num [Integer] amount of elements to be returned. Defaults to 1.
      # @return [String, Array<String>] last *num* elements from the set
      def last(num = 1)
        result = command :zrevrange, [key, 0, num - 1]
        num == 1 ? result[0] : result
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

      def prepare_score_bounds(score)
        case score
        when Hash    then { min: "-inf", max: "+inf" }.merge(score).values
        when Numeric then [score, score]
        end
      end
    end
  end
end
