# frozen_string_literal: true

module RedisHelper
  extend RSpec::SharedContext

  let(:redis) { Conflow.redis.with(&:itself) }
  after { redis.flushdb }
end
