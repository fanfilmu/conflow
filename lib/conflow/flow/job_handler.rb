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
      # @param hook [Symbol] method to be called on {Conflow::Flow} instance after job is performed.
      #   The hook method should accept result of the job (value returned by {Conflow::Worker#perform})
      # @return [Conflow::Job] enqueued job
      def run(job_class, params: {}, after: [], hook: nil)
        job, dependencies = job_builder.call(job_class, params, after, hook)

        call_script(Conflow::Redis::AddJobScript, job, after: dependencies)
        queue_available_jobs

        job
      end

      # Starts the job - resolves it's promises
      def start(job)
        call_script(Conflow::Redis::ResolvePromisesScript, job)
      end

      # Finishes job, changes its status, runs hook if it's present and queues new available jobs
      # @param job [Conflow::Job] job to be marked as finished
      # @param result [Object] result of the job to be passed to hook
      def finish(job, result = nil)
        send(job.hook.to_s, result) unless job.hook.nil?
        job.result = result if result
        call_script(Conflow::Redis::CompleteJobScript, job)
        queue_available_jobs
        destroy! if finished?
      end

      private

      def queue_available_jobs
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
