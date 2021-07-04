# coding: utf-8
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
          instance_variable_get(:@runtime_lock_timeout) ||
              instance_variable_set(:@runtime_lock_timeout, Resque::UniqueAtRuntime.configuration&.lock_timeout)
        end

        def runtime_requeue_interval
          instance_variable_get(:@runtime_requeue_interval) ||
              instance_variable_set(:@runtime_requeue_interval, Resque::UniqueAtRuntime.configuration&.requeue_interval)
        end

        def unique_at_runtime_key_base
          instance_variable_get(:@unique_at_runtime_key_base) ||
              instance_variable_set(:@unique_at_runtime_key_base, Resque::UniqueAtRuntime.configuration&.unique_at_runtime_key_base)
        end

        # Overwrite this method to uniquely identify which mutex should be used
        # for a resque worker.
        def unique_at_runtime_redis_key(*_)
          Resque::UniqueAtRuntime.debug("getting key for #{@queue}!")
          @queue
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

          Resque::UniqueAtRuntime.debug("attempting to lock queue with #{key}")

          # Per http://redis.io/commands/hsetnx
          return false if Resque.redis.hsetnx(unique_at_runtime_key_base, key, timeout)
          previous_timeout = Resque.redis.hget(unique_at_runtime_key_base, key).to_i
          return key if previous_timeout > now
          Resque.redis.hset(unique_at_runtime_key_base, key, timeout)
          return false if previous_timeout <= now

          key
        end

        def unlock_queue(*args)
          key = unique_at_runtime_redis_key(*args)
          Resque::UniqueAtRuntime.debug("unlock queue with #{key}")
          Resque.redis.hdel(unique_at_runtime_key_base, key)
        end

        def reenqueue(*args)
          Resque.enqueue(self, *args)
        end

        def before_perform_lock_runtime(*args)
          if (key = queue_locked?(*args))
            Resque::UniqueAtRuntime.debug("failed to lock queue with #{key}")

            # Sleep so the CPU's rest
            sleep(runtime_requeue_interval)

            # can't get the lock, so re-enqueue the task
            reenqueue(*args)

            # and don't perform
            raise Resque::Job::DontPerform
          else
            Resque::UniqueAtRuntime.debug('check passed will perform')
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
          Resque::UniqueAtRuntime.debug('on failure unlock')
          unlock_queue(*args)
        end
      end
    end
  end
end
