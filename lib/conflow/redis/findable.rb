# frozen_string_literal: true

module Conflow
  module Redis
    # Findable module allows to use .find method on models with identifiers. It requires additional field: :type
    # @api private
    module Findable
      # Adds :type field to store class name of the Findable object
      def self.included(base)
        base.extend ClassMethods
        base.field :type, :value
      end

      # Adds logic for assigning class name as type
      def initialize(*args)
        super
        self.type = self.class.name
      end

      # Adds .find method which accepts ID and returns model of proper (sub)type
      module ClassMethods
        # Creates new {Findable} object from ID.
        # @example
        #   MyFlow.new.id #=> 13
        #   Conflow::Flow.find(13) #=> Myflow object
        def find(id)
          class_name = ValueField.new(format(key_template + ":type", id: id)).value
          raise ::Redis::CommandError, "#{name} with ID #{id} doesn't exist" unless class_name

          Object.const_get(class_name).new(id)
        end
      end
    end
  end
end
