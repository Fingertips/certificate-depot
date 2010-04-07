require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Certificate" do
  before do
    @ca_keypair     = CertificateDepot::Keypair.generate
    @ca_certificate = CertificateDepot::Certificate.generate(
      :type         => :ca,
      :organization => 'Certificate Depot Test',
      :public_key   => @ca_keypair.public_key,
      :private_key  => @ca_keypair.private_key
    )
  end
  
  it "generates a new CA certificate" do
    @ca_certificate.public_key.to_s.should == @ca_keypair.public_key.to_s
    @ca_certificate['O'].should == 'Certificate Depot Test'
    @ca_certificate.organization.should == 'Certificate Depot Test'
    @ca_certificate.serial_number.should == 0
    @ca_certificate.certificate.signature_algorithm.should == 'sha1WithRSAEncryption'
    @ca_certificate.certificate.extensions[0].value.should == 'CA:TRUE'
  end
  
  it "generates a new client certificate" do
    keypair     = CertificateDepot::Keypair.generate
    certificate = CertificateDepot::Certificate.generate(
      :type           => :client,
      :ca_certificate => @ca_certificate,
      :user_id        => 'recorder-12',
      :public_key     => keypair.public_key,
      :private_key    => @ca_keypair.private_key,
      :serial_number  => 4
    )
    certificate.public_key.to_s.should == keypair.public_key.to_s
    certificate['UID'].should == 'recorder-12'
    certificate.user_id.should == 'recorder-12'
    certificate.issuer.to_s.should == @ca_certificate.subject.to_s
    certificate.serial_number.should == 4
    certificate.certificate.signature_algorithm.should == 'sha1WithRSAEncryption'
    certificate.certificate.extensions[0].value.should == 'CA:FALSE'
  end
  
  it "generates a new server certificate" do
    keypair     = CertificateDepot::Keypair.generate
    certificate = CertificateDepot::Certificate.generate(
      :type           => :server,
      :ca_certificate => @ca_certificate,
      :public_key     => keypair.public_key,
      :private_key    => @ca_keypair.private_key,
      :serial_number  => 4,
      :common_name    => '*.example.com'
    )
    certificate.common_name.should == '*.example.com'
  end
  
  it "loads from file" do
    path = File.join(temporary_directory, 'ca.crt')
    @ca_certificate.write_to(path)
    
    certificate = CertificateDepot::Certificate.from_file(path)
    certificate.organization.should == 'Certificate Depot Test'
  end
end