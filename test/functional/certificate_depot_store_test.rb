require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Store, with an empty depot" do
  before do
    @depot = CertificateDepot.create(temporary_directory, 'Certificate Depot Test')
    @store = @depot.certificates
  end
  
  it "has no size" do
    @store.size.should == 0
  end
  
  it "returns the next serial number" do
    @store.next_serial_number.should == 1
  end
end

describe "CertificateDepot::Store, with certificates" do
  before do
    @addresses = %w(manfred@example.com eloy@example.com thijs@example.com)
    @depot     = CertificateDepot.create(temporary_directory, 'Certificate Depot Test')
    @addresses.each do |address|
      @depot.generate_client_keypair_and_certificate(address)
    end
    @store = @depot.certificates
  end
  
  it "has no size" do
    @store.size.should == @addresses.length
  end
  
  it "returns the next serial number" do
    @store.next_serial_number.should == 4
  end
  
  it "syncs to disk" do
    entries(@store.path).length.should == 0
    @store.sync
    entries(@store.path).should == %w(1.crt 2.crt 3.crt)
  end
  
  private
  
  def entries(path)
    Dir.entries(path) - %w(. .. ca.crt)
  end
end
