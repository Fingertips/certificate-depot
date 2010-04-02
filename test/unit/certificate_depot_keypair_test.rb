require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Keypair" do
  it "should generate a new key" do
    keypair = CertificateDepot::Keypair.generate
    keypair.public_key.should.be.public
    keypair.private_key.should.be.private
  end
end