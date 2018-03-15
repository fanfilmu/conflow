# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis hash. It's methods mirror most used Hash methods.
    # @api private
    class HashField < Field
      include Enumerable

      # Merges hashes, similar to Hash#merge
      # @param hash [Hash] hash of keys and values to be merged
      # @return [String] Redis response
      #
      # @example
      #   field.merge(smart: true, degree: :none)
      def merge(hash)
        command :hmset, [key, hash.flatten]
      end

      # Replaces currently stored hash with one given as param
      # @param new_hash [Hash] hash of keys and values to be stored
      # @return [String] Redis response
      #
      # @example
      #   field.overwrite(smart: true, degree: :none)
      def overwrite(new_hash)
        redis.with do |conn|
          conn.pipelined do
            conn.del(key)
            conn.hmset(key, prepare_hash(new_hash).flatten)
          end
        end
      end

      # Creates Ruby Hash based on soted values. Keys will be symbolized and values JSON-parsed
      # @return [String] Redis response
      #
      # @example
      #   field.to_h #=> { smart: true, degree: "none" }
      def to_h
        command(:hgetall, [key]).each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = JSON.parse(value)
        end
      end; alias to_hash to_h

      # Iterates over hash.
      # @see to_h
      # @return [Enumerator] if no block given
      def each(&block)
        to_h.each(&block)
      end

      # @param other [Object] Object to compare value with. Handles Hashes and other {HashField} objects
      # @return [Boolean] true if equal
      def ==(other)
        case other
        when Hash      then to_h == other
        when HashField then key == other.key || to_h == other.to_h
        else super
        end
      end

      # @return [String] string representation of the hash
      def to_s
        to_h.to_s
      end

      private

      def prepare_hash(hash)
        hash.each_with_object({}) do |(k, v), h|
          h[k] = v && JSON.dump(v)
        end
      end
    end
  end
end
