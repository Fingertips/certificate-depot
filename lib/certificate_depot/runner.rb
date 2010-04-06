require 'optparse'
 
class CertificateDepot
  class Runner
    def initialize(argv)
      @argv = argv
      @options = {}
    end
    
    def parser
      @parser ||= OptionParser.new do |opts|
        #               ---------------------------------------------------------------------------
        opts.banner =  "Usage: depot [command] [options]"
        opts.separator ""
        opts.separator "Commands:"
        opts.separator "    init <path> [name]        Create a new depot on disk. You probably want"
        opts.separator "                              to run init as root to make sure your keys"
        opts.separator "                              will be safe."
        opts.separator "         --cn <common_name>   Sets the CN in the certificate so you can use"
        opts.separator "                              it as an SSL server certificate too."
        opts.separator ""
        opts.separator "    generate <path> <email>   Create a new client certificate. Writes a pem"
        opts.separator "                              with a private key and a certificate to"
        opts.separator "                              standard output"
        opts.separator ""
        opts.separator "    config <path>             Shows a configuration example for Apache for"
        opts.separator "                              the depot."
        opts.separator ""
        opts.separator "Options:"
        opts.on("-c", "--cn [COMMON_NAME]", "Set the common name to use in the generated certificate") do |common_name|
          @options[:common_name] = common_name
        end
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
        CertificateDepot.create(path, label, @options)
      when :generate
        if argv.length >= 2
          path  = File.expand_path(argv[0])
          email = argv[1]
          
          keypair, certificate = CertificateDepot.generate_client_keypair_and_certificate(path, email, @options)
          puts keypair.private_key.to_s
          puts certificate.certificate.to_s
        else
          puts parser.to_s
        end
      when :config
        if argv.length >= 1
          path = File.expand_path(argv[0])
          puts CertificateDepot.configuration_example(path)
        else
          puts parser.to_s
        end
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