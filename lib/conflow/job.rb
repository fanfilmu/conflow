# frozen_string_literal: true

module Conflow
  # Represents conflow job.
  # @!attribute [rw] status
  #   Status of the job
  #   @return [Integer] 0 - pending, 1 - finished
  # @!attribute [rw] class_name
  #   @return [String] class name of the worker class
  # @!attribute [rw] params
  #   @return [Hash, nil] parameters needed to complete job
  class Job < Conflow::Redis::Field
    include Conflow::Redis::Model
    include Conflow::Redis::Identifier

    has_many :successors, Conflow::Job
    has_many :promises,   Conflow::Promise
    field :params,     :hash
    field :result,     :hash
    field :class_name, :value
    field :status,     :value # 0 - pending, 1 - finished

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

    # Returns promise of this job's result. It assumes result of the job will be a Hash.
    # @note Passing a {Promise} as a job parameter automatically sets the job
    #   which produces the result as dependency of the new job
    # @return [Conflow::Future] future object (basis of {Promise})
    # @example Running job which depends on result of another
    #   job = run MyJob, params: { key: 400 }
    #   run OtherJob, params: { value: job.outcome[:result] }
    #   # now OtherJob will depend on MyJob and it will use it's :result result as it's own :value parameter
    def outcome
      Future.new(self)
    end
  end
end
