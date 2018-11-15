# frozen_string_literal: true

require 'spec_helper'

describe Resque::UniqueAtRuntime do
  let(:unique_log_level) { :info }
  let(:logger) { Logger.new('/dev/null') }
  describe '.log' do
    before do
      @logger = Resque::UniqueAtRuntime.configuration.logger
      @log_level = Resque::UniqueAtRuntime.configuration.log_level
      Resque::UniqueAtRuntime.configuration.logger = logger
      Resque::UniqueAtRuntime.configuration.log_level = :info
    end
    after do
      Resque::UniqueAtRuntime.configuration.logger = @logger
      Resque::UniqueAtRuntime.configuration.log_level = @log_level
    end
    subject { described_class.log('warbler') }
    it('logs') do
      expect(logger).to receive(:info).with('warbler')
      block_is_expected.not_to raise_error
    end
  end

  describe '.debug' do
    context 'with debug_mode => true' do
      before do
        @debug_mode = Resque::UniqueAtRuntime.configuration.debug_mode
        @logger = Resque::UniqueAtRuntime.configuration.logger
        @log_level = Resque::UniqueAtRuntime.configuration.log_level
        Resque::UniqueAtRuntime.configuration.debug_mode = true
        Resque::UniqueAtRuntime.configuration.logger = logger
        Resque::UniqueAtRuntime.configuration.log_level = :info
      end
      after do
        Resque::UniqueAtRuntime.configuration.debug_mode = @debug_mode
        Resque::UniqueAtRuntime.configuration.logger = @logger
        Resque::UniqueAtRuntime.configuration.log_level = @log_level
      end
      subject { described_class.debug('warbler') }
      it('logs') do
        expect(logger).to receive(:debug).with(/R-UAR.*warbler/)
        block_is_expected.not_to raise_error
      end
    end
    context 'with ENV["RESQUE_DEBUG"] = "runtime"', :env_resque_stubbed do
      let(:resque_debug) { 'runtime' }
      before do
        @debug_mode = Resque::UniqueAtRuntime.configuration.debug_mode
        @logger = Resque::UniqueAtRuntime.configuration.logger
        @log_level = Resque::UniqueAtRuntime.configuration.log_level
        Resque::UniqueAtRuntime.configuration.logger = logger
        Resque::UniqueAtRuntime.configuration.log_level = :info
        Resque::UniqueAtRuntime.configuration.send(:debug_mode_from_env)
      end
      after do
        Resque::UniqueAtRuntime.configuration.debug_mode = @debug_mode
        Resque::UniqueAtRuntime.configuration.logger = @logger
        Resque::UniqueAtRuntime.configuration.log_level = @log_level
      end
      subject { described_class.debug('warbler') }
      it('logs') do
        expect(logger).to receive(:debug).with(/R-UAR.*warbler/)
        block_is_expected.not_to raise_error
      end
    end
    context 'with ENV["RESQUE_DEBUG"] = nil', :env_resque_stubbed do
      let(:resque_debug) { nil }
      before do
        @debug_mode = Resque::UniqueAtRuntime.configuration.debug_mode
        @logger = Resque::UniqueAtRuntime.configuration.logger
        @log_level = Resque::UniqueAtRuntime.configuration.log_level
        Resque::UniqueAtRuntime.configuration.logger = logger
        Resque::UniqueAtRuntime.configuration.log_level = :info
        Resque::UniqueAtRuntime.configuration.send(:debug_mode_from_env)
      end
      after do
        Resque::UniqueAtRuntime.configuration.debug_mode = @debug_mode
        Resque::UniqueAtRuntime.configuration.logger = @logger
        Resque::UniqueAtRuntime.configuration.log_level = @log_level
      end
      subject { described_class.debug('warbler') }
      it('does not logs') do
        expect(logger).not_to receive(:debug)
        block_is_expected.not_to raise_error
      end
    end
  end
end
