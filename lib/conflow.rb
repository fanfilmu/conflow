# frozen_string_literal: true

require "conflow/version"

require "redis"

require "conflow/redis/connection_wrapper"
require "conflow/redis/field"
require "conflow/redis/value_field"
require "conflow/redis/hash_field"
require "conflow/redis/array_field"
require "conflow/redis/field_builder"
require "conflow/redis/model"

module Conflow
  class << self
    attr_reader :redis

    def redis=(conn)
      @redis =
        if defined?(ConnectionPool) && conn.is_a?(ConnectionPool)
          conn
        else
          Conflow::Redis::ConnectionWrapper.new(conn)
        end
    end
  end
end
