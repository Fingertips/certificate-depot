require 'socket'

class CertificateDepot
  class Server
    attr_accessor :socket, :depot
    
    DEFAULTS = {
      :host                 => '127.0.0.1',
      :port                 => 35553,
      :process_count        => 2,
      :max_connection_queue => 10
    }
    
    def initialize(depot, options={})
      @depot   = depot
      @options = options
      DEFAULTS.keys.each do |key|
        @options[key] ||= DEFAULTS[key]
      end
    end
    
    def listen
      self.socket  = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      address = Socket.pack_sockaddr_in(@options[:port], @options[:host])
      socket.bind(address)
      socket.listen(@options[:max_connection_queue])
      trap('EXIT') { socket.close }
      
      @options[:process_count].times do
        fork do
          trap('INT') { exit }
          CertificateDepot::Worker.spawn(self)
        end
      end
    end
    
    def self.listen(depot, options={})
      server = new(depot, options)
      server.listen
    end
  end
end