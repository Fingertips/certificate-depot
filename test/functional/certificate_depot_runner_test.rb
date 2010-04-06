require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Runner, concerning the commandline utility" do
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
  
  it "generates a new key and certificate and writes it to stdout" do
    path = File.join(temporary_directory, 'my-depot')
    runner(['init', path, 'Certificate', 'Depot', 'Test']).run
    pem = capture_stdout do
      runner(['generate', path, 'manfred@example.com']).run
    end
    pem.should.include("RSA PRIVATE KEY")
    pem.should.include("CERTIFICATE")
  end
  
  it "shows help text when path or email weren't supplied when generating a new certificate" do
    runner = runner(['generate'])
    capture_stdout do
      runner.run
    end.should == runner.parser.to_s
  end
  
  it "show a configuration example for Apache" do
    path = File.join(temporary_directory, 'my-depot')
    runner(['init', path, 'Certificate', 'Depot', 'Test']).run
    example = capture_stdout do
      runner(['config', path]).run
    end
    example.should.include(File.join(path, 'certificates', 'ca.crt'))
  end
  
  it "show help text when path weren't supplied when requesting a configuration example" do
    runner = runner(['config'])
    capture_stdout do
      runner.run
    end.should == runner.parser.to_s
  end
  
  private
  
  def runner(argv)
    CertificateDepot::Runner.new(argv)
  end
end