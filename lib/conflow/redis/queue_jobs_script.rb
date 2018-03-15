# frozen_string_literal: true

module Conflow
  module Redis
    # Removes jobs from indegree set, adds them to queued list, and returns IDs of queued jobs.
    # @api private
    class QueueJobsScript < Script
      self.script = <<~LUA
        local indegree_set = KEYS[1]
        local queued_set = KEYS[2]

        local ids = redis.call('zrangebyscore', indegree_set, 0, 0)
        redis.call('zremrangebyscore', indegree_set, 0, 0)

        if #ids ~= 0 then
          redis.call('sadd', queued_set, unpack(ids))
        end

        return ids
      LUA

      class << self
        # Call the script.
        # Script removes jobs which have score 0 in Flow's indegree set and moves them to queued_jobs list.
        # @param flow [Conflow::Flow] Flow from which jobs should be enqueued
        def call(flow)
          super([flow.indegree.key, flow.queued_jobs.key])
        end
      end
    end
  end
end
