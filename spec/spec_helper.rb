# frozen_string_literal: true

require 'rspec'

require 'mock_redis'
require 'resque'
require 'timecop'

require 'byebug' if RbConfig::CONFIG['RUBY_INSTALL_NAME'] == 'ruby'

require 'simplecov'
SimpleCov.start

# This gem
require 'resque-unique_at_runtime'

RSpec.configure do |config|
  config.before(:suite) do
    Resque.redis = MockRedis.new
  end
end
