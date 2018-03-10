# frozen_string_literal: true

module Conflow
  module Redis
    # Adds new job to flow
    class CompleteJobScript < Script
      # script accepts keys: flow.indegree_set and job_id
      # It will change status of the job and update dependencies
      self.script = <<~LUA
        local indegree_set = KEYS[1]
        local job_id = KEYS[2]

        local successors = redis.call('lrange', job_id .. ':successor_ids', 0, -1)

        for i=1,#successors do
          redis.call('zincrby', indegree_set, -1, successors[i])
        end

        return redis.call('set', job_id .. ':status', '1')
      LUA

      class << self
        def call(flow, job)
          super([flow.indegree.key, job.key])
        end
      end
    end
  end
end
