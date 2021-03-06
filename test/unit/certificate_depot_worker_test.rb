require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Worker" do
  it "parses commands" do
    [
      ['', []],
      ['generate',                   [:generate]],
      ['poedels',                    [:poedels]],
      ['revoke 34',                  [:revoke, 34]]
    ].each do |input, expected|
      CertificateDepot::Worker.parse_command(input).should == expected
    end
    
    command = CertificateDepot::Worker.parse_command('generate /UID=recorder-12')
    command[0].should == :generate
    command[1].class.should == OpenSSL::X509::Name
    parts = command[1].to_a
    parts[0][0].should == 'UID'
    parts[0][1].should == 'recorder-12'
  end
  
  it "runs the generate command" do
    keypair = mock('Keypair')
    keypair.stubs(:private_key).returns("PRIVATE KEY\n")
    certificate = mock('Certificate')
    certificate.stubs(:certificate).returns("CERTIFICATE\n")
    
    depot   = mock('Depot')
    server  = mock('Server')
    subject = OpenSSL::X509::Name.parse('/UID=recorder-82')
    server.stubs(:depot).returns(depot)
    depot.expects(:generate_keypair_and_certificate).with({
      :type => :client,
      :subject => subject
    }).returns([keypair, certificate])
    
    socket = Collector.new
    worker = CertificateDepot::Worker.new(server)
    worker.run_command(socket, :generate, subject)
    socket.written.join.should == "PRIVATE KEY\nCERTIFICATE\n"
  end
  
  it "runs the shutdown command" do
    worker = CertificateDepot::Worker.new(nil)
    worker.expects(:exit).with(1)
    worker.run_command(nil, :shutdown)
  end
  
  it "runs the help command without arguments" do
    socket = Collector.new
    worker = CertificateDepot::Worker.new(nil)
    worker.run_command(socket, :help)
    socket.written.join.should == "generate help shutdown\n"
  end
  
  it "runs the help command with an argument" do
    socket = Collector.new
    worker = CertificateDepot::Worker.new(nil)
    worker.run_command(socket, :help, 'generate')
    socket.written.join.should == CertificateDepot::Worker.help('generate')
  end
end