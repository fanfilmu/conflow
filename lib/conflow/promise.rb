# frozen_string_literal: true

module Conflow
  # Promises are stubs for returned values from jobs. They will be resolved once the job is done.
  class Promise < Conflow::Redis::Field
    include Conflow::Redis::Model
    include Conflow::Redis::Identifier

    # @!attribute [rw] job_id
    #   ID of the job that promised result
    #   @return [Conflow::Redis::ValueField] ID of {Conflow::Job}
    field :job_id,     :raw_value
    # @!attribute [rw] key
    #   Key of job's result which is promised
    #   @return [Conflow::Redis::ValueField] Name of the key
    field :result_key, :raw_value
    # @!attribute [rw] hash_field
    #   Redis field name in the result hash
    #   @return [Conflow::Redis::ValueField] Name of the field
    field :hash_field, :raw_value
  end
end
