# frozen_string_literal: true

module Resque
  module Plugins
    # If you want your job to support uniqueness at runtime, simply include
    #   this module into your job class.
    #
    #   class RunAlone
    #     @queue = :run_alone
    #     include Resque::Plugins::UniqueAtRuntime
    #
    #     def self.perform(arg1, arg2)
    #       alone_stuff
    #     end
    #   end
    #
    module UniqueAtRuntime
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def runtime_lock_timeout_at(now)
          now + runtime_lock_timeout + 1
        end

        def runtime_lock_timeout
          instance_variable_get(:@runtime_lock_timeout) || Resque::UniqueAtRuntime::LOCK_TIMEOUT
        end

        def runtime_requeue_interval
          instance_variable_get(:@runtime_requeue_interval) || Resque::UniqueAtRuntime::REQUEUE_INTERVAL
        end

        # Overwrite this method to uniquely identify which mutex should be used
        # for a resque worker.
        def unique_at_runtime_redis_key(*_)
          puts "unique_at_runtime: getting key for #{@queue}!" if ENV['RESQUE_DEBUG']
          "unique_at_runtime:#{@queue}"
        end

        # returns true if the job signature can be locked (is not currently locked)
        def can_lock_queue?(*args)
          !queue_locked?(*args)
        end

        # returns the locking key if locked, otherwise false
        def queue_locked?(*args)
          now = Time.now.to_i
          key = unique_at_runtime_redis_key(*args)
          timeout = runtime_lock_timeout_at(now)

          puts "unique_at_runtime: attempting to lock queue with #{key}" if ENV['RESQUE_DEBUG']

          # Per http://redis.io/commands/setnx
          return false if Resque.redis.setnx(key, timeout)
          return key if Resque.redis.get(key).to_i > now
          return false if Resque.redis.getset(key, timeout).to_i <= now

          key
        end

        def unlock_queue(*args)
          key = unique_at_runtime_redis_key(*args)
          puts "unique_at_runtime: unlock queue with #{key}" if ENV['RESQUE_DEBUG']
          Resque.redis.del(key)
        end

        def reenqueue(*args)
          Resque.enqueue(self, *args)
        end

        def before_perform_lock_runtime(*args)
          if (key = queue_locked?(*args))
            puts "unique_at_runtime: failed to lock queue with #{key}" if ENV['RESQUE_DEBUG']

            # Sleep so the CPU's rest
            sleep(runtime_requeue_interval)

            # can't get the lock, so re-enqueue the task
            reenqueue(*args)

            # and don't perform
            raise Resque::Job::DontPerform
          else
            puts 'uniqueness check passed will perform' if ENV['RESQUE_DEBUG']
            true
          end
        end

        def around_perform_unlock_runtime(*args)
          yield
        ensure
          unlock_queue(*args)
        end

        # There may be scenarios where the around_perform's ensure unlock±
        #   duplicates the on_failure unlock, but that's a small price to pay for
        #   uniqueness.
        def on_failure_unlock_runtime(*args)
          puts 'unique_at_runtime: on failure unlock' if ENV['RESQUE_DEBUG']
          unlock_queue(*args)
        end
      end
    end
  end
end
