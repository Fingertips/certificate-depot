require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Certificate" do
  it "generates a new self-signed certificate" do
    keypair = CertificateDepot::Keypair.generate
    certificate = CertificateDepot::Certificate.generate(keypair.public_key)
    certificate.public_key.to_s.should == keypair.public_key.to_s
  end
end