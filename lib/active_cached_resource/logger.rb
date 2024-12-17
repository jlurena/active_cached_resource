require "logger"

module ActiveCachedResource
  class Logger < ::Logger
    # @!constant COLORS
    #   @return [Hash] A hash that maps log levels to their corresponding ANSI color codes.
    #   @example
    #     COLORS[:debug] # => "\e[36m" (Blue)
    #     COLORS[:info]  # => "\e[0m"  (Default)
    #     COLORS[:warn]  # => "\e[33m" (Yellow)
    #     COLORS[:error] # => "\e[31m" (Red)
    #     COLORS[:fatal] # => "\e[31m" (Red)
    #     COLORS[:reset] # => "\e[0m"  (Reset)
    COLORS = {
      debug: "\e[36m",   # Blue
      info: "\e[0m",     # Default
      warn: "\e[33m",    # Yellow
      error: "\e[31m",   # Red
      fatal: "\e[31m",   # Red
      reset: "\e[0m"     # Reset
    }

    # Initializes a new logger instance for the specified model.
    #
    # @param model_name [String] the name of the model to be logged
    #
    # @return [void]
    def initialize(model_name)
      super($stdout)
      @model_name = model_name
      self.formatter = proc do |severity, datetime, _progname, msg|
        "#{COLORS[severity.downcase.to_sym]}#{datetime} -- #{severity} [CACHE][ACR][#{model_name}] #{msg}#{COLORS[:reset]}\n"
      end
    end
  end
end
