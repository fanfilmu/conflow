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
        build_job(job_class, params, hook).tap do |job|
          job_classes[job_class] = job
          after = prepare_dependencies(after)

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

      def prepare_dependencies(dependencies)
        case dependencies
        when Enumerable then dependencies.map(&method(:prepare_dependency))
        else [prepare_dependency(dependencies)]
        end
      end

      def prepare_dependency(dependency)
        case dependency
        when Conflow::Job    then dependency
        when Class           then job_classes[dependency]
        when String, Numeric then Conflow::Job.new(dependency)
        end
      end

      def job_classes
        @job_classes ||= {}
      end
    end
  end
end
