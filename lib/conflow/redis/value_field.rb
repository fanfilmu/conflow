# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis string
    class ValueField < Field
      def overwrite(value)
        command :set, [key, JSON.dump(value)]
      end

      def default(value)
        command :set, [key, JSON.dump(value), nx: true]
      end

      def ==(other)
        case other
        when String, Numeric then value == other
        when Symbol          then value.to_sym == other
        when ValueField      then key == other.key || to_s == other.to_s
        else super
        end
      end

      def nil?
        value.nil?
      end

      def to_s
        value&.to_s
      end; alias to_str to_s

      def value
        result = command(:get, [key])
        result && JSON.parse(result)
      end
    end
  end
end
