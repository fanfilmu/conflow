# frozen_string_literal: true

module Conflow
  module Redis
    # Identifier changes logic of fields so that they can be found by an id.
    # ID is a counter stored in redis under .counter_key
    # Key is build with template stored in .key_template
    # @api private
    module Identifier
      # Extends base class with {ClassMethods}
      def self.included(base)
        base.extend ClassMethods
      end

      # class methods for classes with identifier
      module ClassMethods
        # @see counter_key
        attr_writer :counter_key
        # @see key_template
        attr_writer :key_template

        # Copies *counter_key* and *key_template* to child classes
        def inherited(base)
          base.instance_variable_set("@counter_key", counter_key)
          base.instance_variable_set("@key_template", key_template)
          super
        end

        # Redis key holding counter with IDs of model.
        # @example default key
        #   class My::Super::Class < Conflow::Redis::Field
        #     include Conflow::Redis::Identifier
        #   end
        #
        #   My::Super::Class.counter_key #=> "my:super:class:idcnt"
        # @return [String] Redis key
        def counter_key
          @counter_key ||= [*name.downcase.split("::"), :idcnt].join(":")
        end

        # Template for building keys for fields using only the ID.
        # @example default key
        #   class My::Super::Class < Conflow::Redis::Field
        #     include Conflow::Redis::Identifier
        #   end
        #
        #   My::Super::Class.key_template #=> "my:super:class:%<id>d"
        # @return [String] Template for building redis keys
        def key_template
          @key_template ||= [*name.downcase.split("::"), "%<id>d"].join(":")
        end

        # @return [Integer] next available ID
        def generate_id
          Conflow.redis.with { |conn| conn.incr(counter_key) }
        end
      end

      # ID of the model
      attr_reader :id

      # Overrides logic of {Field#initialize}, allowing creating objects with ID instead of full key
      # @param id [Integer] ID of the model
      def initialize(id = self.class.generate_id)
        @id = id.to_i
        super(format(self.class.key_template, id: id))
      end
    end
  end
end
