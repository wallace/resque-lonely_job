# -*- encoding: utf-8 -*-
require File.expand_path('../lib/resque-unique_at_runtime/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Peter H. Boling","Jonathan R. Wallace"]
  gem.email         = ["peter.boling@gmail.com","jonathan.wallace@gmail.com"]
  gem.summary       = %q{A resque plugin that ensures job uniqueness at runtime.}
  gem.homepage      = "http://github.com/pboling/resque-unique_at_runtime"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "resque-unique_at_runtime"
  gem.require_paths = ["lib"]
  gem.version       = Resque::Plugins::UniqueAtRuntime::VERSION
  gem.license       = "MIT"
  gem.required_ruby_version = ">= 1.9.3"

  gem.add_dependency 'resque', '>= 1.2'
  gem.add_development_dependency 'mock_redis'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '>= 3.0'
  gem.add_development_dependency 'timecop'

  gem.description   = <<desc
Ensures that for a given queue, only one worker is working on a job at any given time.

Example:

  require 'resque/plugins/unique_at_runtime'

  class StrictlySerialJob
    extend Resque::Plugins::UniqueAtRuntime

    @queue = :serial_work

    def self.perform
      # only one at a time in this block, no parallelism allowed for this
      # particular queue
    end
  end
desc
end
