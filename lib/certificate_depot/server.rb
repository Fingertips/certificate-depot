require 'socket'
require 'fcntl'

class CertificateDepot
  class Server
    attr_accessor :socket, :depot
    
    READ_BUFFER_SIZE = 16 * 1024
    DEFAULTS = {
      :host                 => '127.0.0.1',
      :port                 => 35553,
      :process_count        => 2,
      :max_connection_queue => 10
    }
    
    def initialize(depot, options={})
      @depot = depot
      
      # Override the default with user supplied options.
      @options = options
      DEFAULTS.keys.each do |key|
        @options[key] ||= DEFAULTS[key]
      end
      
      # For Inter Process Communication we create a pair of pipes for each worker.
      # The server process reads an writes from first IO object. The worker processes
      # read and write from the second IO object.
      @lifelines = {}
      
      # Workers are instances of CertificateDepot::Worker. They are indexed by their
      # own PID.
      @workers = {}
    end
    
    # Start behaving like a server. This method blocks until the server needs to go down.
    def listen
      trap_signals
      setup_socket
      run
    end
    
    # Forks itself and starts the runloop for the server.
    def run
      # fork do
        loop do
          reap_workers
          spawn_workers
          sleep
        end
      # end
    end
    
    # Figures out if any workers died and deletes them if they did
    def reap_workers
      # Don't try to find more dead workers than the process count
      @workers.length.times do
        if pid = Process.waitpid(-1, Process::WNOHANG)
          despawn_worker(pid)
        else
          return # Stop when we don't find any
        end
      end
    end
    
    # Deletes references to workers from the server instance
    def despawn_worker(pid)
      @workers.delete(pid)
      @lifelines.delete(pid)
    end
    
    # Figures out how many workers are currently running and creates new ones when needed.
    def spawn_workers
      missing_workers.times do
        worker = CertificateDepot::Worker.new(self)
        
        lifeline = IO.pipe
        lifeline.each { |io| io.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) }
        
        pid = fork do
          lifeline.first.close
          worker.lifeline = lifeline.last
          worker.run
        end
        
        @workers[pid]   = worker
        @lifelines[pid] = lifeline.first
        
        lifeline.last.close
      end
    end
    
    # Sleeps until:
    #   - Something in the application wants the main server loop to wake up OR
    #   - 2 seconds go by
    def sleep
      needy = IO.select(@lifelines.values, nil, nil, 2)
      needy.flatten.each do |pipe|
        loop { pipe.read_nonblock(READ_BUFFER_SIZE) } unless pipe.closed?
      end if needy
    rescue EOFError, Errno::EAGAIN, Errno::EINTR
    end
    
    # Installs signal traps to listen for incoming signals to the process.
    def trap_signals
      trap(:EXIT) do
        @lifelines.each { |pid, lifeline| lifeline.close }
        socket.close
      end
    end
    
    # Creates the socket the server listens on.
    def setup_socket
      self.socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      address = Socket.pack_sockaddr_in(@options[:port], @options[:host])
      socket.bind(address)
      socket.listen(@options[:max_connection_queue])
    end
    
    # Returns the number of workers that need to be created in order to get to the
    # configured process count.
    def missing_workers
      @options[:process_count] - @workers.length
    end
    
    # Creates a new server instance and starts listening on its configured hostname
    # and port.
    def self.listen(depot, options={})
      server = new(depot, options)
      server.listen
    end
  end
end