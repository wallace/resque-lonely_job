# Resque::Plugins::UniqueAtRuntime

[![Build Status](https://travis-ci.org/pboling/resque-unique_at_runtime.png)](https://travis-ci.org/pboling/resque-lonely\_job)

A [semanticaly versioned](http://semver.org/)
[Resque](https://github.com/resque/resque) plugin which ensures for a given
queue, that only one worker is working on a job at any given time.

Resque::Plugins::UniqueAtRuntime differs from [resque-lonely_job](https://github.com/wallace/resque-lonely_job) in that it is compatible with, and can be used at the same time as, [resque-solo](https://github.com/neighborland/resque_solo).

Resque::Plugins::UniqueAtRuntime differs from [resque_solo](https://github.com/neighborland/resque_solo) in that `resque-solo` offers **queue-time** uniqueness, while `resque-unique_at_runtime` offers **runtime** uniqueness.  The same difference applies to other queue-time uniqueness gems: [resque-queue-lock](https://github.com/mashion/resque-queue-lock), [resque-lock](https://github.com/defunkt/resque-lock).

Runtime uniqueness without queue-time uniqueness means the same job may be queued multiple times but you're guaranteed that first job queued will run to completion before subsequent jobs are run.
  
However, you can use both runtime and queue-time uniqueness together in the same project.

To use `resque-solo` and `resque-unique_at_runtime` together, with fine control of per job configuration of uniqueness at runtime and queue-time, it is recommended to use [resque-unique_by_arity](https://github.com/pboling/resque-unique_by_arity).

NOTE: There is a *strong* possibility that subsequent jobs are re-ordered due to
the implementation of
[reenqueue](https://github.com/pboling/resque-unique_at_runtime/blob/master/lib/resque-unique_at_runtime.rb#L35).
(See Example #2 for an alternative approach that attempts to preserve job
ordering but introduces the possibility of starvation.)

Therefore it is recommended that the payload for jobs be stored in a separate
redis list distinct from the Resque queue (see Example #3).

## Requirements

Requires a version of MRI Ruby >= 1.9.3.

## Installation

Add this line to your application's Gemfile:

    gem 'resque-unique_at_runtime', '~> 1.0.0'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-unique_at_runtime

## Usage

#### Example #1 -- One job running per queue

    require 'resque-unique_at_runtime'

    class StrictlySerialJob
      extend Resque::Plugins::UniqueAtRuntime

      @queue = :serial_work

      def self.perform
        # only one at a time in this block, no parallelism allowed for this
        # particular queue
      end
    end

#### Example #2 -- One job running per user-defined attribute

Let's say you want the serial constraint to apply at a more granular
level.  Instead of applying at the queue level, you can overwrite the .redis\_key
method.

    require 'resque-unique_at_runtime'

    class StrictlySerialJob
      extend Resque::Plugins::UniqueAtRuntime

      @queue = :serial_work

      # Returns a string that will be used as the redis key
      # NOTE: it is recommended to prefix your string with the 'unique_at_runtime:' to
      # namespace your key!
      def self.unique_at_runtime_redis_key(account_id, *args)
        "unique_at_runtime:strictly_serial_job:#{account_id}"
      end

      # Overwrite reenqueue to lpush instead of default rpush.  This attempts to
      # preserve job ordering but job order is *NOT* guaranteed and also not
      # likely. See the comment on SHA: e9912fb2 for why.
      def self.reenqueue(*args)
        Resque.redis.lpush("queue:#{Resque.queue_from_class(self)}", Resque.encode(class: self, args: args))
      end

      def self.perform(account_id, *args)
        # only one at a time in this block, no parallelism allowed for this
        # particular unique_at_runtime_redis_key
      end
    end

*NOTE*: Without careful consideration of your problem domain, worker starvation
and/or unfairness is possible for jobs in this example.  Imagine a scenario
where you have three jobs in the queue with two resque workers:

    +---------------------------------------------------+
    | :serial_work                                      |
    |---------------------------------------------------|
    |             |             |             |         |
    | unique_at_runtime_redis_key:  | unique_at_runtime_redis_key:  | unique_at_runtime_redis_key:  | ...     |
    |    A        |    A        |    B        |         |
    |             |             |             |         |
    | job 1       | job 2       | job 3       |         |
    +---------------------------------------------------+
                                      ^
                                      |
      Possible starvation +-----------+
      for this job and
      subsequent ones


  When the first worker grabs job 1, it'll acquire the mutex for processing
  redis\_key A.  The second worker tries to grab the next job off the queue but
  is unable to acquire the mutex for redis\_key A so it places job 2 back at the
  head of the :serial\_work queue.  Until worker 1 completes job 1 and releases
  the mutex for redis\_key A, no work will be done in this queue.

  This issue may be avoided by employing dynamic queues,
  http://blog.kabisa.nl/2010/03/16/dynamic-queue-assignment-for-resque-jobs/,
  where the queue is a one to one mapping to the redis\_key.

#### Example #3 -- One job running per user-defined attribute with job ordering preserved

The secret to preserving job order semantics is to remove critical data from the
resque job and store data in a separate redis list. Part of a running job's
responsibility will be to grab data off of the separate redis list needed for it
to complete its job.

    +---------------------------------------------------+
    | :serial_work for jobs associated with key A       |
    |---------------------------------------------------|
    |   data x    |   data y    |   data z    | ...     |
    +---------------------------------------------------+

    +---------------------------------------------------+
    | :serial_work for jobs associated with key B       |
    |---------------------------------------------------|
    |   data m    |   data n    |   data o    | ...     |
    +---------------------------------------------------+

    +---------------------------------------------------+
    | :serial_work                                      |
    |---------------------------------------------------|
    |             |             |             |         |
    | unique_at_runtime_redis_key:  | unique_at_runtime_redis_key:  | unique_at_runtime_redis_key:  | ...     |
    |    A        |    A        |    B        |         |
    |             |             |             |         |
    | job 1       | job 2       | job 3       |         |
    +---------------------------------------------------+

It now doesn't matter whether job 1 and job 2 are re-ordered as whichever goes
first will perform an atomic pop on the redis list that contains the data needed
for its job (data x, data y, data z).

#### Example #4 -- Requeue interval

The behavior when multiple jobs exist in a queue protected by resque-unique_at_runtime
is for one job to be worked, while the other is continuously dequeued and
requeued until the first job is finished.  This can result in that worker
process pegging a CPU/core on a worker server.  To guard against this, the
default behavior is to sleep for 1 second before the requeue, which will allow
the cpu to perform other work.

This can be customized using a ```@requeue_interval``` class instance variable
in your job like so:


    require 'resque-unique_at_runtime'

    class StrictlySerialJob
      extend Resque::Plugins::UniqueAtRuntime

      @queue = :serial_work
      @requeue_interval = 5         # sleep for 5 seconds before requeueing

      def self.perform
        # some implementation
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
