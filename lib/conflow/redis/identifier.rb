# frozen_string_literal: true

module Conflow
  module Redis
    # Identifier changes logic of fields so that they can be found by an id.
    # ID is a counter stored in redis under .counter_key
    # Key is build with template stored in .key_template
    module Identifier
      def self.included(base)
        base.extend ClassMethods
      end

      # class methods for classes with identifier
      module ClassMethods
        attr_writer :counter_key, :key_template

        def counter_key
          @counter_key ||= [*name.downcase.split("::"), :idcnt].join(":")
        end

        def key_template
          @key_template ||= [*name.downcase.split("::"), "%<id>d"].join(":")
        end

        def generate_id
          Conflow.redis.with { |conn| conn.incr(counter_key) }
        end
      end

      attr_reader :id

      def initialize(id = self.class.generate_id)
        @id = id.to_i
        super(format(self.class.key_template, id: id))
      end
    end
  end
end
