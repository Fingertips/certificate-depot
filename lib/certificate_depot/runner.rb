require 'optparse'
 
class CertificateDepot
  class Runner
    def initialize(argv)
      @argv = argv
      @options = {}
    end
    
    def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner =  "Usage: depot [command]"
        opts.separator ""
        opts.separator "Commands:"
        opts.separator "    init <path>     - create a new depot on disk"
        opts.separator ""
        opts.separator "Options:"
        opts.on("-h", "--help", "Show help") do
          puts opts
          exit
        end
      end
    end
    
    def run
      argv = @argv.dup
      parser.parse!(argv)
      if command = argv.shift
      else
        puts parser.to_s
      end
    end
  end
end