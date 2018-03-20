# frozen_string_literal: true

module Conflow
  module Redis
    # Resolves job's promises
    # @api private
    class ResolvePromisesScript < Script
      self.script = <<~LUA
        local pairs = {}

        for i=1, #ARGV, 3 do
          local result_field = redis.call('get', ARGV[i])
          local field_name = redis.call('get', ARGV[i + 1])
          local result_hash_key = ARGV[i + 2]

          table.insert(pairs, field_name)
          table.insert(pairs, redis.call('hget', result_hash_key, result_field) or '""')
        end

        return redis.call('hmset', KEYS[1], unpack(pairs))
      LUA

      class << self
        # @param job [Conflow::Job] Job which needs promises to be resolved
        def call(_flow, job)
          promises = extract_keys(job.promises)
          super([job.params.key], promises) if promises.any?
        end

        private

        def extract_keys(promises)
          promises.flat_map do |promise|
            [promise.result_key.key, promise.hash_field.key, Conflow::Job.new(promise.job_id.value).result.key]
          end
        end
      end
    end
  end
end
