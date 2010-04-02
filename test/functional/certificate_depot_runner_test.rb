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
  
  
  private
  
  def runner(argv)
    CertificateDepot::Runner.new(argv)
  end
end