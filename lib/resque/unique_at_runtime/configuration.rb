# frozen_string_literal: true

require 'logger'
module Resque
  module UniqueAtRuntime
    class Configuration
      DEFAULT_AT_RUNTIME_KEY_BASE = 'r-uae'
      DEFAULT_LOCK_TIMEOUT = 60 * 60 * 24 * 5
      DEFAULT_REQUEUE_INTERVAL = 1

      attr_accessor :logger,
                    :log_level,
                    :unique_at_runtime_key_base,
                    :lock_timeout,
                    :requeue_interval,
                    :debug_mode
      def initialize(**options)
        @logger = options.key?(:logger) ? options[:logger] : Logger.new(STDOUT)
        @log_level = options.key?(:log_level) ? options[:log_level] : :debug
        @unique_at_runtime_key_base = options.key?(:unique_at_runtime_key_base) ? options[:unique_at_runtime_key_base] : DEFAULT_AT_RUNTIME_KEY_BASE
        @lock_timeout = options.key?(:lock_timeout) ? options[:lock_timeout] : DEFAULT_LOCK_TIMEOUT
        @requeue_interval = options.key?(:requeue_interval) ? options[:requeue_interval] : DEFAULT_REQUEUE_INTERVAL
        env_debug = ENV['RESQUE_DEBUG']
        @debug_mode = !!(options.key?(:debug_mode) ? options[:debug_mode] : env_debug == 'true' || (env_debug.is_a?(String) && env_debug.match?(/runtime/)))
      end

      def unique_logger
        logger
      end

      def unique_log_level
        log_level
      end

      def log(msg)
        Resque::UniqueAtRuntime.runtime_unique_log(msg, self)
      end

      def to_hash
        {
          logger: logger,
          log_level: log_level
        }
      end
    end
  end
end
