# frozen_string_literal: true

require 'resque/unique_at_runtime/version'

# Ruby Std Lib
require 'digest/md5'

# External Gems
require 'colorized_string'
require 'resque'

# This Gem
require 'resque/plugins/unique_at_runtime'
require 'resque/unique_at_runtime/resque_ext/resque'
require 'resque/unique_at_runtime/configuration'

# See lib/resque/plugins/unique_at_runtime.rb for the actual plugin
#
# This is not that ^.  Rather, it is an API used by the plugin or as tools by a
#   developer.  These methods are not intended to be included/extended into
#   Resque, Resque::Job, or Resque::Queue.
module Resque
  module UniqueAtRuntime
    PLUGIN_TAG = (ColorizedString['[R-UAR] '].blue).freeze

    def log(message)
      configuration.logger&.send(configuration.log_level, message) if configuration.logger
    end

    def debug(message)
      configuration.logger&.debug("#{PLUGIN_TAG}#{message}") if configuration.debug_mode
    end

    # For per-class config with a block
    def configure
      yield(@configuration)
    end

    #### CONFIG ####
    class << self
      attr_accessor :configuration
    end

    self.configuration = Configuration.instance # setup defaults

    module_function(:log,
                    :debug)
  end
end
