# frozen_string_literal: true

module FixturesHelper
  extend RSpec::SharedContext

  around do |example|
    fixtures = %i[Operation SquareRoot ThreadBasedFlow Worker]
    fixtures.each { |fixture| Object.const_set(fixture, FixturesHelper.const_get(fixture)) }

    redis.set("test_key", initial_value)

    example.run

    fixtures.each { |fixture| Object.send(:remove_const, fixture) }
  end

  let(:flow) { ThreadBasedFlow.new }

  def test_value
    redis.get("test_key").to_i
  end

  def perform_work!
    Array.new(flow.job_ids.size) { Thread.new { Worker.new.call } }.each(&:join)
  end

  class Operation
    attr_reader :operator, :number, :key, :new_value

    def initialize(operator:, number:)
      @operator = operator
      @number = number
      @key = "test_key"
    end

    def call
      sleep(rand / 10)

      Conflow.redis.with do |conn|
        result = nil
        result = perform_operation(conn) while result.nil?
      end

      { value: new_value }
    end

    private

    def perform_operation(conn)
      conn.watch(key) do
        value = conn.get key
        @new_value = value.to_i.send(operator, number)
        conn.multi { |multi| multi.set(key, new_value) }
      end
    end
  end

  class SquareRoot < Operation
    attr_reader :key, :new_value

    def initialize
      super(operator: nil, number: nil)
    end

    private

    def perform_operation(conn)
      conn.watch(key) do
        value = conn.get key
        @new_value = Math.sqrt(value.to_i)
        conn.multi { |multi| multi.set(key, new_value) }
      end
    end
  end

  class ThreadBasedFlow < Conflow::Flow
    def queue(job)
      Worker.queue << [id, job.id]
    end

    def fizz(result)
      puts "Fizz" if result[:value] % 3 == 0
    end
  end

  class Worker
    include Conflow::Worker

    def self.queue
      @queue ||= Queue.new
    end

    def call
      perform(*self.class.queue.pop) do |worker_type, parameters|
        if parameters.any?
          worker_type.new(parameters).call
        else
          worker_type.new.call
        end
      end
    end
  end
end
