require File.expand_path('../../test_helper', __FILE__)

if `which nc` == ''
  puts "[!] Skipping tests using netcat"
  HAS_NETCAT = false
else
  HAS_NETCAT = true
end

# I'm misusing the test suite here a bit because I assume all the tests will
# run in the defined order.
describe "A Certificate Depot Server" do
  PORT = 35556
  
  def self.has_netcat?
    HAS_NETCAT
  end
  
  before do
    @depot_bin      = File.expand_path('../../../bin/depot', __FILE__)
    @path           = File.expand_path('../../../tmp/server-test-depot', __FILE__)
    @log_file_path  = File.expand_path('../../../tmp/depot.log', __FILE__)
    @pid_file_path  = File.expand_path('../../../tmp/depot.pid', __FILE__)
  end
  
  it "generates a new depot on disk" do
    `#{@depot_bin} init #{@path} Certificate Depot Server Test`.should == ""
  end
  
  it "starts a server" do
    system("#{@depot_bin} start #{@path} --log-file #{@log_file_path} --pid-file #{@pid_file_path} --port #{PORT}")
  end
  
  it "shows help" do
    `echo "help" | nc 127.0.0.1 #{PORT}`.should == "generate help shutdown\n"
  end if has_netcat?
  
  it "generates a certificate" do
    pem_path = File.join(@path, 'test.pem')
    `echo "generate /UID=recorder-12" | nc 127.0.0.1 #{PORT} > #{pem_path}`
    certificate = OpenSSL::X509::Certificate.new(File.read(pem_path))
    certificate.subject.to_s.should == '/UID=recorder-12'
  end if has_netcat?
  
  it "stops a server" do
    `#{@depot_bin} stop --pid-file #{@pid_file_path}`.should == "[!] Stopping server\n"
  end
  
  it "removes the depot from disk" do
    FileUtils.rm_rf(@path)
    FileUtils.rm_f(@log_file_path)
    FileUtils.rm_f(@pid_file_path)
  end
end