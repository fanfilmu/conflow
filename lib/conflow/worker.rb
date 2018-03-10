# frozen_string_literal: true

module Conflow
  # It adds #perform method which accepts two parameters: flow_id and job_id and a block.
  # Block yields Class name and parameters.
  # If block returns without errors, job is considered finished.
  module Worker
    def perform(flow_id, job_id)
      job = Conflow::Job.new(job_id)
      flow = Conflow::Flow.find(flow_id)

      yield(job.worker_type, job.params).tap { |result| flow.finish(job, result) }
    end
  end
end
