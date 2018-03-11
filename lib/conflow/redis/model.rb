# frozen_string_literal: true

module Conflow
  module Redis
    # Models adds .field method which allows to define fields easily.
    module Model
      # Extends base class with .field and .has_many methods
      def self.included(base)
        base.extend(ClassMethods)
      end

      # - if other object is a {Model} as well, it compares keys
      # - standard Ruby comparison otherwise
      # @return [Boolean] true if other is the same model, false otherwise
      def ==(other)
        other.is_a?(Model) ? key == other.key : super
      end

      # Removes this and all related models.
      # @param execute [Boolean] if false, only returns keys that would be removed
      def destroy!(execute: true)
        keys = self.class.fields.map { |name| send(name).key }
        related_keys = self.class.relations.map(&method(:collect_relation_keys))

        (keys + related_keys).flatten.tap do |key_list|
          command :del, [key_list] if execute && key_list.any?
        end
      end

      private

      def collect_relation_keys(relation)
        send(relation).map { |object| object.destroy!(execute: false) }
      end

      # Methods for defining fields on model
      module ClassMethods
        # Maps types (option for {Conflow::Redis::Model::ClassMethods#field}) to specific type field
        ALLOWED_TYPES = {
          hash:       Conflow::Redis::HashField,
          array:      Conflow::Redis::ArrayField,
          value:      Conflow::Redis::ValueField,
          sorted_set: Conflow::Redis::SortedSetField,
          set:        Conflow::Redis::SetField
        }.freeze

        # Copies field and relations information
        def inherited(subclass)
          subclass.instance_variable_set("@fields", fields.dup)
          subclass.instance_variable_set("@relations", relations.dup)
        end

        # Defines Redis field accessors.
        # @param name [Symbol] name of the field
        # @param type [:hash, :array, :value, :sorted_set, :set] type of the new field
        #
        # @see Conflow::Redis::HashField
        # @see Conflow::Redis::ArrayField
        # @see Conflow::Redis::ValueField
        # @see Conflow::Redis::SortedSetField
        # @see Conflow::Redis::SetField
        # @example
        #   model_class.field :data, :hash
        #   instance = model_class.new
        #   instance.hash["something"] = 800
        #   instance.hash = { something: "else"}
        #   instance.hash["something"] #=> "else"
        def field(name, type)
          type_class = ALLOWED_TYPES[type]
          raise ArgumentError, "Unknown type: #{type}. Should be one of: #{ALLOWED_TYPES.keys.inspect}" unless type_class

          fields << name
          FieldBuilder.new(name, type_class).call(self)
        end

        # Convienience method for defining relation-like accessor.
        # @example
        #   has_many :jobs, Conflow::Job # defines #job_ids and #jobs
        def has_many(name, klass, field_name: "#{name.to_s.chop}_ids")
          field(field_name, :array)
          relations << name
          define_method(name) { send(field_name).map { |id| klass.new(id) } }
        end

        # @return [Array<Symbol>] fields defined on this class
        def fields
          @fields ||= []
        end

        # @return [Array<Symbol>] relations defined on this class
        def relations
          @relations ||= []
        end
      end
    end
  end
end
