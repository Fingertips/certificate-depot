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
      @server   = server
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
    
    # Runs a command and writes the result to the request socket.
    def run_command(socket, *args)
      args    = args.dup
      command = args.shift
      
      case command
      when :generate
        generate(socket, args[0])
      when :shutdown
        exit 1
      end
    end
    
    # Processes an incoming request. Parse the command, run the command, and
    # close the socket.
    def process_incoming_socket(socket, address)
      input = socket.gets
      server.log.debug("Worker #{Process.pid}: Got input: #{input}")
      run_command(socket, *self.class.parse_command(input))
      socket.close
    end
    
    # Starts the mainloop for the worker. The mainloop sleeps until one of the
    # following three things happens: server gets a new request, activity on
    # the lifeline to the server, or 2 seconds go by.
    def run
      loop do
        # IO.select returns either a triplet of lists with IO objects that
        # need attention or nil on timeout of 2 seconds.
        if needy = IO.select([server.socket], nil, [lifeline], 2)
          # The first of the triplet are server sockets. If these are active
          # it means there is a new incoming connection.
          if incoming = needy.first
            incoming.each do |socket|
              begin
                process_incoming_socket(*socket.accept_nonblock)
              rescue Errno::EAGAIN, Errno::ECONNABORTED
              end
            end
          # The last of the triplet is the lifeline. If this is active, the
          # server probably went down so we need to go down as well.
          elsif lifelines = needy.last
            exit 1
          end
        end
      end
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
  end
end