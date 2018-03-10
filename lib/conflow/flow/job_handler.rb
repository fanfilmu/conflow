# frozen_string_literal: true

module Conflow
  class Flow < Conflow::Redis::Field
    # Handles running and finishing jobs
    module JobHandler
      def run(job_class, params: {}, after: [], hook: nil)
        build_job(job_class, params, hook).tap do |job|
          call_script(Conflow::Redis::AddJobScript, job, after: after)
        end
      end

      def finish(job, result = nil)
        send(job.hook.to_s, result) unless job.hook.nil?
        call_script(Conflow::Redis::CompleteJobScript, job)
      end

      private

      def queue_available_jobs
        indegree.delete_if(score: 0).each do |job_id|
          queue Conflow::Job.new(job_id)
        end
      end

      def build_job(job_class, params, hook)
        Conflow::Job.new.tap do |job|
          job.params = params if params.any?
          job.hook = hook if hook
          job.class_name = job_class.name
        end
      end

      def call_script(script, *args)
        script.call(self, *args)
        queue_available_jobs
      end
    end
  end
end
