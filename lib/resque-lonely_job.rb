require 'resque-lonely_job/version'

module Resque
  module Plugins
    module LonelyJob
      LOCK_TIMEOUT = 60 * 60 * 24 * 5 # 5 days

      def lock_timeout
        Time.now.to_i + LOCK_TIMEOUT + 1
      end

      # Overwrite this method to uniquely identify which mutex should be used
      # for a resque worker.
      def redis_key(*args)
        "lonely_job:#{@queue}"
      end

      def can_lock_queue?(*args)
        now = Time.now.to_i
        key = redis_key(*args)
        timeout = lock_timeout

        # Per http://redis.io/commands/setnx
        return true  if Resque.redis.setnx(key, timeout)
        return false if Resque.redis.get(key).to_i > now
        return true  if Resque.redis.getset(key, timeout).to_i <= now
        return false
      end

      def unlock_queue(*args)
        Resque.redis.del(redis_key(*args))
      end

      # Unfortunately, there's not a Resque interface for lpush so we have to
      # role our own.  This is based on Resque.push but we don't need to
      # call Resque.watch_queue as the queue should already exist if we're
      # unable to get the lock.
      def reenqueue(*args)
        Resque.enqueue(self, *args)
      end

      def before_perform(*args)
        unless can_lock_queue?(*args)
          # can't get the lock, so re-enqueue the task
          reenqueue(*args)

          # and don't perform
          raise Resque::Job::DontPerform
        end
      end

      def around_perform(*args)
        begin
          yield
        ensure
          unlock_queue(*args)
        end
      end
    end
  end
end
