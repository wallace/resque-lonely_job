# frozen_string_literal: true

require File.expand_path('lib/resque/unique_at_runtime/version', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'resque-unique_at_runtime'
  spec.version       = Resque::UniqueAtRuntime::VERSION
  spec.authors       = ['Peter H. Boling', 'Jonathan R. Wallace']
  spec.email         = ['peter.boling@gmail.com', 'jonathan.wallace@gmail.com']
  spec.license       = 'MIT'

  spec.summary       = 'A resque plugin that ensures job uniqueness at runtime.'
  spec.homepage      = 'http://github.com/pboling/resque-unique_at_runtime'
  spec.required_ruby_version = '>= 2.3.0'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'colorize', '>= 0.8'
  spec.add_runtime_dependency 'resque', '>= 1.2'

  spec.add_development_dependency 'byebug', '~> 11.1'
  spec.add_development_dependency 'fakeredis', '~> 0.7'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'pry-byebug', '~> 3.6'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rspec-block_is_expected', '~> 1.0'
  spec.add_development_dependency 'rspec-stubbed_env', '~> 1.0'
  spec.add_development_dependency 'rubocop', '~> 0.60'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.30'
  spec.add_development_dependency 'timecop'

  spec.description = <<~desc
    Ensures that for a given queue, only one worker is working on a job at any given time.

    Example:

      require 'resque/plugins/unique_at_runtime'

      class StrictlySerialJob
        include Resque::Plugins::UniqueAtRuntime

        @queue = :serial_work

        def self.perform
          # only one at a time in this block, no parallelism allowed for this
          # particular queue
        end
      end
  desc
end
