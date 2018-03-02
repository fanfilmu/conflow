# frozen_string_literal: true

module RedisHelper
  extend RSpec::SharedContext

  let(:redis) { Redis.new }

  before { Conflow.redis = redis }
  after { redis.flushdb }
end
