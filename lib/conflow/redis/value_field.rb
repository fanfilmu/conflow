# frozen_string_literal: true

module Conflow
  module Redis
    # Represents single value (Redis String). Values are serialized as JSON in order to preserve type.
    # @api private
    class ValueField < Field
      # @note *value* must be serializable through JSON.dump
      # @param value [Object] new value to be saved
      # @return [String] Redis response
      def overwrite(value)
        command :set, [key, JSON.dump(value)]
      end

      # @note *value* must be serializable through JSON.dump
      # @param value [Object] value to be assigned to field (unless key already holds value)
      # @return [String] Redis response
      def default(value)
        command :set, [key, JSON.dump(value), nx: true]
      end

      # @param other [Object] Object to compare value with. Handles Strings, Numerics,
      #   Symbols and other {ValueField} objects
      # @return [Boolean] true if equal
      def ==(other)
        case other
        when String, Numeric then value == other
        when Symbol          then value.to_sym == other
        when ValueField      then key == other.key || to_s == other.to_s
        else super
        end
      end

      # @return [Boolean] true if object does not exist in Redis, else otherwise
      def nil?
        value.nil?
      end

      # @return [String, nil] String representation of value
      def to_s
        value&.to_s
      end; alias to_str to_s

      # @return [Object] JSON-parsed value present in Redis
      def value
        result = command(:get, [key])
        result && JSON.parse(result)
      end
    end
  end
end
