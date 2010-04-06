require File.expand_path('../../test_helper', __FILE__)

describe "CertificateDepot::Keypair" do
  it "should generate a new key" do
    keypair = CertificateDepot::Keypair.generate
    keypair.public_key.should.be.public
    keypair.private_key.should.be.private
  end
  
  it "should write the key to file" do
    key_path = File.join(temporary_directory, 'test.key')
    keypair = CertificateDepot::Keypair.generate
    keypair.write_to(key_path)
    File.should.exist(key_path)
    File.size(key_path).should > 0
  end
end