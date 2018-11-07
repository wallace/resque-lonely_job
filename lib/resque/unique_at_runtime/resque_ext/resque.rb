module Resque
  class << self
    def running?(klass, *args)
      klass.queue_locked?(*args)
    end
  end
end
