require 'socket'
require 'optparse'

class Hurt
  def initialize(argv)
    @argv          = argv.dup
    @request_count = 10
    @concurrency   = 2
    
    parser.parse!(@argv)
    
    @host, @port = @argv
    
    if @host.nil? or @port.nil? or @host == '' or @port == ''
      puts "[!] Please specify a host and port to run the tests on."
      exit -1
    end
  end
  
  def parser
    @parser ||= OptionParser.new do |opts|
      opts.banner =  "Usage: test/hurt.rb <host> <port> [options]"
      opts.on("-n", "--requests [REQUESTS]", "The total number of requests to send (default: 10)") do |request_count|
        @request_count = request_count.to_i
      end
      opts.on("-c", "--concurrency [CONCURRENCY]", "The number of requests to fire simultaniously (default: 2)") do |concurrency|
        @concurrency = concurrency.to_i
      end
      opts.on("-h", "--help", "Show help") do
        puts opts
        exit
      end
    end
  end
  
  def run
    puts "Sending #{@request_count} requests to #{@host} on port #{@port} with concurrency #{@concurrency}"
    requests_to_make = @request_count
    retries = 0
    while(requests_to_make > 0 and retries < (@request_count * 3))
      threads = []
      @concurrency.times do
        break unless requests_to_make > 0
        threads << Thread.new do
          begin
            socket = TCPSocket.open(@host, @port)
            socket.puts("generate /UID=recorder-1")
            cert = socket.read
            if cert.include?('CERTIFICATE')
              $stdout.write('.')
              $stdout.flush
            else
              $stdout.write('!')
              $stdout.flush
            end
            requests_to_make -= 1
          rescue Errno::ECONNRESET, Errno::ECONNREFUSED
            $stdout.write('X')
            $stdout.flush
            retries += 1
          rescue Errno::ETIMEDOUT
            $stdout.write('T')
            $stdout.flush
            retries += 1
          ensure
            socket.close if socket
          end
        end
      end
      threads.each { |t| t.join }
    end
    puts
  end
  
  def self.run(argv)
    hurt = new(argv)
    hurt.run
  end
end

Hurt.run(ARGV)