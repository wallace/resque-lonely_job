# frozen_string_literal: true

require 'logger'
module Resque
  module UniqueAtRuntime
    class Configuration
      DEFAULT_LOCK_TIMEOUT = 60 * 60 * 24 * 5
      DEFAULT_REQUEUE_INTERVAL = 1
      DEFAULT_UNIQUE_AT_RUNTIME_KEY_BASE = 'r-uar'.freeze
      DEFAULT_LOG_LEVEL = :debug

      include Singleton

      attr_accessor :debug_mode,
                    :lock_timeout,
                    :log_level,
                    :logger,
                    :requeue_interval,
                    :unique_at_runtime_key_base

      def initialize
        debug_mode_from_env
        @lock_timeout = DEFAULT_LOCK_TIMEOUT
        @log_level = DEFAULT_LOG_LEVEL
        @logger = nil
        @requeue_interval = DEFAULT_REQUEUE_INTERVAL
        @unique_at_runtime_key_base = DEFAULT_UNIQUE_AT_RUNTIME_KEY_BASE
        if @debug_mode
          # Make sure there is a logger when in debug_mode
          @logger ||= Logger.new(STDOUT)
        end
      end

      def to_hash
        {
          debug_mode: debug_mode,
          lock_timeout: lock_timeout,
          log_level: log_level,
          logger: logger,
          requeue_interval: requeue_interval,
          unique_at_runtime_key_base: unique_at_runtime_key_base
        }
      end

      def debug_mode=(val)
        @debug_mode = !!val
      end

      private

      def debug_mode_from_env
        env_debug = ENV['RESQUE_DEBUG']
        @debug_mode = !!(env_debug == 'true' || (env_debug.is_a?(String) && env_debug.match?(/runtime/)))
      end
    end
  end
end
