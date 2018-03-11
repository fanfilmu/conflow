# frozen_string_literal: true

module Conflow
  # Represents conflow job.
  # @!attribute [rw] status
  #   Status of the job
  #   @return [Integer] 0 - pending, 1 - finished
  # @!attribute [rw] hook
  #   @return [String, nil] name of the method on related flow to be called once job is finished
  # @!attribute [rw] class_name
  #   @return [String] class name of the worker class
  # @!attribute [rw] params
  #   @return [Hash, nil] parameters needed to complete job
  class Job < Conflow::Redis::Field
    include Conflow::Redis::Model
    include Conflow::Redis::Identifier

    has_many :successors, Conflow::Job
    field :params,     :hash
    field :class_name, :value
    field :status,     :value # 0 - pending, 1 - finished
    field :hook,       :value

    # Returns instance of Job. It sets status to 0 (pending) for new jobs
    def initialize(*)
      super
      status.default(0)
    end

    # Convienience method returning Class object of the job.
    # It's the class supplied in {Conflow::Flow#run} method
    # @return [Class] class of the job
    def worker_type
      Object.const_get(class_name.to_s)
    end
  end
end
