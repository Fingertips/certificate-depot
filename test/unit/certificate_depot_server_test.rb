require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Server" do
  before do
    @depot = mock('Depot')
  end
  
  it "accepts options which override defaults" do
    expected = CertificateDepot::Server::DEFAULTS.dup
    expected[:port] = 234
    expected[:possible_pid_files] = ["/var/run/depot.pid", File.expand_path('~/.depot.pid')]
    expected[:possible_log_files] = ["/var/log/depot.log", File.expand_path('~/depot.log')]
    
    server = CertificateDepot::Server.new(@depot, {
      :port => 234
    })
    server.instance_eval { @options }.should == expected
  end
  
  it "returns a log instance" do
    server = CertificateDepot::Server.new(@depot)
    server.log.should.be.kind_of?(CertificateDepot::Log)
  end
  
  it "wants a shutdown on EXIT and QUIT signals" do
    server = CertificateDepot::Server.new(@depot)
    server.signals_want_shutdown?.should == false
    server.instance_eval { @signals = [:QUIT] }
    server.signals_want_shutdown?.should == true
    server.instance_eval { @signals = [:EXIT] }
    server.signals_want_shutdown?.should == true
  end
  
  it "writes its PID to the filesystem" do
    pid_file = File.join(temporary_directory, 'depot.pid')
    File.should.not.exist(pid_file)
    
    server = CertificateDepot::Server.new(@depot, :pid_file => pid_file)
    server.save_pid_to_file(42)
    
    File.should.exist(pid_file)
  end
  
  it "reads a PID from the filesystem after it was written" do
    pid_file = File.join(temporary_directory, 'depot.pid')
    server = CertificateDepot::Server.new(@depot, :pid_file => pid_file)
    server.save_pid_to_file(42)
    server.load_pid_from_file.should == 42
  end
  
  it "removes the PID from the filesystem" do
    pid_file = File.join(temporary_directory, 'depot.pid')
    server = CertificateDepot::Server.new(@depot, :pid_file => pid_file)
    server.save_pid_to_file(42)
    server.remove_pid_file
    server.load_pid_from_file.should == nil
  end
  
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
  
  it "reaps workers" do
    server = CertificateDepot::Server.new(@depot)
    server.instance_eval {
      @workers = { 42 => 'Worker' }
      @lifelines = { 42 => 'IO' }
    }
    
    Process.expects(:waitpid).returns(42)
    server.reap_workers
    
    server.instance_eval { @workers }[42].should.be.nil
    server.instance_eval { @lifelines }[42].should.be.nil
  end
  
  it "missing the configured amount of workers on startup" do
    server = CertificateDepot::Server.new(@depot, :process_count => 12)
    server.missing_workers.should == 12
    server.instance_eval { @workers = { 42 => 'Worker'} }
    server.missing_workers.should == 11
  end
end