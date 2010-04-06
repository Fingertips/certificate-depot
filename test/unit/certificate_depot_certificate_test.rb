require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Certificate" do
  before do
    @ca_keypair     = CertificateDepot::Keypair.generate
    @ca_certificate = CertificateDepot::Certificate.generate(
      :organization => 'Certificate Depot Test',
      :public_key => @ca_keypair.public_key,
      :private_key => @ca_keypair.private_key
    )
  end
  
  it "generates a new self-signed certificate" do
    @ca_certificate.public_key.to_s.should == @ca_keypair.public_key.to_s
    @ca_certificate['O'].should == 'Certificate Depot Test'
    @ca_certificate.organization.should == 'Certificate Depot Test'
    @ca_certificate.serial_number.should == 0
  end
  
  it "generates a new client certificate" do
    keypair     = CertificateDepot::Keypair.generate
    certificate = CertificateDepot::Certificate.generate(
      :ca_certificate => @ca_certificate,
      :email_address => 'manfred@example.com',
      :public_key => keypair.public_key,
      :private_key => @ca_keypair.private_key,
      :serial_number => 4
    )
    certificate.public_key.to_s.should == keypair.public_key.to_s
    certificate['emailAddress'].should == 'manfred@example.com'
    certificate.email_address.should == 'manfred@example.com'
    certificate.issuer.to_s.should == @ca_certificate.subject.to_s
    certificate.serial_number.should == 4
  end
  
  it "generates a new client certificate with optional attributes" do
    keypair     = CertificateDepot::Keypair.generate
    certificate = CertificateDepot::Certificate.generate(
      :ca_certificate => @ca_certificate,
      :email_address => 'manfred@example.com',
      :public_key => keypair.public_key,
      :private_key => @ca_keypair.private_key,
      :serial_number => 4,
      :common_name => 'example.com'
    )
    certificate.common_name.should == 'example.com'
  end
  
  it "loads from file" do
    path = File.join(temporary_directory, 'ca.crt')
    @ca_certificate.write_to(path)
    
    certificate = CertificateDepot::Certificate.from_file(path)
    certificate.organization.should == 'Certificate Depot Test'
  end
end