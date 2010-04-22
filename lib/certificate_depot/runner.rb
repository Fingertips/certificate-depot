require 'optparse'
 
class CertificateDepot
  # The Runner class handles commands issued to the command-line utility.
  class Runner
    def initialize(argv)
      @argv = argv
      @options = {}
    end
    
    # Returns an option parser.
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
        opts.on("-n", "--process-count [COUNT]", "The number of worker processes to spawn (2)") do |process_count|
          @options[:process_count] = process_count.to_i
        end
        opts.on("-q", "--max-connection-queue [MAX]", "The number of requests to queue on the server (10)") do |max_connection_queue|
          @options[:max_connection_queue] = max_connection_queue.to_i
        end
        opts.on("-p", "--pid-file [PID_FILE]", "The file to store the server PID in (/var/run/depot.pid)") do |pid_file|
          @options[:pid_file] = pid_file
        end
        opts.on("-l", "--log-file [LOG_FILE]", "The file to store the server log in (/var/log/depot.log)") do |log_file|
          @options[:log_file] = log_file
        end
        opts.on("-h", "--help", "Show help") do
          puts opts
          exit
        end
      end
    end
    
    # Utility method which returns false if there is a path in argv. When
    # there is no path in argv it returns true and prins a warning.
    def no_path(argv)
      if argv.length == 0
        puts "[!] Please specify the path to the depot you want to operate on"
        true
      else
        false
      end
    end
    
    # Runs command with arguments. Commands and arguments are documented in
    # the help message of the command-line utility.
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
        if CertificateDepot.start(path, @options)
          puts "[!] Starting server"
        else
          puts "[!] Can't start the server"
        end
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
    
    # Runs the command found in the arguments. If the arguments don't contain
    # a command the help message is show.
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
