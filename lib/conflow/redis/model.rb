# frozen_string_literal: true

module Conflow
  module Redis
    # Models adds .field method which allows to define fields easily.
    module Model
      def field(name, type)
        case type
        when :hash  then FieldBuilder.new(name, Conflow::Redis::HashField).call(self)
        when :array then FieldBuilder.new(name, Conflow::Redis::ArrayField).call(self)
        when :value then FieldBuilder.new(name, Conflow::Redis::ValueField).call(self)
        else raise ArgumentError, "Unknown type: #{type}. Should be one of: [:hash, :array]"
        end
      end
    end
  end
end
