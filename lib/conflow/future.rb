# frozen_string_literal: true

module Conflow
  # Raised when future was built with nested key
  # @example
  #   job.outcome[:parent][:child] #=> raises InvalidNestedPromise
  class InvalidNestedFuture < Error
    # Sets custom message for the error
    def initialize
      super "Futures don't allow extracting nested fields"
    end
  end

  # Struct like objects that represent value to be returned by {Job}
  class Future
    # Job which result is promised
    attr_reader :job
    # Key in the result hash to which this future proxies
    attr_reader :result_key

    # @param job [Conflow::Job] Job which result is promised
    # @param result_key [String, Symbol] key under which promised value exists
    def initialize(job, result_key = nil)
      @job = job
      @result_key = result_key
    end

    # Returns new {Future} with assigned key, if possible
    # @return [Future]
    def [](key)
      raise InvalidNestedFuture if result_key
      Future.new(job, key)
    end

    # Builds promise from this future
    def build_promise(depending_job, param_key)
      Promise.new.tap do |promise|
        promise.assign_attributes(job_id: job.id, hash_field: param_key, result_key: result_key)
        depending_job.promise_ids << promise.id
      end
    end
  end
end
