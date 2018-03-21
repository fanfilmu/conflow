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
    # @api private
    # @see Conflow::Job#outcome
    def initialize(job, result_key = nil)
      @job = job
      @result_key = result_key
    end

    # Returns new {Future} with assigned key, if possible
    # @param key [Symbol, String] Key in result hash of the job that holds promised value
    # @return [Future] future object that can be used as parameter
    # @example
    #   job = run AJob #=> returns { email: "test@example.com" }
    #   job.outcome[:email] # when resolved, will return "test@example.com"
    def [](key)
      raise InvalidNestedFuture if result_key
      Future.new(job, key)
    end

    # Builds promise from this future
    # @api private
    # @param depending_job [Conflow::Job] job which will use new promise
    # @param param_key [Symbol, String] key in result hash that holds promised value
    # @return [Conflow::Promise] promise object
    def build_promise(depending_job, param_key)
      Promise.new.tap do |promise|
        promise.assign_attributes(job_id: job.id, hash_field: param_key, result_key: result_key)
        depending_job.promise_ids << promise.id
      end
    end
  end
end
