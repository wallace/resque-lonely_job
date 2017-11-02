require 'rspec'

require 'mock_redis'
require 'resque'
require 'timecop'

# This gem
require 'resque-unique_at_runtime'

RSpec.configure do |config|
  config.before(:suite) do
    Resque.redis = MockRedis.new
  end
end
