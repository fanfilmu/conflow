# frozen_string_literal: true

module Conflow
  # It adds #perform method which accepts two parameters: flow_id and job_id and a block.
  # Block yields Class name and parameters.
  # If block returns without errors, job is considered finished.
  module Worker
    # @param flow_id [Integer] id of the flow
    # @param job_id [Integer] id of the job to be performed
    # @yieldparam worker_type [Class] class supplied on job creation
    # @yieldparam params [Hash] parameters of the job supplied on creation
    # @return [Object] result of the block execution
    #
    # @example Performing job with simple new/call pattern
    #   class FlowWorkerJob
    #     include Conflow::Worker
    #     include Sidekiq::Worker
    #
    #     def perform(flow_id, job_id)
    #       super do |worker_type, params|
    #         worker_type.new(params).call
    #       end
    #     end
    #   end
    def perform(flow_id, job_id)
      job = Conflow::Job.new(job_id)
      flow = Conflow::Flow.find(flow_id)

      flow.start(job)

      yield(job.worker_type, job.params).tap { |result| flow.finish(job, result) }
    end
  end
end
