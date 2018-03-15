# frozen_string_literal: true

module Conflow
  module Redis
    # Adds new job to flow
    # @api private
    class AddJobScript < Script
      # script accepts keys: flow.job_ids, flow.indegree, and keys successors of the jobs on which new job depends.
      # It also accepts one argument: id of the new job
      self.script = <<~LUA
        local job_list = KEYS[1]
        local indegree_set = KEYS[2]
        local job_id = ARGV[1]
        local score = 0

        for i=3,#KEYS do
          if redis.call('get', KEYS[i] .. ':status') == '0' then
            score = score + 1
            redis.call('lpush', KEYS[i] .. ':successor_ids', job_id)
          end
        end

        redis.call('lpush', job_list, job_id)
        return redis.call('zadd', indegree_set, score, job_id)
      LUA

      class << self
        # Call the script.
        # Script changes {Conflow::Flow#indegree} of all of its successors by -1 (freeing them to be queued if it
        # reaches 0) and sets {Conflow::Job#status} to 1 (finished)
        def call(flow, job, after: [])
          super([flow.job_ids.key, flow.indegree.key, *after.map(&:key)], [job.id])
        end
      end
    end
  end
end
