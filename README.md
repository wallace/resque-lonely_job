# Resque::Lonelyjob

A [Resque](https://github.com/defunkt/resque) plugin. Requires Resque 1.20.0.

Ensures that for a given queue, only one worker is working on a job at any given
time.  

This differs from [resque-lock](from https://github.com/defunkt/resque-lock) in
that the same job may be queued multiple times but you're guaranteed that first
job queued will run to completion before subsequent jobs are run. 

## Installation

Add this line to your application's Gemfile:

    gem 'resque-lonelyjob'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-lonelyjob

## Usage

Example:

    require 'resque/plugins/lonelyjob'

    class StrictlySerialJob
      extend Resque::Jobs::LonelyJob

      use_queue :serial_work

      def self.perform
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
