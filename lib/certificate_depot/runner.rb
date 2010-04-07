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
        opts.separator ""
        opts.separator "    generate <path>           Create a new certificate. Writes a pem"
        opts.separator "                              with a private key and a certificate to"
        opts.separator "                              standard output"
        opts.separator "                    --type    Create a client or server certificate"
        opts.separator ""
        opts.separator "    config <path>             Shows a configuration example for Apache for"
        opts.separator "                              the depot."
        opts.separator ""
        opts.separator "Options:"
        opts.on("-c", "--cn [COMMON_NAME]", "Set the common name to use in the generated certificate") do |common_name|
          @options[:common_name] = common_name
        end
        opts.on("-e", "--email [EMAIL]", "Set the email to use in the generated certificate") do |email|
          @options[:email_address] = email
        end
        opts.on( "-u", "--uid [USERID]", "Set the user id to use in the generated certificate" ) do |user_id|
          @options[:user_id] = user_id
        end
        opts.on("-t", "--type [TYPE]", "Generate a certificate of a certain type (server|client)") do |type|
          @options[:type] = type.intern
        end
        opts.on("-h", "--help", "Show help") do
          puts opts
          exit
        end
      end
    end
    
    def run_command(command, argv)
      if argv.length == 0
        puts "[!] Please specify the path to the depot you want to operate on\n    $ depot #{command} /path/to/depot"
      else
        path = File.expand_path(argv[0])
        case command
        when :init
          if argv[1]
            label = argv[1..-1].join(' ')
          else
            label = path.split('/').last
          end
          CertificateDepot.create(path, label, @options)
        when :generate
          unless [:server, :client].include?(@options[:type])
            puts "[!] Unknown certificate type `#{@options[:type]}', please specify either server or client with the --type option"
          else
            keypair, certificate = CertificateDepot.generate_keypair_and_certificate(path, @options)
            puts keypair.private_key.to_s
            puts certificate.certificate.to_s
          end
        when :config
          puts CertificateDepot.configuration_example(path)
        else
          puts parser.to_s
        end
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