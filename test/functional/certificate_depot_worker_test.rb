require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Worker" do
  before do
    @depot = CertificateDepot.create(temporary_directory, 'Certificate Depot Test')
    @server = CertificateDepot::Server.new(@depot)
    @server.socket = mock('Server socket')
    @worker = CertificateDepot::Worker.new(@server)
  end
  
  it "generates certificates" do
    subject = '/UID=recorder-5'
    
    collector = send_command("generate #{subject}")
    written = collector.written.join
    
    certificate = OpenSSL::X509::Certificate.new(written)
    certificate.subject.to_s.should == subject
    certificate.issuer.to_s.should == @depot.ca_certificate.subject.to_s
    
    key = OpenSSL::PKey::RSA.new(written)
    key.should.be.private
  end
  
  it "shows help" do
    collector = send_command("help")
    written = collector.written.join
    written.should == "generate help shutdown\n"
  end
  
  it "shuts down" do
    @worker.expects(:exit).with(1)
    send_command("shutdown")
  end
  
  private
  
  def send_command(command)
    socket  = Collector.new
    socket.stubs(:gets).returns(command)
    socket.stubs(:close)
    @worker.process_incoming_socket(socket, nil)
    socket
  end
end