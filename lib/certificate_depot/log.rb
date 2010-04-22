class CertificateDepot
  # Simple thead-safe logger implementation.
  #
  #  log = Log.new('/var/log/depot.log', :level => Log::INFO)
  #  log.fatal('I am completely operational, and all my circuits are functioning perfectly.')
  #  log.close
  class Log
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5
    # Used to stop logging altogether
    SILENT  = 9 
    
    # Holds the current log file
    attr_accessor :file
    # Holds the current log level
    attr_accessor :level
    
    # Creates a new Log instance.
    def initialize(file, options={})
      @file  = file
      @level = options[:level] || DEBUG
    end
    
    # Log if the error level is debug or lower.
    def debug(*args); log(DEBUG, *args); end
    # Log if the error level is info or lower.
    def info(*args); log(INFO, *args); end
    # Log if the error level is warn or lower.
    def warn(*args); log(WARN, *args); end
    # Log if the error level is error or lower.
    def error(*args); log(ERROR, *args); end
    # Log if the error level is fatal or lower.
    def fatal(*args); log(FATAL, *args); end
    # Log if the error level is unknown or lower.
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