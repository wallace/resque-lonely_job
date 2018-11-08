# frozen_string_literal: true

require 'rspec'

require 'fakeredis/rspec'
require 'rspec/block_is_expected'
require 'rspec/stubbed_env'
require 'resque'
require 'timecop'

require 'byebug' if RbConfig::CONFIG['RUBY_INSTALL_NAME'] == 'ruby'

require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  RSpec.shared_context "resque_debug" do
    include_context 'with stubbed env'
    let(:resque_debug) { 'runtime' }
    before do
      stub_env('RESQUE_DEBUG' => resque_debug)
    end
  end
  config.include_context "resque_debug", :env_resque_stubbed => true
end

# This gem needs to load after mocking up the environment
require 'resque-unique_at_runtime'
