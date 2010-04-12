class CertificateDepot
  class Log
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5
    SILENT  = 9
    
    # Holds the current log level
    attr_accessor :level
    
    # Creates a new Log instance.
    def initialize(file, options={})
      @file  = file
      @level = options[:level] || DEBUG
    end
    
    def debug(*args); log(DEBUG, *args); end
    def info(*args); log(INFO, *args); end
    def warn(*args); log(WARN, *args); end
    def error(*args); log(ERROR, *args); end
    def fatal(*args); log(FATAL, *args); end
    def unknown(*args); log(UNKNOWN, *args); end
    
    # Writes a message to the log is the current loglevel is equal or greater than the message_level.
    #
    #   log.log(Log::DEBUG, "This is a debug message")
    def log(message_level, *args)
      @file.flock(File::LOCK_EX)
      @file.write(self.class.format(*args)) if message_level >= level
      @file.flock(File::LOCK_UN)
    rescue IOError
    end
    
    # Close the logger
    def close
      @file.close
    end
    
    # Format the log message
    def self.format(*args)
      ["[#{Process.pid.to_s.rjust(5)}] ", Time.now.strftime("%Y-%m-%d %H:%M:%S"), '| ', args.first, "\n"].join
    end
  end
end