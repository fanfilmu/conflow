# frozen_string_literal: true

module Conflow
  module Redis
    # Helper class for defining getter and setter methods for Fields
    class FieldBuilder
      # This dynamic module contains accessor methods for a field
      class FieldAccessor < Module
        def initialize(field_name, klass, methods)
          super() do
            define_getter(field_name, klass) if methods.include?(:getter)
            define_setter(field_name) if methods.include?(:setter)
          end
        end

        def define_getter(field_name, klass)
          instance_var = "@#{field_name}"

          define_method(field_name) do
            instance_variable_get(instance_var) ||
              instance_variable_set(instance_var, klass.new([key, field_name].join(":")))
          end
        end

        def define_setter(field_name)
          define_method("#{field_name}=") do |value|
            send(field_name).tap { |field| field.overwrite(value) }
          end
        end
      end

      attr_reader :field_name, :klass

      def initialize(field_name, klass)
        @field_name = field_name
        @klass = klass
      end

      def call(base, methods: %i[getter setter])
        base.include(FieldAccessor.new(field_name, klass, methods))
      end
    end
  end
end
