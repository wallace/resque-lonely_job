require 'resque-lonelyjob/version'

module Resque
  module Plugins
    module Lonelyjob
      def redis_key(queue)
        "lonely_job:#{queue}"
      end

      def can_lock_queue?(queue)
        Resque.redis.setnx(redis_key(queue), true)
      end

      def unlock_queue(queue)
        Resque.redis.del(redis_key(queue))
      end

      def before_perform(*args)
        unless can_lock_queue?(@queue)
          # can't get the lock, so place self at the end of the queue
          Resque.enqueue(self, *args)

          # and don't perform
          raise Resque::Job::DontPerform
        end
      end

      def after_perform(*args)
        unlock_queue(@queue)
      end

      def on_failure(*args)
        unlock_queue(@queue)
      end
    end
  end
end
