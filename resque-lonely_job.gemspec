# -*- encoding: utf-8 -*-
require File.expand_path('../lib/resque-lonely_job/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jonathan R. Wallace"]
  gem.email         = ["jonathan.wallace@gmail.com"]
  gem.summary       = %q{A resque plugin that ensures that only one job for a given queue will be running on any worker at a given time.}
  gem.homepage      = "http://github.com/wallace/resque-lonely_job"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "resque-lonely_job"
  gem.require_paths = ["lib"]
  gem.version       = Resque::Plugins::LonelyJob::VERSION

  gem.add_dependency 'resque', '>= 1.20.0'
  gem.add_development_dependency 'mock_redis', '~> 0.4.1'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'debugger'

  gem.description   = <<desc
Ensures that for a given queue, only one worker is working on a job at any given time.

Example:

  require 'resque/plugins/lonely_job'

  class StrictlySerialJob
    extend Resque::Plugins::LonelyJob

    @queue = :serial_work

    def self.perform
      # only one at a time in this block, no parallelism allowed for this
      # particular queue
    end
  end
desc
end
