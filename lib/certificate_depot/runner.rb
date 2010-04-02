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
        opts.separator "    init <path> [name]     - create a new depot on disk"
        opts.separator ""
        opts.separator "Options:"
        opts.on("-h", "--help", "Show help") do
          puts opts
          exit
        end
      end
    end
    
    def run_command(command, argv)
      case command
      when :init
        path  = File.expand_path(argv[0])
        if argv[1]
          label = argv[1..-1].join(' ')
        else
          label = path.split('/').last
        end
        CertificateDepot.create(path, label)
      else
        puts parser.to_s
      end
    end
    
    def run
      argv = @argv.dup
      parser.parse!(argv)
      if command = argv.shift
        run_command(command.to_sym, argv)
      else
        puts parser.to_s
      end
    end
  end
end