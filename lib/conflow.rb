# frozen_string_literal: true

require "conflow/version"

require "digest"
require "json"
require "redis"

require "conflow/redis"
require "conflow/redis/connection_wrapper"
require "conflow/redis/field"
require "conflow/redis/value_field"
require "conflow/redis/raw_value_field"
require "conflow/redis/hash_field"
require "conflow/redis/array_field"
require "conflow/redis/sorted_set_field"
require "conflow/redis/set_field"
require "conflow/redis/field_builder"
require "conflow/redis/model"
require "conflow/redis/identifier"
require "conflow/redis/findable"

require "conflow/redis/script"
require "conflow/redis/add_job_script"
require "conflow/redis/complete_job_script"
require "conflow/redis/resolve_promises_script"
require "conflow/redis/queue_jobs_script"

require "conflow/error"
require "conflow/future"
require "conflow/promise"
require "conflow/job"
require "conflow/flow/job_builder"
require "conflow/flow/job_handler"
require "conflow/flow"
require "conflow/worker"

# Conflow allows defining comlicated workflows with dependencies.
# Inspired by {https://github.com/chaps-io/gush Gush} (the idea) and
# {https://github.com/nateware/redis-objects Redis::Objects} (the implementation) it focuses solely on dependency logic,
# while leaving queueing jobs and executing them entirely in hands of the programmer.
module Conflow
  class << self
    # Assigns Redis connection to be used by {Conflow}. It will be wrapped in ConnectionWrapper
    # for Redis instances, in order to have single API containing #with method.
    # You can also assign ConnectionPool instance.
    # @param conn [Redis, ConnectionPool] Redis connection
    # @example
    #   Conflow.redis = Redis.new
    def redis=(conn)
      @redis =
        if defined?(ConnectionPool) && conn.is_a?(ConnectionPool)
          conn
        else
          Conflow::Redis::ConnectionWrapper.new(conn)
        end
    end

    # @return [Conflow::Redis::ConnectionWrapper, ConnectionPool] Wrapped Redis connection
    def redis
      self.redis = ::Redis.current unless defined?(@redis)
      @redis
    end
  end
end
