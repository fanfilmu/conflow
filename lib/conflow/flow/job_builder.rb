# frozen_string_literal: true

module Conflow
  class Flow < Conflow::Redis::Field
    # Handles creating jobs
    class JobBuilder
      attr_reader :context

      def initialize
        @context = {}
      end

      def call(worker_class, params, dependencies, hook)
        job = initialize_job(worker_class)

        promises, params = extract_promises(job, params)
        dependencies = build_dependencies(promises, dependencies)
        assign_job_attributes(job, promises, params, hook)

        [job, dependencies]
      end

      private

      def initialize_job(worker_class)
        Conflow::Job.new.tap do |job|
          job.class_name = worker_class.name
          context[worker_class] = job
        end
      end

      def assign_job_attributes(job, promises, params, hook)
        job.hook = hook if hook
        job.params = params if params.any?
        job.promise_ids.push(*promises.map(&:id)) if promises.any?
      end

      def extract_promises(job, params)
        params = params.dup

        promises = params.map do |key, value|
          next unless value.is_a?(Conflow::Future)

          params.delete(key)
          value.build_promise(job, key)
        end.compact

        [promises, params]
      end

      def build_dependencies(promises, dependencies)
        promise_jobs = promises.map { |promise| Conflow::Job.new(promise.job_id.value) }
        dependencies = prepare_dependencies(dependencies)

        (promise_jobs + dependencies).compact.uniq
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
