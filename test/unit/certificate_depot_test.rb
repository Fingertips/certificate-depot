require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot" do
  it "creates a new depot" do
    CertificateDepot.create(temporary_directory, 'Certificate Depot Test')
    File.should.exist(temporary_directory)
  end
end

describe "A CertificateDepot" do
  before do
    @depot = CertificateDepot.create(temporary_directory, 'Certificate Depot Test')
  end
  
  it "has a label" do
    @depot.label.should == 'Certificate Depot Test'
  end
end