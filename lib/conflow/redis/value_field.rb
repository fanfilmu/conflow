# frozen_string_literal: true

module Conflow
  module Redis
    # Represents Redis string
    class ValueField < Field
      def overwrite(value)
        command :set, [key, value]
      end

      def ==(other)
        case other
        when String, Symbol, Numeric then to_s == other.to_s
        when ValueField              then key == other.key || to_s == other.to_s
        else super
        end
      end

      def to_s
        command :get, [key]
      end; alias to_str to_s
    end
  end
end
