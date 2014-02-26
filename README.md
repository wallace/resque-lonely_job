# Resque::LonelyJob

[![Build Status](https://travis-ci.org/wallace/resque-lonely_job.png)](https://travis-ci.org/wallace/resque-lonely\_job)

A [semanticaly versioned](http://semver.org/)
[Resque](https://github.com/resque/resque) plugin which ensures for a given
queue, that only one worker is working on a job at any given time.

Resque::LonelyJob differs from [resque-queue-lock](https://github.com/mashion/resque-queue-lock), [resque-lock](https://github.com/defunkt/resque-lock) and
[resque-loner](http://github.com/jayniz/resque-loner) in that the same job may
be queued multiple times but you're guaranteed that first job queued will run to
completion before subsequent jobs are run.

However, it is a very *strong* possibility that subsequent jobs are re-ordered due to
the implementation of
[reenqueue](https://github.com/wallace/resque-lonely_job/blob/master/lib/resque-lonely_job.rb#L35).
(See Example #2 for an alternative approach that attempts to preserve job
ordering but introduces the possibility of starvation.)

Therefore it is recommended that the payload for jobs be stored in a separate
redis list distinct from the Resque queue (see Example #3).

## Requirements

Version 1.x Requires Resque >= 1.20.0 and < 1.25.0.

Requires a version of MRI Ruby >= 1.9.3.

## Installation

Add this line to your application's Gemfile:

    gem 'resque-lonely_job', '~> 1.0.0'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-lonely_job

## Usage

#### Example #1 -- One job running per queue

    require 'resque-lonely_job'

    class StrictlySerialJob
      extend Resque::Plugins::LonelyJob

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

    require 'resque-lonely_job'

    class StrictlySerialJob
      extend Resque::Plugins::LonelyJob

      @queue = :serial_work

      # Returns a string that will be used as the redis key
      # NOTE: it is recommended to prefix your string with the 'lonely_job:' to
      # namespace your key!
      def self.redis_key(account_id, *args)
        "lonely_job:strictly_serial_job:#{account_id}"
      end

      # Overwrite reenqueue to lpush instead of default rpush.  This attempts to
      # preserve job ordering but job order is *NOT* guaranteed and also not
      # likely. See the comment on SHA: e9912fb2 for why.
      def self.reenqueue(*args)
        Resque.redis.lpush("queue:#{Resque.queue_from_class(self)}", Resque.encode(class: self, args: args))
      end

      def self.perform(account_id, *args)
        # only one at a time in this block, no parallelism allowed for this
        # particular redis_key
      end
    end

*NOTE*: Without careful consideration of your problem domain, worker starvation
and/or unfairness is possible for jobs in this example.  Imagine a scenario
where you have three jobs in the queue with two resque workers:

    +---------------------------------------------------+
    | :serial_work                                      |
    |---------------------------------------------------|
    |             |             |             |         |
    | redis_key:  | redis_key:  | redis_key:  | ...     |
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
    | redis_key:  | redis_key:  | redis_key:  | ...     |
    |    A        |    A        |    B        |         |
    |             |             |             |         |
    | job 1       | job 2       | job 3       |         |
    +---------------------------------------------------+

It now doesn't matter whether job 1 and job 2 are re-ordered as whichever goes
first will perform an atomic pop on the redis list that contains the data needed
for its job (data x, data y, data z).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
