# frozen_string_literal: true

require 'logger'
module Resque
  module UniqueAtRuntime
    class Configuration
      attr_accessor :logger
      attr_accessor :log_level
      attr_accessor :redis_key_base
      def initialize(**options)
        @logger = options.key?(:logger) ? options[:logger] : Logger.new(STDOUT)
        @log_level = options.key?(:log_level) ? options[:log_level] : :debug
        @redis_key_base = options.key?(:redis_key_base) ? options[:redis_key_base] : 'r-uae'
      end

      def unique_logger
        logger
      end

      def unique_log_level
        log_level
      end

      def log(msg)
        Resque::UniqueByArity.unique_log(msg, self)
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
