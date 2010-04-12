class CertificateDepot
  # A worker runs in a separate process created by the server. It hangs around
  # and polls the server socket for incoming connections. Once it finds one it
  # tried to process it.
  #
  # The worker has a lifeline to the server. The lifeline is a pipe used to
  # signal the server. When the worker goes down the server can detect the
  # severed lifeline. If the worker needs the server to stop sleeping it can
  # write to the lifeline.
  class Worker
    attr_accessor :server, :lifeline
    
    # Creates a new worker instance. The first argument is a server instance.
    def initialize(server)
      @server  = server
      @signals = []
    end
    
    # Generates a new client certificate and writes it to the socket
    def generate(socket, distinguished_name)
      attributes = {
        :type    => :client,
        :subject => distinguished_name
      }
      keypair, certificate = server.depot.generate_keypair_and_certificate(attributes)
      socket.write keypair.private_key.to_s
      socket.write certificate.certificate.to_s
    end
    
    # Writes help to the socket about a topic or a list of commands
    def help(socket, command)
      if command
        socket.write(self.class.help(command.downcase))
      else
        socket.write("generate help shutdown\n")
      end
    end
    
    # Runs a command and writes the result to the request socket.
    def run_command(socket, *args)
      args    = args.dup
      command = args.shift
      
      case command
      when :generate
        generate(socket, args[0])
      when :help
        help(socket, args[0])
      when :shutdown
        exit 1
      end
    end
    
    # Processes an incoming request. Parse the command, run the command, and
    # close the socket.
    def process_incoming_socket(socket, address)
      input = socket.gets
      server.log.debug("Got input: #{input.strip}")
      run_command(socket, *self.class.parse_command(input))
      socket.close
    end
    
    # Starts the mainloop for the worker. The mainloop sleeps until one of the
    # following three things happens: server gets a new request, activity on
    # the lifeline to the server, or 2 seconds go by.
    def run
      trap_signals
      loop do
        break if signals_want_shutdown
        begin
          # IO.select returns either a triplet of lists with IO objects that
          # need attention or nil on timeout of 2 seconds.
          if needy = IO.select([server.socket, lifeline], nil, [server.socket, lifeline], 2)
            server.log.debug("Detected activity on: #{needy.inspect}")
            # If the lifeline is active the server went down and we need to go
            # down as well.
            break if needy.flatten.any? { |io| !io.respond_to?(:accept_nonblock) }
            # Otherwise we handle incoming requests
            needy.flatten.each do |io|
              if io.respond_to?(:accept_nonblock)
                begin
                  process_incoming_socket(*io.accept_nonblock)
                rescue Errno::EAGAIN, Errno::ECONNABORTED
                end
              end
            end
          end
        rescue EOFError, Errno::EAGAIN, Errno::EINTR, Errno::EBADF, IOError
        end
      end
      cleanup
    end
    
    # Cleanup all worker resources
    def cleanup
      server.log.info("Shutting down")
      begin
        lifeline.close
      rescue Errno::EPIPE
      end
    end
    
    # Installs signal traps to listen for incoming signals to the process.
    def trap_signals
      trap(:QUIT) { @signals << :QUIT }
      trap(:EXIT) { @signals << :EXIT }
    end
    
    # Returns true when the signals received by the process demand a shutdown
    def signals_want_shutdown
      !@signals.empty?
    end
    
    # Parses a command issues by a client.
    def self.parse_command(command)
      parts = command.split(' ')
      parts[0] = parts[0].intern if parts[0]
      
      case parts[0]
      when :generate
        parts[1] = OpenSSL::X509::Name.parse(parts[1].to_s) if parts[1]
      when :revoke
        parts[1] = parts[1].to_i if parts[1]
      end
      
      parts
    end
    
    # Returns help text for a certain command
    def self.help(command)
      case command
      when 'generate'
"GENERATE
  generate <distinguished name>
RETURNS
  A private key and certificate in PEM format.
EXAMPLE
  generate /UID=12/CN=Bob Owner,emailAddress=bob@example.com
"
      when 'help'
"HELP
  help <command>
RETURNS
  A description of the command.
EXAMPLE
  help generate
"
      when 'shutdown'
"SHUTDOWN
  shutdown
RETURNS
  Kills the current worker handling the request.
EXAMPLE
  shutdown
"
      else
        "Unknown command #{command}"
      end
    end
  end
end