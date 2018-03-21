# frozen_string_literal: true

module Conflow
  class Flow < Conflow::Redis::Field
    # Handles creating jobs
    class JobBuilder
      # used to map class names to jobs
      attr_reader :context

      # Initializes new builder with empty context
      def initialize
        @context = {}
      end

      # builds job with proper parameters
      def call(worker_class, params, dependencies, hook)
        job = initialize_job(worker_class)
        assign_job_attributes(job, params, hook)

        [job, build_dependencies(dependencies)]
      end

      private

      def initialize_job(worker_class)
        Conflow::Job.new.tap do |job|
          job.class_name = worker_class.name
          context[worker_class] = job
        end
      end

      def assign_job_attributes(job, params, hook)
        job.hook = hook if hook
        job.params = params if params.any?
      end

      def build_dependencies(dependencies)
        prepare_dependencies(dependencies).compact.uniq
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
        when Class           then context[dependency]
        when String, Numeric then Conflow::Job.new(dependency)
        end
      end
    end
  end
end
