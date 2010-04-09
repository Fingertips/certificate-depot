class CertificateDepot
  class Worker
    attr_accessor :server
    
    def initialize(server)
      @server = server
    end
    
    def run_command(socket, *args)
      args    = args.dup
      command = args.shift
      
      case command
      when :generate
        attributes = {
          :type    => :client,
          :subject => args[0]
        }
        keypair, certificate = server.depot.generate_keypair_and_certificate(attributes)
        socket.write keypair.private_key.to_s
        socket.write certificate.certificate.to_s
      when :shutdown
        exit 1
      end
    end
    
    def accept
      socket, address = @server.socket.accept
      run_command(socket, *self.class.parse_command(socket.gets))
      socket.close
    end
    
    def self.spawn(server)
      worker = new(server)
      loop { worker.accept }
    end
    
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