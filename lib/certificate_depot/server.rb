require 'socket'
require 'fcntl'

class CertificateDepot
  # The CertificateDepot server is a pre-forking server. This basically means
  # that it forks a pre-configured number of workers.
  #
  #   Server
  #    |_ worker
  #    |_ worker
  #    |_ ...
  #
  # Workers hang around until something connects to the socket. The first
  # worker to accept the request serves it. When workers die the server starts
  # spawning new processes until it matches the configured process count.
  # Workers are identified by their process ID or PID.
  #
  # The server creates a pipe between itself and each of the workers. We call
  # these pipes lifelines. When a worker goes down the lifeline is severed.
  # This is used as a signal by the server to spawn new workers. If the server
  # goes down the workers use the same trick to notice this.
  class Server
    attr_accessor :socket, :depot
    
    POSSIBLE_PID_FILES = ['/var/run/depot.pid', File.expand_path('~/.depot.pid')]
    READ_BUFFER_SIZE = 16 * 1024
    DEFAULTS = {
      :host                 => '127.0.0.1',
      :port                 => 35553,
      :process_count        => 2,
      :max_connection_queue => 10
    }
    
    # Create a new server instance. The first argument is a CertificateDepot
    # instance. The second argument contains overrides to the DEFAULTS.
    def initialize(depot, options={})
      @depot = depot
      
      # Override the default with user supplied options.
      @options = options.dup
      DEFAULTS.keys.each do |key|
        @options[key] ||= DEFAULTS[key]
      end
      
      # If someone specifies a PID file we have to try that instead of the
      # default.
      if pid_file = @options.delete(:pid_file)
        @options[:possible_pid_files] = [pid_file]
      else
        @options[:possible_pid_files] = POSSIBLE_PID_FILES
      end
      
      # Contains the lifelines to all the workers. They are indexed by the
      # worker's PID.
      @lifelines = {}
      
      # Workers are instances of CertificateDepot::Worker. They are indexed by
      # their own PID.
      @workers = {}
    end
    
    # Start behaving like a server. This method returns once the server has
    # completely started.
    def listen
      trap_signals
      setup_socket
      run
    end
    
    # Forks a process and starts a runloop in the fork. The runloop does
    # worker housekeeping. It does so in three phases. First it removes all
    # non-functional workers from its internal structures. After that it
    # spawns new workers if it needs to. Finally it sleeps for a while so the
    # the runloop doesn't keep busy all the time.
    def run
      save_pid_to_file(fork do
        loop do
          reap_workers
          spawn_workers
          sleep
        end
      end)
    end
    
    # Write the PID of the process with the mainloop to the filesystem so we
    # read it later on to signal the server to shutdown.
    def save_pid_to_file(pid)
      @options[:possible_pid_files].each do |pid_file|
        begin
          File.open(pid_file, 'w') { |file| file.write(pid.to_s) }
          return pid_file
        rescue Errno::EACCES
        end
      end
    end
    
    # Reads the PID of the process with the mainloop from the filesystem. Used
    # for sending signals to a running server.
    def load_pid_from_file
      best_match = @options[:possible_pid_files].inject([]) do |matches, pid_file|
        begin
          matches << [File.atime(pid_file), File.read(pid_file).to_i]
        rescue Errno::EACCES, Errno::ENOENT
        end; matches
      end.compact.sort.last
      best_match[1]
    end
    
    # Removes all possible PID files.
    def remove_pid_file
      @options[:possible_pid_files].each do |pid_file|
        begin
          File.unlink(pid_file)
        rescue Errno::EACCES
        end
      end
    end
    
    # Figures out if any workers died and deletes them from internal
    # structures if they did.
    def reap_workers
      # Don't try to find more dead workers than the process count
      @workers.length.times do
        # We use +waitpid+ to find any child process which has exited. It
        # immediately returns when there aren't any dead processes.
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
    
    # Figures out how many workers are currently running and creates new ones
    # if needed.
    def spawn_workers
      missing_workers.times do
        worker = CertificateDepot::Worker.new(self)
        
        lifeline = IO.pipe
        
        pid = fork do
          # We close the server side of the pipe in this process otherwise we
          # don't get a EOF when reading from it.
          lifeline.first.close
          worker.lifeline = lifeline.last
          worker.run
        end
        
        @workers[pid]   = worker
        @lifelines[pid] = lifeline.first
        
        # We close the client side of the pipe in this process otherwise we
        # don't get an EOF when reading from it.
        lifeline.last.close
      end
    end
    
    # Sleeps until someone wants the server main loop to wake up or when 2
    # seconds go by. Workers can wake the server in two ways, either by
    # writing anything to their lifeline or by severing the lifeline. The
    # lifeline is severed when the worker dies.
    def sleep
      # Returns with active IO objects if any of them are written to.
      # Otherwise it times out after two seconds.
      needy = IO.select(@lifelines.values, nil, nil, 2)
      # Read everything coming in on the lifelines and discard it because
      # the contents doesn't matter.
      needy.flatten.each do |lifeline|
        loop { lifeline.read_nonblock(READ_BUFFER_SIZE) } unless lifeline.closed?
      end if needy
    rescue EOFError, Errno::EAGAIN, Errno::EINTR
    end
    
    # Installs signal traps to listen for incoming signals to the process.
    def trap_signals
      # Cleanup on exit
      trap(:EXIT) do
        @lifelines.each { |pid, lifeline| lifeline.close }
        socket.close
      end
    end
    
    # Creates the socket the server listens on and binds it to the configured
    # host and port.
    def setup_socket
      self.socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      address = Socket.pack_sockaddr_in(@options[:port], @options[:host])
      socket.bind(address)
      socket.listen(@options[:max_connection_queue])
    end
    
    # Returns the number of workers that need to be created in order to get to
    # the configured process count.
    def missing_workers
      @options[:process_count] - @workers.length
    end
    
    # Sends the QUIT signal to the server process.
    def kill
      Process.kill(:QUIT, load_pid_from_file)
    end
    
    # Creates a new server instance and starts listening on its configured
    # host and port. Returns once the server was started.
    def self.listen(depot, options={})
      server = new(depot, options)
      server.listen
    end
    
    # Finds the server PID and kills it causing the workers to go down as well.
    def self.kill(options={})
      server = new(options)
      server.kill
    end
  end
end