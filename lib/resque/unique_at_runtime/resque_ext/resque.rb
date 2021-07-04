# frozen_string_literal: true

module Resque
  class << self
    def running?(klass, *args)
      klass.queue_locked?(*args)
    end
  end
end
