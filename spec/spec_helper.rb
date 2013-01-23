require 'rubygems'
require 'bundler/setup'
require 'rspec'

require 'mock_redis'
require 'resque'
require 'resque-lonely_job'
require 'timecop'

RSpec.configure do |config|
  config.before(:suite) do
    Resque.redis = MockRedis.new
  end
end
