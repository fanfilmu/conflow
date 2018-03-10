# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis hash. It's methods mirror most used Hash methods.
    class HashField < Field
      include Enumerable

      def [](field)
        value = command(:hget, [key, field])
        value ? JSON.parse(value) : value
      end

      def []=(field, value)
        command :hset, [key, field, JSON.dump(value)]
      end

      def merge(hash)
        command :hmset, [key, hash.flatten]
      end

      def delete(*fields)
        command :hdel, [key, fields]
      end

      def overwrite(new_hash)
        new_hash.transform_values! { |value| value && JSON.dump(value) }

        redis.with do |conn|
          conn.pipelined do
            conn.del(key)
            conn.hmset(key, new_hash.flatten)
          end
        end
      end

      def keys
        command(:hkeys, [key]).map(&:to_sym)
      end

      def size
        command :hlen, [key]
      end

      def to_h
        command(:hgetall, [key]).each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = JSON.parse(value)
        end
      end

      def each(&block)
        to_h.each(&block)
      end

      def ==(other)
        case other
        when Hash      then to_h == other
        when HashField then key == other.key || to_h == other.to_h
        else super
        end
      end

      def to_s
        to_h.to_s
      end
    end
  end
end
