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

    # Create new flow with given parameters
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
      new.tap { |flow| flow.configure(*args) }
    end

    # @abstract
    # Override this method in order to contain your flow definition inside the class.
    # This method will be called if flow is created using {.create} method.
    def configure(*args); end
  end
end
