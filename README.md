# Resque::LonelyJob

A [Resque](https://github.com/defunkt/resque) plugin. Requires Resque 1.20.0.

Ensures that for a given queue, only one worker is working on a job at any given
time.  

This differs from [resque-lock](from https://github.com/defunkt/resque-lock) in
that the same job may be queued multiple times but you're guaranteed that first
job queued will run to completion before subsequent jobs are run. 

## Installation

Add this line to your application's Gemfile:

    gem 'resque-lonely_job'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-lonely_job

## Usage

Example #1:

    require 'resque/plugins/lonely_job'

    class StrictlySerialJob
      extend Resque::Plugins::LonelyJob

      @queue = :serial_work

      def self.perform
        # only one at a time in this block, no parallelism allowed for this
        # particular queue
      end
    end

Example #2: Let's say you want the serial constraint to apply at a more granular
level.  Instead of applying at the queue level, you can overwrite the .redis\_key
method.

    require 'resque/plugins/lonely_job'

    class StrictlySerialJob
      extend Resque::Plugins::LonelyJob

      @queue = :serial_work

      # Returns a string that will be used as the redis key
      # NOTE: it is recommended to prefix your string with the 'lonely_job:' to
      # namespace your key!
      def self.redis_key(account_id, *args)
        "lonely_job:strictly_serial_job:#{account_id}"
      end

      def self.perform(account_id, *args)
        # only one at a time in this block, no parallelism allowed for this
        # particular queue
      end
    end
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
