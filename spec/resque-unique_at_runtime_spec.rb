# frozen_string_literal: true

require 'spec_helper'

describe Resque::UniqueAtRuntime do
  let(:unique_log_level) { :info }
  let(:logger) { Logger.new('/dev/null') }
  describe '.runtime_unique_log' do
    subject { described_class.runtime_unique_log('warbler', Resque::UniqueAtRuntime::Configuration.new(logger: logger, log_level: :info)) }
    it('logs') do
      expect(logger).to receive(:info).with('warbler')
      block_is_expected.not_to raise_error
    end
  end

  describe '.runtime_unique_debug' do
    context 'with debug_mode => true' do
      subject { described_class.runtime_unique_debug('warbler', Resque::UniqueAtRuntime::Configuration.new(debug_mode: true, logger: logger, log_level: :info)) }
      it('logs') do
        expect(logger).to receive(:debug).with(/R-UAR.*warbler/)
        block_is_expected.not_to raise_error
      end
    end
    context 'with ENV["RESQUE_DEBUG"] = "runtime"', :env_resque_stubbed do
      let(:resque_debug) { 'runtime' }
      subject { described_class.runtime_unique_debug('warbler', Resque::UniqueAtRuntime::Configuration.new(logger: logger, log_level: :info)) }
      it('logs') do
        expect(logger).to receive(:debug).with(/R-UAR.*warbler/)
        block_is_expected.not_to raise_error
      end
    end
    context 'with ENV["RESQUE_DEBUG"] = nil', :env_resque_stubbed do
      let(:resque_debug) { nil }
      subject { described_class.runtime_unique_debug('warbler', Resque::UniqueAtRuntime::Configuration.new(logger: logger, log_level: :info)) }
      it('does not logs') do
        expect(logger).not_to receive(:debug)
        block_is_expected.not_to raise_error
      end
    end
  end
end
