# Resque::Plugins::UniqueAtRuntime

| Project                 |  Resque::Plugins::UniqueAtRuntime |
|------------------------ | ----------------------- |
| gem name                |  [resque-unique_at_runtime](https://rubygems.org/gems/resque-unique_at_runtime) |
| license                 |  [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT) |
| download rank           |  [![Downloads Today](https://img.shields.io/gem/rd/resque-unique_at_runtime.svg)](https://github.com/pboling/resque-unique_at_runtime) |
| version                 |  [![Version](https://img.shields.io/gem/v/resque-unique_at_runtime.svg)](https://rubygems.org/gems/resque-unique_at_runtime) |
| dependencies            |  [![Depfu](https://badges.depfu.com/badges/99a79f37d1bc55353d0480f5138a0ce0/count.svg)](https://depfu.com/github/pboling/resque-unique_at_runtime?project_id=4349) |
| continuous integration  |  [![Build Status](https://travis-ci.org/pboling/resque-unique_at_runtime.svg?branch=master)](https://travis-ci.org/pboling/resque-unique_at_runtime) |
| test coverage           |  [![Test Coverage](https://api.codeclimate.com/v1/badges/bd4c69c621a3d7890405/test_coverage)](https://codeclimate.com/github/pboling/resque-unique_at_runtime/test_coverage) |
| maintainability         |  [![Maintainability](https://api.codeclimate.com/v1/badges/bd4c69c621a3d7890405/maintainability)](https://codeclimate.com/github/pboling/resque-unique_at_runtime/maintainability) |
| code triage             |  [![Open Source Helpers](https://www.codetriage.com/pboling/resque-unique_at_runtime/badges/users.svg)](https://www.codetriage.com/pboling/resque-unique_at_runtime) |
| homepage                |  [on Github.com][homepage], [on Railsbling.com][blogpage] |
| documentation           |  [on RDoc.info][documentation] |
| Spread ~♡ⓛⓞⓥⓔ♡~      |  [🌍 🌎 🌏](https://about.me/peter.boling), [🍚](https://www.crowdrise.com/helprefugeeswithhopefortomorrowliberia/fundraiser/peterboling), [➕](https://plus.google.com/+PeterBoling/posts), [👼](https://angel.co/peter-boling), [🐛](https://www.topcoder.com/members/pboling/), [:shipit:](http://coderwall.com/pboling), [![Tweet Peter](https://img.shields.io/twitter/follow/galtzo.svg?style=social&label=Follow)](http://twitter.com/galtzo) |

A [semanticaly versioned](http://semver.org/)
[Resque](https://github.com/resque/resque) plugin which ensures for a given
queue, that only one worker is working on a job at any given time.

Resque::Plugins::UniqueAtRuntime (this gem) differs from [resque-lonely_job](https://github.com/wallace/resque-lonely_job) in that it is compatible with, and can be used at the same time as, [resque-unique_in_queue](https://github.com/pboling/resque-unique_in_queue).

Resque::Plugins::UniqueAtRuntime differs from [resque-unique_in_queue](https://github.com/pboling/resque-unique_in_queue) in that `resque-unique_in_queue` offers **queue-time** uniqueness, while `resque-unique_at_runtime` offers **runtime** uniqueness.  The same difference applies to other queue-time uniqueness gems: [resque-queue-lock](https://github.com/mashion/resque-queue-lock), [resque-lock](https://github.com/defunkt/resque-lock).

Runtime uniqueness without queue-time uniqueness means the same job may be queued multiple times but you're guaranteed that first job queued will run to completion before subsequent jobs are run.
  
However, you can use both runtime and queue-time uniqueness together in the same project.

To use `resque-unique_in_queue` and `resque-unique_at_runtime` together, with fine control of per job configuration of uniqueness at runtime and queue-time, it is recommended to use [resque-unique_by_arity](https://github.com/pboling/resque-unique_by_arity).

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

`resque-unique_at_runtime` utilizes 3 class instance variables that can be set
in your Jobs, in addition to the standard `@queue`.  Here they are, with their
default values:

```ruby
@runtime_lock_timeout = 60 * 60 * 24 * 5
@runtime_requeue_interval = 1
@unique_at_runtime_key_base = 'r-uar'.freeze
```

The last one, in normal circumstances, shouldn't be set as different per class,
or uniqueness cleanup becomes more difficult.

It should be set only once, globally:

```ruby
Resque::UniqueAtRuntime.configuration.unique_at_runtime_key_base = 'my-custom'
```

#### Example #1 -- One job running per queue

    require 'resque-unique_at_runtime'

    class StrictlySerialJob
      include Resque::Plugins::UniqueAtRuntime

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
      include Resque::Plugins::UniqueAtRuntime

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

The behavior when multiple jobs exist in a queue protected by `resque-unique_at_runtime`
is for one job to be worked, while the other is continuously dequeued and
requeued until the first job is finished.  This can result in that worker
process pegging a CPU/core on a worker server.  To guard against this, the
default behavior is to sleep for 1 second before the requeue, which will allow
the cpu to perform other work.

This can be customized using a ```@runtime_requeue_interval``` class instance variable
in your job like so:


    require 'resque-unique_at_runtime'

    class StrictlySerialJob
      include Resque::Plugins::UniqueAtRuntime

      @queue = :serial_work
      @runtime_requeue_interval = 5         # sleep for 5 seconds before requeueing

      def self.perform
        # some implementation
      end
    end

#### Example #5 -- Check if a job is running

`resque-unique_at_runtime` extends `Resque` with a new method `running?`.

It can tell you if a job with a specific signature is running, based on the
 presence of the runtime uniqueness key.

Caveat: It can be difficult to get the signature right, especially if you have
tools that enhance job signatures with options.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pboling/resque-unique_at_runtime. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Code of Conduct

Everyone interacting in the Resque::Plugins::UniqueAtRuntime project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/pboling/resque-unique_at_runtime/blob/master/CODE_OF_CONDUCT.md).

## Versioning

This library aims to adhere to [Semantic Versioning 2.0.0][semver].
Violations of this scheme should be reported as bugs. Specifically,
if a minor or patch version is released that breaks backward
compatibility, a new version should be immediately released that
restores compatibility. Breaking changes to the public API will
only be introduced with new major versions.

As a result of this policy, you can (and should) specify a
dependency on this gem using the [Pessimistic Version Constraint][pvc] with two digits of precision.

For example:

```ruby
spec.add_dependency 'resque-unique_at_runtime', '~> 1.0'
```

## License

* Copyright (c) 2012 Jonathan R. Wallace
* Copyright (c) 2017 - 2018 [Peter H. Boling][peterboling] of [Rails Bling][railsbling]

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT) 

[license]: LICENSE
[semver]: http://semver.org/
[pvc]: http://guides.rubygems.org/patterns/#pessimistic-version-constraint
[railsbling]: http://www.railsbling.com
[peterboling]: http://www.peterboling.com
[documentation]: http://rdoc.info/github/pboling/resque-unique_at_runtime/frames
[homepage]: https://github.com/pboling/resque-unique_at_runtime/
[blogpage]: http://www.railsbling.com/tags/resque-unique_at_runtime/
