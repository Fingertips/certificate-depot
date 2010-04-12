require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Runner, concerning creating depots with the commandline utility" do
  it "intializes a new repository with just a path" do
    path = File.join(temporary_directory, 'my-depot')
    runner(['init', path]).run
    CertificateDepot.new(path).label.should == 'my-depot'
  end
  
  it "intializes a new repository with a path and a name" do
    path = File.join(temporary_directory, 'my-depot')
    runner(['init', path, 'Certificate', 'Depot', 'Test']).run
    CertificateDepot.new(path).label.should == 'Certificate Depot Test'
  end
  
  private
  
  def runner(argv)
    CertificateDepot::Runner.new(argv)
  end
end

describe "CertificateDepot::Runner, concerning working on an existing depot with the commandline utility" do
  before do
    @path = File.join(temporary_directory, 'my-depot')
    runner(['init', @path, 'Certificate', 'Depot', 'Test']).run
  end
  
  it "generates a new key and certificate and writes it to stdout" do
    pem = capture_stdout do
      runner(['generate', @path, '--type', 'client', '--email', 'manfred@example.com']).run
    end
    pem.should.include("RSA PRIVATE KEY")
    pem.should.include("CERTIFICATE")
  end
  
  it "shows help text when type wasn't supplied when generating a new certificate" do
    runner = runner(['generate', @path])
    capture_stdout do
      runner.run
    end.should == "[!] Unknown certificate type `', please specify either server or client with the --type option\n"
  end
  
  it "shows a configuration example for Apache" do
    example = capture_stdout do
      runner(['config', @path]).run
    end
    example.should.include(File.join(@path, 'certificates', 'ca.crt'))
  end
  
  it "show help text when path wasn't" do
    runner = runner(['config'])
    capture_stdout do
      runner.run
    end.should == "[!] Please specify the path to the depot you want to operate on\n"
  end
  
  it "starts a new server" do
    CertificateDepot.expects(:start).returns(true)
    capture_stdout do
      runner(['start', @path]).run
    end.should == "[!] Starting server\n"
  end
  
  it "starts nothing when something happens" do
    CertificateDepot.expects(:start).returns(false)
    capture_stdout do
      runner(['start', @path]).run
    end.should == "[!] Can't start the server\n"
  end
  
  it "stops a running server" do
    CertificateDepot.expects(:stop).returns(true)
    capture_stdout do
      runner(['stop']).run
    end.should == "[!] Stopping server\n"
  end
  
  it "stops nothing when there is no running server" do
    CertificateDepot.expects(:stop).returns(false)
    capture_stdout do
      runner(['stop']).run
    end.should == "[!] Can't find a running server\n"
  end
  
  private
  
  def runner(argv)
    CertificateDepot::Runner.new(argv)
  end
end