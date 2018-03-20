# frozen_string_literal: true

module Conflow
  module Redis
    # Represents single value (Redis String). Values are not serialized
    # @api private
    class RawValueField < Field
      # @param value [Object] new value to be saved
      # @return [String] Redis response
      def overwrite(value)
        command :set, [key, value]
      end

      # @return [String, nil] String representation of value
      def to_s
        value&.to_s
      end; alias to_str to_s

      # @param other [Object] Object to compare value with. Handles Strings, Symbols and other RawValueFields
      # @return [Boolean] true if equal
      def ==(other)
        case other
        when String, Symbol then value == other.to_s
        when RawValueField  then key == other.key || to_s == other.to_s
        else super
        end
      end

      # @return [Object] Value present in Redis
      def value
        command(:get, [key])
      end
    end
  end
end
