require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot" do
  it "creates a new depot" do
    CertificateDepot.create(temporary_directory, 'Certificate Depot Test')
    
    # Creates all directories
    File.should.exist(temporary_directory)
    %w(private certificates).each do |directory|
      File.should.exist(File.join(temporary_directory, directory))
    end
    
    # Creates configuration and all database files
    File.size(File.join(temporary_directory, 'depot.cnf')).should > 0
    
    # Creates a key and self-signed certificate
    File.size(File.join(temporary_directory, 'private/ca.key')).should > 0
    File.size(File.join(temporary_directory, 'certificates/ca.crt')).should > 0
  end
end

describe "A CertificateDepot" do
  before do
    @depot = CertificateDepot.create(temporary_directory, 'Certificate Depot Test')
  end
  
  it "has a label" do
    @depot.label.should == 'Certificate Depot Test'
  end
  
  it "generates a new client keypair and certificate" do
    keypair, certificate = @depot.generate_keypair_and_certificate(:type => :client, :email_address => 'manfred@example.com')
    keypair.public_key.should.be.public
    keypair.private_key.should.be.private
    
    certificate.email_address.should == 'manfred@example.com'
    certificate.issuer.to_s.should == @depot.ca_certificate.subject.to_s
  end
  
  it "generates a new client keypair with an X509 name" do
    keypair, certificate = @depot.generate_keypair_and_certificate(:type => :client, :subject => OpenSSL::X509::Name.parse('/UID=recorder-34'))
    keypair.public_key.should.be.public
    keypair.private_key.should.be.private
    
    certificate.user_id.should == 'recorder-34'
    certificate.issuer.to_s.should == @depot.ca_certificate.subject.to_s
  end
  
  it "generates a new server keypair and certificate" do
    keypair, certificate = @depot.generate_keypair_and_certificate(:type => :server, :common_name => '*.example.com')
    keypair.public_key.should.be.public
    keypair.private_key.should.be.private
    
    certificate.common_name.should == '*.example.com'
    certificate.issuer.to_s.should == @depot.ca_certificate.subject.to_s
  end
end