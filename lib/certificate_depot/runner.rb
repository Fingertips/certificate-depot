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
        opts.separator "    start <path>              Start a server."
        opts.separator ""
        opts.separator "    stop                      Stop a running server."
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
        opts.on("-H", "--host [HOST]", "IP address or hostname to listen on (127.0.0.1)") do |host|
          @options[:host] = host
        end
        opts.on("-P", "--port [PORT]", "The port to listen on (35553)") do |port|
          @options[:port] = port.to_i
        end
        opts.on("-n", "--process-count", "The number of worker processes to spawn (2)") do |process_count|
          @options[:process_count] = process_count.to_i
        end
        opts.on("-q", "--max-connection-queue", "The number of requests to queue on the server (10)") do |max_connection_queue|
          @options[:max_connection_queue] = max_connection_queue.to_i
        end
        opts.on("-h", "--help", "Show help") do
          puts opts
          exit
        end
      end
    end
    
    def no_path(argv)
      if argv.length == 0
        puts "[!] Please specify the path to the depot you want to operate on"
        true
      else
        false
      end
    end
    
    def run_command(command, argv)
      path = File.expand_path(argv[0].to_s)
      case command
      when :init
        return if no_path(argv)
        if argv[1]
          label = argv[1..-1].join(' ')
        else
          label = path.split('/').last
        end
        CertificateDepot.create(path, label, @options)
      when :generate
        return if no_path(argv)
        unless [:server, :client].include?(@options[:type])
          puts "[!] Unknown certificate type `#{@options[:type]}', please specify either server or client with the --type option"
        else
          keypair, certificate = CertificateDepot.generate_keypair_and_certificate(path, @options)
          puts keypair.private_key.to_s
          puts certificate.certificate.to_s
        end
      when :config
        return if no_path(argv)
        puts CertificateDepot.configuration_example(path)
      when :start
        return if no_path(argv)
        CertificateDepot.start(path, @options)
      when :stop
        if CertificateDepot.stop(@options)
          puts "[!] Stopping server"
        else
          puts "[!] Can't find a running server"
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