# frozen_string_literal: true

module Conflow
  module Redis
    # Adds new job to flow
    # @api private
    class CompleteJobScript < Script
      self.script = <<~LUA
        local indegree_set = KEYS[1]
        local queued_jobs = KEYS[2]
        local job_key = KEYS[3]
        local job_id = ARGV[1]

        local successors = redis.call('lrange', job_key .. ':successor_ids', 0, -1)

        for i=1,#successors do
          redis.call('zincrby', indegree_set, -1, successors[i])
        end

        redis.call('srem', queued_jobs, job_id)
        return redis.call('set', job_key .. ':status', '1')
      LUA

      class << self
        # Call the script.
        # Script changes {Conflow::Flow#indegree} of all of its successors by -1 (freeing them to be queued if it
        # reaches 0) and sets {Conflow::Job#status} to 1 (finished)
        # @param flow [Conflow::Flow] Flow to which job belongs to
        # @param job [Conflow::Job] Job to be marked as completed
        def call(flow, job)
          super([flow.indegree.key, flow.queued_jobs.key, job.key], [job.id])
        end
      end
    end
  end
end
