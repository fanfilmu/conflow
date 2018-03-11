# frozen_string_literal: true

module Conflow
  module Redis
    # Main class for scripts, handling logic of executing and caching scripts.
    class Script
      class << self
        # @return [Boolean] whether scripts are cached or not
        attr_reader :cache_scripts
        # @return [String] LUA script of this Conflow::Redis::Script
        attr_reader :script

        # Sets cache_scripts option on inherited scripts
        def inherited(base)
          scripts << base
          base.cache_scripts = cache_scripts
          super
        end

        # @!attribute [rw] cache_scripts
        #   This options decides whether scripts used by the gem will be cached in Redis or not.
        #   See {https://redis.io/commands/eval Redis EVAL} and {https://redis.io/commands/evalsha Redis EVALSHA}.
        #   @example Disable caching scripts (set this in your initializer)
        #     Conflow::Redis::Script.cache_scripts = false
        def cache_scripts=(value)
          @cache_scripts = value

          @command = value ? :sha_eval : :eval
          scripts.each { |script_class| script_class.cache_scripts = cache_scripts }
        end

        # Executes script in Redis with given arguments.
        #
        # @overload call(keys, args = [])
        #   @param keys [Array<String>] Array of keys
        #   @param args [Array<Object>] Array of arguments of the script
        def call(*args)
          Conflow.redis.with { |conn| send(command, conn, args) }
        end

        private

        attr_reader :command, :sha

        def script=(script)
          @script = script
          @sha = Digest::SHA1.hexdigest(script)
        end

        def scripts
          @scripts ||= []
        end

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
