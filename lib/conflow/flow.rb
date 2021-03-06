# frozen_string_literal: true

module Conflow
  # Flow is a set of steps needed to complete certain task. It is composed of jobs
  # which have dependency relations with one another.
  #
  # {Conflow::Flow} class is designed to be inherited in your application. You must supply {queue} method
  #
  # @!attribute [r] jobs
  #   Read-only array of jobs added to the flow.
  #   @return [Array<Conflow::Job>] List of jobs in the flow
  #
  # @!attribute [rw] indegree
  #   Sorted set (Redis zset) of job ids. Each job has a score attached, which is the number of "indegree" nodes -
  #   the nodes on which given job depends. This changes dynamically and score equal to 0 means that all dependencies
  #   are fulfilled.
  #   @return [Conflow::Redis::SortedSetField] Set of jobs to be performed
  #
  # @!attribute [r] queued_jobs
  #   Set of jobs that are currently queued (and not yet finished).
  #   @return [Conflow::Redis::SetField] Set of queued jobs
  #
  # @!method queue(job)
  #   @abstract
  #   Queues job to be performed. Both id of the flow and id of the job must be preserved
  #   in order to recreate job in worker.
  #   @param job [Conflow::Job] job to be queued
  #
  #   @example Queue sidekiq job
  #     class MyBaseFlow < Conflow::Flow
  #       def queue(job)
  #         Sidekiq::Client.enqueue(FlowWorkerJob, id, job.id)
  #       end
  #     end
  class Flow < Conflow::Redis::Field
    include Conflow::Redis::Model
    include Conflow::Redis::Identifier
    include Conflow::Redis::Findable
    include JobHandler

    has_many :jobs, Conflow::Job
    field :queued_jobs, :set
    field :indegree,    :sorted_set
    field :lock,        :value

    # Create new flow with given parameters
    # @param args [Array<Object>] any parameters that will be passed to {#configure} method
    # @return [Conflow::Job] job object representing created job
    # @example Simple configurable flow
    #   class MyFlow < Conflow::Flow
    #     def configure(id:, strict:)
    #       run UpsertJob, params: { id: id }
    #       run CheckerJob, params: { id: id } if strict
    #     end
    #   end
    #
    #   MyFlow.create(id: 320, strict: false)
    #   MyFlow.create(id: 15, strict: true)
    def self.create(*args)
      new.tap do |flow|
        flow.with_lock do
          flow.configure(*args)
        end
      end
    end

    # Returns whether or not the flow is finished (all jobs were processed)
    # @return [Boolean] true if no pending jobs
    def finished?
      lock.value != 1 && queued_jobs.size.zero? && indegree.size.zero?
    end

    # @abstract
    # Override this method in order to contain your flow definition inside the class.
    # This method will be called if flow is created using {.create} method.
    # @param args [Array<Object>] any arguments needed to start a flow
    # @see create
    def configure(*args); end

    # Lock prevents flow from enqueuing jobs during configuration - it could happen that first job is finished
    # before second is enqueued, therefore "finishing" the flow.
    # @api private
    def with_lock
      self.lock = 1
      yield
      self.lock = 0
      queue_available_jobs
    end
  end
end
