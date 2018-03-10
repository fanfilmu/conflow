# frozen_string_literal: true

module Conflow
  class Flow < Conflow::Redis::Field
    # Handles running and finishing jobs
    module JobHandler
      def run(job_class, params: {}, after: [])
        build_job(job_class, params).tap do |job|
          call_script(Conflow::Redis::AddJobScript, job, after: after)
        end
      end

      def finish(job)
        call_script(Conflow::Redis::CompleteJobScript, job)
      end

      private

      def queue_available_jobs
        indegree.delete_if(score: 0).each do |job_id|
          queue Conflow::Job.new(job_id)
        end
      end

      def build_job(job_class, params)
        Conflow::Job.new.tap do |job|
          job.params = params if params.any?
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
