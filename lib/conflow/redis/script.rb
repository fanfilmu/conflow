# frozen_string_literal: true

module Conflow
  module Redis
    # Main class for scripts, handling logic of executing and caching scripts.
    class Script
      class << self
        attr_reader :sha, :cache_scripts, :script
        attr_accessor :script_getter, :command

        def scripts
          @scripts ||= []
        end

        def inherited(base)
          scripts << base
          base.cache_scripts = cache_scripts
          super
        end

        def cache_scripts=(value)
          @cache_scripts = value

          self.command = value ? :sha_eval : :eval
          scripts.each { |script_class| script_class.cache_scripts = cache_scripts }
        end

        def script=(script)
          @script = script
          @sha = Digest::SHA1.hexdigest(script)
        end

        def call(*args)
          Conflow.redis.with { |conn| send(command, conn, args) }
        end

        private

        def sha_eval(redis, args)
          redis.evalsha(sha, *args)
        rescue ::Redis::CommandError => e
          raise unless e.message == "NOSCRIPT No matching script. Please use EVAL."
          redis.script(:load, script)
          retry
        end

        def eval(redis, args)
          redis.eval(script, *args)
        end
      end

      self.cache_scripts = true
    end
  end
end
