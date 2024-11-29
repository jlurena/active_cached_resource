require "logger"

module ActiveCachedResource
  class Logger < ::Logger
    COLORS = {
      debug: "\e[36m",   # Blue
      info: "\e[0m",     # Default
      warn: "\e[33m",    # Yellow
      error: "\e[31m",   # Red
      fatal: "\e[31m",   # Red
      reset: "\e[0m"     # Reset
    }

    def initialize(model_name)
      super($stdout)
      @model_name = model_name
      self.formatter = proc do |severity, datetime, _progname, msg|
        "#{COLORS[severity.downcase.to_sym]}#{datetime} -- #{severity} [CACHE][ACR][#{model_name}] #{msg}#{COLORS[:reset]}\n"
      end
    end
  end
end
