# frozen_string_literal: true

module Conflow
  class Flow < Conflow::Redis::Field
    # Handles running and finishing jobs
    module JobHandler
      # @param job_class [Class] Class of the worker which will perform the job
      # @param params [Hash]
      #   Parameters of the job. They will be passed to {Conflow::Worker#perform} block. Defalts to empty hash.
      # @param after [Conflow::Job|Class|Integer|Array<Conflow::Job,Class,Integer>]
      #   Dependencies of the job. Can be one or more objects of the following classes: {Conflow::Job}, Class, Integer
      # @return [Conflow::Job] enqueued job
      def run(job_class, params: {}, after: [])
        job, dependencies = job_builder.call(job_class, params, after)

        call_script(Conflow::Redis::AddJobScript, job, after: dependencies)
        queue_available_jobs

        job
      end

      # Starts the job - resolves it's promises. It's called by {Worker} before it yields parameters
      # @api private
      # @see Worker
      # @param job [Conflow::Job] job that needs to resolve it's promises
      # @return [void]
      def start(job)
        call_script(Conflow::Redis::ResolvePromisesScript, job)
      end

      # Finishes job, changes its status, assigns result of the job and queues new available jobs
      # @param job [Conflow::Job] job to be marked as finished
      # @param result [Object] result of the job
      def finish(job, result = nil)
        job.result = result if result.is_a?(Hash) && result.any?
        call_script(Conflow::Redis::CompleteJobScript, job)
        queue_available_jobs
        destroy! if finished?
      end

      private

      def queue_available_jobs
        return unless lock.value != 1

        call_script(Conflow::Redis::QueueJobsScript)&.each do |job_id|
          queue Conflow::Job.new(job_id)
        end
      end

      def call_script(script, *args)
        script.call(self, *args)
      end

      def job_builder
        @job_builder ||= JobBuilder.new
      end
    end
  end
end
